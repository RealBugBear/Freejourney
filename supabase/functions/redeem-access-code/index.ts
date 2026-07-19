const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

export type RedeemPlatform = "ios" | "android" | "unknown";
export type BenefitKind = "internal_grant" | "store_offer";
export type EntitlementKey = "premium" | "studio";

export const MAX_REQUEST_BODY_BYTES = 4 * 1024;
export const MAX_NORMALIZED_CODE_LENGTH = 256;
export const MIN_HMAC_SECRET_BYTES = 32;

type RedeemRpcResult = {
  success?: unknown;
  benefit_kind?: unknown;
  entitlement_key?: unknown;
  expires_at?: unknown;
  is_permanent?: unknown;
  apple_offer_ref?: unknown;
  google_offer_ref?: unknown;
  premium_type?: unknown;
  redeemed_at?: unknown;
};

type RedeemSuccessData = {
  benefit_kind: BenefitKind;
  entitlement_key: EntitlementKey;
  expires_at: string | null;
  is_permanent: boolean;
  offer: {
    platform: RedeemPlatform;
    reference: string | null;
  } | null;
};

type RedeemSuccess = {
  success: true;
  data: RedeemSuccessData;
};

type RedeemError = {
  status: number;
  code: string;
};

type SupabaseClient = {
  auth: {
    getUser: () => Promise<{
      data: { user: { id: string } | null };
      error: unknown;
    }>;
  };
  rpc: (
    functionName: string,
    args: Record<string, unknown>,
  ) => Promise<{
    data: unknown;
    error: { message: string } | null;
  }>;
};

type CreateSupabaseClient = (
  url: string,
  key: string,
  options?: Record<string, unknown>,
) => SupabaseClient;

type ReadEnvironment = (name: string) => string | undefined;

type RedeemPayload = {
  code?: unknown;
  platform?: unknown;
};

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function normalizeCode(value: unknown): string {
  return typeof value === "string" ? value.trim().toUpperCase() : "";
}

export function isValidNormalizedCode(value: string): boolean {
  return value.length > 0 && value.length <= MAX_NORMALIZED_CODE_LENGTH;
}

export function isValidHmacSecret(value: unknown): value is string {
  if (typeof value !== "string" || value !== value.trim()) return false;
  return new TextEncoder().encode(value).byteLength >= MIN_HMAC_SECRET_BYTES;
}

export async function readRedeemPayload(req: Request): Promise<RedeemPayload> {
  const declaredLength = req.headers.get("content-length");
  if (declaredLength !== null && /^\d+$/.test(declaredLength)) {
    const bytes = Number(declaredLength);
    if (!Number.isSafeInteger(bytes) || bytes > MAX_REQUEST_BODY_BYTES) {
      throw new Error("request_body_too_large");
    }
  }

  if (req.body === null) return {};

  const reader = req.body.getReader();
  const chunks: Uint8Array[] = [];
  let totalBytes = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      totalBytes += value.byteLength;
      if (totalBytes > MAX_REQUEST_BODY_BYTES) {
        try {
          await reader.cancel();
        } catch {
          // The size error below is the stable public outcome.
        }
        throw new Error("request_body_too_large");
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }

  if (totalBytes === 0) return {};
  const body = new Uint8Array(totalBytes);
  let offset = 0;
  for (const chunk of chunks) {
    body.set(chunk, offset);
    offset += chunk.byteLength;
  }

  const decoded = new TextDecoder("utf-8", { fatal: true }).decode(body);
  const parsed = JSON.parse(decoded);
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    return {};
  }
  return parsed as RedeemPayload;
}

export function normalizePlatform(value: unknown): RedeemPlatform {
  if (typeof value !== "string") return "unknown";

  switch (value.trim().toLowerCase()) {
    case "ios":
    case "apple":
    case "app_store":
      return "ios";
    case "android":
    case "google":
    case "play_store":
      return "android";
    default:
      return "unknown";
  }
}

export async function computeCodeHmac(
  normalizedCode: string,
  secret: string,
): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(normalizedCode),
  );

  return Array.from(
    new Uint8Array(signature),
    (byte) => byte.toString(16).padStart(2, "0"),
  ).join("");
}

function hasErrorToken(message: string, token: string): boolean {
  return message === token || message.includes(token);
}

