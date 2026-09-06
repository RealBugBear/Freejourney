#!/usr/bin/env python3
"""Synthetic claim contention probe. Never contacts Supabase or FCM over HTTP.

Requires the disposable local reflexjourney Docker database, an empty queue,
and no pg_cron extension. It creates one synthetic account, claims its jobs
through concurrent database connections, and removes its fixtures in finally.
Latency includes docker exec and psql startup; this is not an app capacity test.
"""

import concurrent.futures
import json
import os
import subprocess
import time
import uuid


CONTAINER = "supabase_db_reflexjourney"
JOB_COUNT = 10000
WORKERS = 16
BATCH_SIZE = 100


def local_docker_environment():
    result = subprocess.run(
        ["docker", "context", "inspect", "--format", "{{.Endpoints.docker.Host}}"],
        capture_output=True, text=True, check=True,
    )
    endpoint = os.environ.get("DOCKER_HOST") or result.stdout.strip()
    if not endpoint.startswith("unix://"):
        raise RuntimeError("Probe requires a local Unix Docker socket")
    env = dict(os.environ)
    env.pop("DOCKER_CONTEXT", None)
    env["DOCKER_HOST"] = endpoint
    return env


def sql(statement, env):
    result = subprocess.run(
        ["docker", "exec", "-i", CONTAINER, "psql", "-X", "-qAt",
         "-U", "postgres", "-d", "postgres", "-v", "ON_ERROR_STOP=1"],
        input=statement, capture_output=True, text=True, env=env, timeout=60,
    )
    if result.returncode:
        # DB errors can echo SQL or rows. Keep diagnostic output aggregate-only.
        raise RuntimeError("Local synthetic SQL operation failed")
    return result.stdout.strip()


def main():
    env = local_docker_environment()
    if sql("SELECT count(*) FROM pg_extension WHERE extname = 'pg_cron';", env) != "0":
        raise RuntimeError("Probe requires a local database without cron")
    if sql("SELECT count(*) FROM public.notification_jobs;", env) != "0":
        raise RuntimeError("Probe requires an empty local notification queue")
    user_id = str(uuid.uuid4())
    inserted = False
    try:
        sql(f"""BEGIN;
            INSERT INTO auth.users (id, email, raw_user_meta_data)
            VALUES ('{user_id}', 'queue-{user_id}@example.invalid', '{{}}');
            INSERT INTO public.notification_jobs
              (user_id, type, scheduled_for, local_date, timezone, idempotency_key)
            SELECT '{user_id}', 'training_soft', now() - interval '1 minute',
                   current_date - n, 'UTC', '{user_id}:' || n
              FROM generate_series(1, {JOB_COUNT}) n;
            COMMIT;""", env)
        inserted = True

        def drain_worker(_):
            claimed = []
            latencies = []
            while True:
                started = time.perf_counter()
                output = sql(
                    f"SELECT id FROM public.claim_due_notification_jobs({BATCH_SIZE});",
                    env,
                )
                latencies.append((time.perf_counter() - started) * 1000)
                if not output:
                    break
                claimed.extend(output.splitlines())
            return claimed, latencies

        started = time.perf_counter()
        with concurrent.futures.ThreadPoolExecutor(max_workers=WORKERS) as pool:
            results = list(pool.map(drain_worker, range(WORKERS)))
        elapsed = time.perf_counter() - started
        ids = [item for claims, _ in results for item in claims]
        latencies = sorted(item for _, timings in results for item in timings)
        counts = sql(f"""SELECT count(*) FILTER (WHERE status = 'sending'),
             count(*) FILTER (WHERE attempt_count <> 1)
           FROM public.notification_jobs WHERE user_id = '{user_id}';""", env)
        if len(ids) != JOB_COUNT or len(set(ids)) != JOB_COUNT or counts != f"{JOB_COUNT}|0":
            raise RuntimeError("Claim uniqueness, coverage, or attempt-count invariant failed")

        summary = {
            "scope": "local PostgreSQL queue claims only; no notification delivery",
            "jobs": JOB_COUNT, "workers": WORKERS, "batch_size": BATCH_SIZE,
            "duplicate_claims": len(ids) - len(set(ids)), "unclaimed_jobs": JOB_COUNT - len(ids),
            "elapsed_seconds": round(elapsed, 3),
            "claims_per_second": round(JOB_COUNT / elapsed, 1),
            "batch_latency_ms_including_process_startup": {
                f"p{percentile}": round(latencies[min(len(latencies) - 1, int(len(latencies) * percentile / 100))], 2)
                for percentile in (50, 95, 99)
            },
        }
    finally:
        if inserted:
            sql(f"DELETE FROM auth.users WHERE id = '{user_id}';", env)
            if sql(f"SELECT count(*) FROM public.notification_jobs WHERE user_id = '{user_id}';", env) != "0":
                raise RuntimeError("Local synthetic fixture cleanup failed")
    summary["fixture_cleanup_verified"] = True
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
