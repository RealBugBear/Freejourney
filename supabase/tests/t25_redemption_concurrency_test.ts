import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type LocalSupabaseConfig = {
  apiUrl: string;
  serviceRoleKey: string;
};

function parseEnvOutput(output: string): Record<string, string> {
  const values: Record<string, string> = {};
  for (const line of output.split("\n")) {
    const match = line.match(/^([A-Z][A-Z0-9_]*)=(?:"(.*)"|(.*))$/);
    if (match) values[match[1]] = match[2] ?? match[3] ?? "";
  }
  return values;
}

async function readLocalSupabaseConfig(): Promise<LocalSupabaseConfig> {
  const command = new Deno.Command("supabase", {
    args: ["status", "-o", "env"],
    stdout: "piped",
    stderr: "null",
  });
  const result = await command.output();
  if (!result.success) {
    throw new Error("Local Supabase status is unavailable");
  }

  const values = parseEnvOutput(new TextDecoder().decode(result.stdout));
  const apiUrl = values.API_URL ?? "http://127.0.0.1:54321";
  const serviceRoleKey = values.SERVICE_ROLE_KEY;
  if (!serviceRoleKey) {
    throw new Error("Local Supabase service role is unavailable");
  }
  return { apiUrl, serviceRoleKey };
}

async function findLocalDbContainer(): Promise<string> {
  const command = new Deno.Command("docker", {
    args: ["ps", "--format", "{{.Names}}"],
    stdout: "piped",
    stderr: "null",
  });
  const result = await command.output();
  if (!result.success) throw new Error("Local Docker status is unavailable");
  const containers = new TextDecoder().decode(result.stdout).trim().split("\n")
    .filter((name) => name.startsWith("supabase_db_"));
  if (containers.length !== 1) {
    throw new Error("Expected exactly one running local Supabase database");
  }
  return containers[0];
}

async function runLocalSql(
  container: string,
  sql: string,
  operation: string,
): Promise<void> {
  const command = new Deno.Command("docker", {
    args: [
      "exec",
      "-i",
      container,
      "psql",
      "-U",
      "postgres",
      "-d",
      "postgres",
      "-v",
      "ON_ERROR_STOP=1",
      "-c",
      sql,
    ],
    stdout: "null",
    stderr: "null",
  });
  const result = await command.output();
  if (!result.success) {
    throw new Error(`Synthetic ${operation} failed (local_sql)`);
  }
}

function randomDigest(): string {
  return Array.from(
    crypto.getRandomValues(new Uint8Array(32)),
    (byte) => byte.toString(16).padStart(2, "0"),
  ).join("");
}

function requireNoError(
  error: { code?: string; name?: string; status?: number } | null,
  operation: string,
): void {
  if (error) {
    const category = error.code ?? error.status?.toString() ?? error.name ??
      "uncategorized";
    throw new Error(`Synthetic ${operation} failed (${category})`);
  }
}

Deno.test("campaign total limit is atomic across concurrent accounts", async () => {
  const { apiUrl, serviceRoleKey } = await readLocalSupabaseConfig();
  const client = createClient(apiUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const runId = crypto.randomUUID();
  const digest = randomDigest();
  const userIds = [crypto.randomUUID(), crypto.randomUUID()];
  const dbContainer = await findLocalDbContainer();
  let accountsInserted = false;
  let campaignId: string | null = null;
  let codeId: string | null = null;

  try {
    await runLocalSql(
      dbContainer,
      `INSERT INTO auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at, confirmation_token, email_change,
        email_change_token_new, recovery_token
      ) VALUES
        ('00000000-0000-0000-0000-000000000000', '${userIds[0]}',
         'authenticated', 'authenticated',
         't25-concurrency-${runId}-a@example.invalid', '', now(),
         '{"provider":"email","providers":["email"]}', '{}',
         now(), now(), '', '', '', ''),
        ('00000000-0000-0000-0000-000000000000', '${userIds[1]}',
         'authenticated', 'authenticated',
         't25-concurrency-${runId}-b@example.invalid', '', now(),
         '{"provider":"email","providers":["email"]}', '{}',
         now(), now(), '', '', '', '')`,
      "account setup",
    );
    accountsInserted = true;

    const { data: campaign, error: campaignError } = await client
      .from("benefit_campaigns")
      .insert({
        internal_name: `t25-concurrency-${runId}`,
        purpose: "synthetic_concurrency_test",
        entitlement_key: "premium",
        benefit_kind: "internal_grant",
        grant_source: "benefit_code",
        grant_type: "duration_days",
        duration_days: 1,
        target_role: "user",
        total_redemption_limit: 1,
        per_account_limit: 1,
        is_active: true,
      })
      .select("id")
      .single();
    requireNoError(campaignError, "campaign setup");
    campaignId = campaign?.id ?? null;
    if (!campaignId) throw new Error("Synthetic campaign setup failed");

    const { data: benefitCode, error: codeError } = await client
      .from("benefit_codes")
      .insert({
        campaign_id: campaignId,
        code_digest: digest,
        display_hint: "T25-RACE",
        usage_type: "multi_use",
        redemption_limit: 2,
        is_active: true,
      })
      .select("id")
      .single();
    requireNoError(codeError, "code setup");
    codeId = benefitCode?.id ?? null;
    if (!codeId) throw new Error("Synthetic code setup failed");

    const calls = userIds.map((userId) =>
      client.rpc("redeem_access_code", {
        p_code: null,
        p_user_id: userId,
        p_code_hmac: digest,
        p_platform: "ios",
      })
    );
    const results = await Promise.all(calls);
    const successes = results.filter(({ error, data }) =>
      error === null && data?.success === true
    );
    const limitFailures = results.filter(({ error }) =>
      error?.message?.includes("redemption_limit_reached")
    );
    if (successes.length !== 1 || limitFailures.length !== 1) {
      throw new Error("Concurrent redemption did not serialize at the limit");
    }

    const { count, error: countError } = await client
      .from("benefit_redemptions")
      .select("id", { count: "exact", head: true })
      .eq("campaign_id", campaignId);
    requireNoError(countError, "redemption count verification");
    if (count !== 1) {
      throw new Error("Concurrent redemption wrote an unexpected row count");
    }
  } finally {
    // Cleanup contains only synthetic local fixtures. Account deletion also
    // exercises the durable consumption audit after its user link is removed.
    let accountCleanupError: unknown;
    if (accountsInserted) {
      try {
        await runLocalSql(
          dbContainer,
          `DELETE FROM auth.users WHERE id IN ('${userIds[0]}', '${
            userIds[1]
          }')`,
          "account cleanup",
        );
      } catch (error) {
        accountCleanupError = error;
      }
    }
    if (campaignId) {
      await client
        .from("benefit_redemptions")
        .delete()
        .eq("campaign_id", campaignId);
    }
    if (codeId) await client.from("benefit_codes").delete().eq("id", codeId);
    if (campaignId) {
      await client.from("benefit_campaigns").delete().eq("id", campaignId);
    }
    if (accountCleanupError) throw accountCleanupError;
  }
});