function isBenefitCodeNotFound(message: unknown): boolean {
  return typeof message === "string" &&
    hasErrorToken(message.toLowerCase(), "benefit_code_not_found");
}

export function mapRedeemError(
  message: unknown,
  hmacSecretConfigured = true,
): RedeemError {
  const value = typeof message === "string" ? message.toLowerCase() : "";

  if (
    hasErrorToken(value, "benefit_code_not_found") ||
    hasErrorToken(value, "benefit_code_inactive")
  ) {
    return { status: 400, code: "invalid_code" };
  }
  if (hasErrorToken(value, "invalid_code")) {
    if (!hmacSecretConfigured) {
      return { status: 503, code: "benefit_code_secret_missing" };
    }
    return { status: 400, code: "invalid_code" };
  }
  if (hasErrorToken(value, "already_redeemed")) {
    return { status: 400, code: "already_redeemed" };
  }
  if (hasErrorToken(value, "expired_code")) {
    return { status: 400, code: "expired_code" };
  }
  if (hasErrorToken(value, "unsupported_code_type")) {
    return { status: 400, code: "unsupported_code_type" };
  }
  if (
    hasErrorToken(value, "role_not_eligible") ||
    hasErrorToken(value, "ineligible_role") ||
    hasErrorToken(value, "role_mismatch")
  ) {
    return { status: 403, code: "role_not_eligible" };
  }
  if (
    hasErrorToken(value, "campaign_inactive") ||
    hasErrorToken(value, "campaign_not_active") ||
    hasErrorToken(value, "campaign_expired") ||
    hasErrorToken(value, "campaign_revoked")
  ) {
    return { status: 400, code: "campaign_inactive" };
  }
  if (
    hasErrorToken(value, "redemption_limit_reached") ||
    hasErrorToken(value, "campaign_limit_reached") ||
    hasErrorToken(value, "account_limit_reached") ||
    hasErrorToken(value, "per_account_limit_reached")
  ) {
    return { status: 409, code: "redemption_limit_reached" };
  }
  if (hasErrorToken(value, "benefit_code_secret_missing")) {
    return { status: 503, code: "benefit_code_secret_missing" };
  }
  if (hasErrorToken(value, "offer_unavailable")) {
    return { status: 400, code: "offer_unavailable" };
  }
  if (hasErrorToken(value, "invalid_platform")) {
    return { status: 400, code: "invalid_platform" };
  }
  if (hasErrorToken(value, "unauthorized")) {
    return { status: 401, code: "unauthorized" };
  }

  return { status: 500, code: "unknown_error" };
}

function asRpcResult(data: unknown): RedeemRpcResult {
  if (Array.isArray(data) && data.length !== 1) {
    throw new Error("invalid_redeem_response");
  }
  const value = Array.isArray(data) ? data[0] : data;
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("invalid_redeem_response");
  }
  return value as RedeemRpcResult;
}

function nullableString(value: unknown): string | null {
  if (value === null) return null;
  if (typeof value === "string") {
    const trimmed = value.trim();
    if (trimmed.length > 0) return trimmed;
  }
  throw new Error("invalid_redeem_response");
}

function nullableTimestamp(value: unknown): string | null {
  if (value === null) return null;
  if (
    typeof value === "string" &&
    value.length > 0 &&
    Number.isFinite(Date.parse(value))
  ) return value;
  throw new Error("invalid_redeem_response");
}

function isLegacyT24Result(result: RedeemRpcResult): boolean {
  return result.benefit_kind === undefined &&
    result.success === true &&
    result.premium_type === "code" &&
    typeof result.redeemed_at === "string" &&
    Number.isFinite(Date.parse(result.redeemed_at));
}

