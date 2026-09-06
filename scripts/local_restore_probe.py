#!/usr/bin/env python3
"""Rehearse LOCAL backup restoration without copying existing user data.

Copies schema only from local postgres into an isolated source database, adds
synthetic fixtures there, then dumps/restores that database into an isolated
target. Existing postgres data is never dumped or changed. Both temporary
DBs and dump files are removed in finally. No cron, HTTP, or provider calls.
"""
import json
import subprocess
import tempfile
import uuid
from pathlib import Path

from local_notification_queue_probe import CONTAINER, local_docker_environment, sql


def command(args, env, **kwargs):
    result = subprocess.run(
        ["docker", "exec", "-i", CONTAINER, *args], env=env,
        stderr=subprocess.PIPE, timeout=60, **kwargs,
    )
    if result.returncode:
        raise RuntimeError("Local restore command failed (SQL details withheld)")
    return result


def db_sql(database, statement, env):
    result = command(
        ["psql", "-X", "-qAt", "-U", "postgres", "-d", database,
         "-v", "ON_ERROR_STOP=1"], env,
        input=statement.encode(), stdout=subprocess.PIPE,
    )
    return result.stdout.decode().strip()


def dump_database(database, path, env, schema_only=False):
    args = ["pg_dump", "-U", "postgres", "-d", database, "-Fc", "--no-owner"]
    if schema_only:
        args.append("--schema-only")
    with path.open("wb") as output:
        command(args, env, stdout=output)


def restore_database(database, path, env):
    with path.open("rb") as source:
        command(
            ["pg_restore", "-U", "postgres", "-d", database,
             "--no-owner", "--exit-on-error"], env,
            stdin=source, stdout=subprocess.PIPE,
        )


def main():
    env = local_docker_environment()
    if sql("SELECT count(*) FROM pg_extension WHERE extname='pg_cron';", env) != "0":
        raise RuntimeError("Requires cron-free local database")
    prefix = "readiness_restore_" + uuid.uuid4().hex[:12]
    source_db, target_db = prefix + "_source", prefix + "_target"
    created = []
    user_id = str(uuid.uuid4())
    subject_id = str(uuid.uuid4())
    journal_id = str(uuid.uuid4())
    metadata_query = """SELECT jsonb_build_object(
      'public_tables', (SELECT count(*) FROM pg_tables WHERE schemaname='public'),
      'rls_tables', (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
        WHERE n.nspname='public' AND c.relrowsecurity),
      'policies', (SELECT count(*) FROM pg_policies WHERE schemaname='public'),
      'public_functions', (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
        WHERE n.nspname='public'),
      'public_triggers', (SELECT count(*) FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
        JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND NOT t.tgisinternal)
    );"""
    with tempfile.TemporaryDirectory(prefix="reflex-restore-") as directory:
        schema_dump = Path(directory) / "schema.dump"
        synthetic_dump = Path(directory) / "synthetic.dump"
        try:
            dump_database("postgres", schema_dump, env, schema_only=True)
            for name in (source_db, target_db):
                command(["createdb", "-U", "postgres", name], env, stdout=subprocess.PIPE)
                created.append(name)
            restore_database(source_db, schema_dump, env)
            if db_sql(source_db, "SELECT count(*) FROM auth.users;", env) != "0":
                raise RuntimeError("Schema restore unexpectedly contains accounts")
            db_sql(source_db, f"""BEGIN;
              INSERT INTO auth.users (id, email, raw_user_meta_data)
                VALUES ('{user_id}', 'restore@example.invalid', '{{}}');
              INSERT INTO public.reflex_subject_profiles (id, owner_user_id, profile_type, display_name)
                VALUES ('{subject_id}', '{user_id}', 'child', 'Synthetic restore fixture');
              INSERT INTO public.journal_entries (id, user_id, subject_profile_id, content, day_key)
                VALUES ('{journal_id}', '{user_id}', '{subject_id}', 'Synthetic restore content', 1);
              COMMIT;""", env)
            dump_database(source_db, synthetic_dump, env)
            restore_database(target_db, synthetic_dump, env)
            source_metadata = json.loads(db_sql(source_db, metadata_query, env))
            target_metadata = json.loads(db_sql(target_db, metadata_query, env))
            if source_metadata != target_metadata:
                raise RuntimeError("Restored schema metadata differs")
            data_check = f"""SELECT (
              (SELECT count(*) FROM auth.users)=1 AND
              EXISTS (SELECT 1 FROM public.profiles WHERE id='{user_id}') AND
              EXISTS (SELECT 1 FROM public.reflex_subject_profiles
                WHERE id='{subject_id}' AND owner_user_id='{user_id}') AND
              EXISTS (SELECT 1 FROM public.journal_entries WHERE id='{journal_id}'
                AND user_id='{user_id}' AND subject_profile_id='{subject_id}'
                AND content='Synthetic restore content')
            );"""
            if db_sql(target_db, data_check, env) != "t":
                raise RuntimeError("Restored synthetic data differs")
            # Exercise RLS with existing cluster roles and restored grants.
            for caller, expected_count in ((user_id, "1"), (str(uuid.uuid4()), "0")):
                visible = db_sql(target_db, f"""BEGIN;
                  SET LOCAL ROLE authenticated;
                  SET LOCAL request.jwt.claims = '{{"role":"authenticated","sub":"{caller}"}}';
                  SELECT count(*) FROM public.journal_entries;
                  ROLLBACK;""", env)
                if visible != expected_count:
                    raise RuntimeError("Restored row-level authorization failed")
            summary = {
                "scope": "local schema plus isolated synthetic data restore; existing user data never copied",
                "schema_metadata": source_metadata,
                "schema_metadata_matches": True,
                "synthetic_data_matches": True,
                "owner_rls_passed": True,
                "cross_account_rls_passed": True,
                "synthetic_dump_bytes": synthetic_dump.stat().st_size,
            }
        finally:
            cleanup_failed = False
            for name in reversed(created):
                try:
                    command(["dropdb", "-U", "postgres", name], env, stdout=subprocess.PIPE)
                except RuntimeError:
                    cleanup_failed = True
            if cleanup_failed:
                raise RuntimeError("Isolated restore database cleanup failed")
    summary["isolated_databases_and_dump_files_removed"] = True
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
