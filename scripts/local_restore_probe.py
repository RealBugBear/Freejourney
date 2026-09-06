#!/usr/bin/env python3
"""Rehearse LOCAL backup restoration without copying existing user data.

Copies schema only from local postgres into an isolated source database, adds
synthetic fixtures there, then dumps/restores that database into an isolated
target. Existing postgres data is never dumped or changed. Both temporary
DBs and dump files are removed in finally. No cron, HTTP, or provider calls.

Requires the local supabase_db_reflexjourney container over a Unix Docker socket,
with migrations applied and pg_cron absent. The container's supabase_admin role
must allow login with the container's POSTGRES_PASSWORD: Supabase's postgres role
is not a superuser and cannot restore extension settings such as log_min_messages.
The container needs Bash, PostgreSQL client tools, and the Supabase extensions
and cluster roles used by its schema. Existing auth users are allowed; only the
schema is copied from postgres.
"""
import json
import re
import subprocess
import tempfile
import uuid
from pathlib import Path

from local_notification_queue_probe import CONTAINER, local_docker_environment, sql


RESTORE_ROLE = "supabase_admin"


def command(args, env, **kwargs):
    result = subprocess.run(
        # Expand credentials inside the local container, never into host argv or logs.
        ["docker", "exec", "-i", CONTAINER, "sh", "-c",
         'export PGPASSWORD="$POSTGRES_PASSWORD"; exec "$@"', "local-restore", *args], env=env,
        stderr=subprocess.PIPE, timeout=60, **kwargs,
    )
    if result.returncode:
        raise RuntimeError("Local restore command failed (SQL details withheld)")
    return result


def db_sql(database, statement, env):
    result = command(
        ["psql", "-X", "-qAt", "-U", RESTORE_ROLE, "-d", database,
         "-v", "ON_ERROR_STOP=1"], env,
        input=statement.encode(), stdout=subprocess.PIPE,
    )
    return result.stdout.decode().strip()


def dump_database(database, path, env, schema_only=False):
    args = ["pg_dump", "-U", RESTORE_ROLE, "-d", database, "-Fc", "--no-owner"]
    if schema_only:
        args.append("--schema-only")
    with path.open("wb") as output:
        command(args, env, stdout=output)


def restore_database(database, path, env, graphql_schema):
    # Supabase adds its GraphQL wrapper to extension membership after installing
    # pg_graphql. pg_dump omits that definition, but retains its grants. Restore
    # the original schema definition before replaying those grants.
    restore_args = ["pg_restore", "-U", RESTORE_ROLE, "-d", database,
                    "--no-owner", "--exit-on-error"]
    with path.open("rb") as source:
        command([*restore_args, "--no-privileges"], env,
                stdin=source, stdout=subprocess.PIPE)
    db_sql(database, graphql_schema + ";\n" + """
      ALTER EXTENSION pg_graphql ADD FUNCTION
        graphql_public.graphql(text, text, jsonb, jsonb);
    """, env)
    with path.open("rb") as source:
        listing = command(["pg_restore", "--list"], env,
                          stdin=source, stdout=subprocess.PIPE).stdout.decode()
    privileges = "\n".join(line for line in listing.splitlines()
                           if re.match(r"^\d+; \d+ \d+ (?:DEFAULT )?ACL ", line))
    if not privileges:
        raise RuntimeError("Restore archive unexpectedly contains no privileges")
    with path.open("rb") as source:
        # Pass the TOC on a separate descriptor; stdin remains the binary dump.
        # All SQL/grants come from the archive, with no shell interpolation.
        command(["bash", "-c", 'exec 3<<<"$1"; shift; exec "$@"',
                 "restore-privileges", privileges, *restore_args,
                 "--use-list=/dev/fd/3"], env,
                stdin=source, stdout=subprocess.PIPE)


def main():
    env = local_docker_environment()
    if sql("SELECT count(*) FROM pg_extension WHERE extname='pg_cron';", env) != "0":
        raise RuntimeError("Requires cron-free local database")
    graphql_definition_query = """SELECT pg_get_functiondef(
      'graphql_public.graphql(text,text,jsonb,jsonb)'::regprocedure);"""
    graphql_schema = sql(graphql_definition_query, env)
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
                command(["createdb", "-U", RESTORE_ROLE, "--template=template0", name],
                        env, stdout=subprocess.PIPE)
                created.append(name)
            restore_database(source_db, schema_dump, env, graphql_schema)
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
            restore_database(target_db, synthetic_dump, env, graphql_schema)
            source_metadata = json.loads(db_sql(source_db, metadata_query, env))
            target_metadata = json.loads(db_sql(target_db, metadata_query, env))
            if source_metadata != target_metadata:
                raise RuntimeError("Restored schema metadata differs")
            if db_sql(target_db, graphql_definition_query, env) != graphql_schema:
                raise RuntimeError("Restored GraphQL wrapper definition differs")
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
                "graphql_wrapper_definition_matches": True,
                "synthetic_data_matches": True,
                "owner_rls_passed": True,
                "cross_account_rls_passed": True,
                "synthetic_dump_bytes": synthetic_dump.stat().st_size,
            }
        finally:
            cleanup_failed = False
            for name in reversed(created):
                try:
                    command(["dropdb", "-U", RESTORE_ROLE, name], env, stdout=subprocess.PIPE)
                except RuntimeError:
                    cleanup_failed = True
            if cleanup_failed:
                raise RuntimeError("Isolated restore database cleanup failed")
    summary["isolated_databases_and_dump_files_removed"] = True
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