export function buildSuccessResponse(
  rpcData: unknown,
  platform: RedeemPlatform,
  nowMilliseconds = Date.now(),
): RedeemSuccess {
  const result = asRpcResult(rpcData);
  if (isLegacyT24Result(result)) {
    return {
      success: true,
      data: {
        benefit_kind: "internal_grant",
        entitlement_key: "premium",
        expires_at: null,
        is_permanent: true,
        offer: null,
      },
    };
  }

  if (
    result.success !== true ||
    (result.benefit_kind !== "internal_grant" &&
      result.benefit_kind !== "store_offer") ||
    (result.entitlement_key !== "premium" &&
      result.entitlement_key !== "studio") ||
    typeof result.is_permanent !== "boolean"
  ) {
    throw new Error("invalid_redeem_response");
  }

  const benefitKind: BenefitKind = result.benefit_kind;
  const entitlementKey: EntitlementKey = result.entitlement_key;
  const expiresAt = nullableTimestamp(result.expires_at);
  const isPermanent = result.is_permanent;

  let offer: RedeemSuccessData["offer"] = null;
  if (benefitKind === "store_offer") {
    if (platform === "unknown" || isPermanent || expiresAt !== null) {
      throw new Error("invalid_redeem_response");
    }
    const reference = platform === "ios"
      ? nullableString(result.apple_offer_ref)
      : nullableString(result.google_offer_ref);
    if (reference === null) {
      throw new Error("invalid_redeem_response");
    }
    offer = { platform, reference };
  } else if (
    (isPermanent && expiresAt !== null) ||
    (!isPermanent &&
      (expiresAt === null || Date.parse(expiresAt) <= nowMilliseconds))
  ) {
    throw new Error("invalid_redeem_response");
  }

  return {
    success: true,
    data: {
      benefit_kind: benefitKind,
      entitlement_key: entitlementKey,
      expires_at: expiresAt,
      is_permanent: isPermanent,
      offer,
    },
  };
}

export async function handleRequest(
  req: Request,
  createClient: CreateSupabaseClient,
  readEnvironment: ReadEnvironment = (name) => Deno.env.get(name),
): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    const supabaseUrl = readEnvironment("SUPABASE_URL");
    const anonKey = readEnvironment("SUPABASE_ANON_KEY");
    const serviceRoleKey = readEnvironment("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      return jsonResponse({ error: "unknown_error" }, 500);
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser();
    if (authError || !user) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    let payload: RedeemPayload;
    try {
      payload = await readRedeemPayload(req);
    } catch (error) {
      if (
        error instanceof Error && error.message === "request_body_too_large"
      ) {
        return jsonResponse({ error: "request_body_too_large" }, 413);
      }
      return jsonResponse({ error: "invalid_code" }, 400);
    }
    const code = normalizeCode(payload.code);
    if (!isValidNormalizedCode(code)) {
      return jsonResponse({ error: "invalid_code" }, 400);
    }
    const platform = normalizePlatform(payload.platform);

    const hmacSecret = readEnvironment("BENEFIT_CODE_HMAC_SECRET");
    const hmacSecretConfigured = isValidHmacSecret(hmacSecret);
    const serviceClient = createClient(supabaseUrl, serviceRoleKey);
    let data: unknown;
    let error: { message: string } | null;

    if (hmacSecretConfigured) {
      const codeHmac = await computeCodeHmac(code, hmacSecret);
      ({ data, error } = await serviceClient.rpc("redeem_access_code", {
        // New benefit codes never cross the Edge boundary in cleartext.
        p_code: null,
        p_user_id: user.id,
        p_code_hmac: codeHmac,
        p_platform: platform,
      }));

      if (error && isBenefitCodeNotFound(error.message)) {
        // Only a definite HMAC miss may retry the isolated T24 legacy path.
        ({ data, error } = await serviceClient.rpc("redeem_access_code", {
          p_code: code,
          p_user_id: user.id,
          p_code_hmac: null,
          p_platform: platform,
        }));
      }
    } else {
      // Preserve existing T24 codes even if the new-code secret is missing or
      // below the minimum strength. New HMAC codes fail with a configuration
      // error after this legacy-only lookup misses.
      ({ data, error } = await serviceClient.rpc("redeem_access_code", {
        p_code: code,
        p_user_id: user.id,
        p_code_hmac: null,
        p_platform: platform,
      }));
    }

    if (error) {
      const mapped = mapRedeemError(error.message, hmacSecretConfigured);
      return jsonResponse({ error: mapped.code }, mapped.status);
    }

    return jsonResponse(buildSuccessResponse(data, platform));
  } catch {
    return jsonResponse({ error: "unknown_error" }, 500);
  }
}

if (import.meta.main) {
  const { createClient } = await import(
    "https://esm.sh/@supabase/supabase-js@2"
  );
  const clientFactory = createClient as unknown as CreateSupabaseClient;
  Deno.serve((req) => handleRequest(req, clientFactory));
}
