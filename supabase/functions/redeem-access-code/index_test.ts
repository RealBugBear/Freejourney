import {
  assertEquals,
  assertMatch,
  assertRejects,
  assertThrows,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";

import {
  buildSuccessResponse,
  computeCodeHmac,
  handleRequest,
  isValidHmacSecret,
  isValidNormalizedCode,
  mapRedeemError,
  MAX_REQUEST_BODY_BYTES,
  normalizeCode,
  normalizePlatform,
  readRedeemPayload,
} from "./index.ts";

type MockRpcResponse = {
  data: unknown;
  error: { message: string } | null;
};

function mockClientFactory(responses: MockRpcResponse[]) {
  const rpcCalls: Array<{
    functionName: string;
    args: Record<string, unknown>;
  }> = [];
  let clientCount = 0;
  const factory: Parameters<typeof handleRequest>[1] = () => {
    const isUserClient = clientCount++ === 0;
    return {
      auth: {
        getUser: async () => ({
          data: { user: { id: "00000000-0000-4000-8000-000000000001" } },
          error: null,
        }),
      },
      rpc: async (functionName, args) => {
        if (isUserClient) throw new Error("unexpected_user_client_rpc");
        rpcCalls.push({ functionName, args });
        const response = responses.shift();
        if (!response) throw new Error("missing_mock_rpc_response");
        return response;
      },
    };
  };
  return { factory, rpcCalls };
}

function testEnvironment(secret?: string): Parameters<typeof handleRequest>[2] {
  const values: Record<string, string> = {
    SUPABASE_URL: "https://test-only.invalid",
    SUPABASE_ANON_KEY: "TEST-ONLY-ANON-KEY",
    SUPABASE_SERVICE_ROLE_KEY: "TEST-ONLY-SERVICE-ROLE-KEY",
    ...(secret === undefined ? {} : { BENEFIT_CODE_HMAC_SECRET: secret }),
  };
  return (name) => values[name];
}

function redeemRequest(code = "TEST-ONLY-CODE"): Request {
  return new Request("https://test-only.invalid/redeem-access-code", {
    method: "POST",
    headers: {
      Authorization: "Bearer TEST-ONLY-JWT",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ code, platform: "ios" }),
  });
}

Deno.test("normalizes codes and canonicalizes supported platforms", () => {
  assertEquals(normalizeCode("  test-only-code  "), "TEST-ONLY-CODE");
  assertEquals(normalizeCode(null), "");
  assertEquals(isValidNormalizedCode("A".repeat(256)), true);
  assertEquals(isValidNormalizedCode("A".repeat(257)), false);

  assertEquals(normalizePlatform("iOS"), "ios");
  assertEquals(normalizePlatform("app_store"), "ios");
  assertEquals(normalizePlatform("ANDROID"), "android");
  assertEquals(normalizePlatform("play_store"), "android");
  assertEquals(normalizePlatform("web"), "unknown");
  assertEquals(normalizePlatform(undefined), "unknown");
});

Deno.test("computes a lowercase HMAC-SHA256 hex digest", async () => {
  const digest = await computeCodeHmac(
    "TEST-ONLY-CODE",
    "TEST-ONLY-HMAC-KEY-AT-LEAST-32-BYTES",
  );

  assertEquals(
    digest,
    "1352f6d1565359f150e377b9f39cbb019a1e4a9880690083877c940c1b0427bb",
  );
  assertMatch(digest, /^[0-9a-f]{64}$/);
  assertEquals(isValidHmacSecret("X".repeat(31)), false);
  assertEquals(isValidHmacSecret("X".repeat(32)), true);
  assertEquals(isValidHmacSecret("😀".repeat(8)), true);
  assertEquals(isValidHmacSecret(`${" ".repeat(31)}X`), false);
  assertEquals(isValidHmacSecret(`${"X".repeat(32)} `), false);
});

Deno.test("rejects request bodies over 4 KiB before parsing", async () => {
  const oversized = new Request("https://test-only.invalid", {
    method: "POST",
    body: "X".repeat(MAX_REQUEST_BODY_BYTES + 1),
  });
  await assertRejects(
    () => readRedeemPayload(oversized),
    Error,
    "request_body_too_large",
  );
});

Deno.test("maps legacy and benefit redemption errors without leaking details", () => {
  assertEquals(mapRedeemError("invalid_code"), {
    status: 400,
    code: "invalid_code",
  });
  assertEquals(mapRedeemError("role_not_eligible"), {
    status: 403,
    code: "role_not_eligible",
  });
  assertEquals(mapRedeemError("campaign_expired"), {
    status: 400,
    code: "campaign_inactive",
  });
  assertEquals(mapRedeemError("campaign_limit_reached"), {
    status: 409,
    code: "redemption_limit_reached",
  });
  assertEquals(mapRedeemError("benefit_code_secret_missing"), {
    status: 503,
    code: "benefit_code_secret_missing",
  });
  assertEquals(mapRedeemError("invalid_code", false), {
    status: 503,
    code: "benefit_code_secret_missing",
  });
  assertEquals(mapRedeemError("benefit_code_not_found"), {
    status: 400,
    code: "invalid_code",
  });
  assertEquals(mapRedeemError("benefit_code_inactive"), {
    status: 400,
    code: "invalid_code",
  });
  assertEquals(mapRedeemError("offer_unavailable"), {
    status: 400,
    code: "offer_unavailable",
  });
  assertEquals(mapRedeemError("invalid_platform"), {
    status: 400,
    code: "invalid_platform",
  });
  assertEquals(mapRedeemError("database detail that must stay private"), {
    status: 500,
    code: "unknown_error",
  });
});

Deno.test("builds a neutral internal-grant response", () => {
  assertEquals(
    buildSuccessResponse(
      {
        success: true,
        benefit_kind: "internal_grant",
        entitlement_key: "studio",
        expires_at: "2026-08-01T00:00:00Z",
        is_permanent: false,
      },
      "ios",
      Date.parse("2026-07-19T00:00:00Z"),
    ),
    {
      success: true,
      data: {
        benefit_kind: "internal_grant",
        entitlement_key: "studio",
        expires_at: "2026-08-01T00:00:00Z",
        is_permanent: false,
        offer: null,
      },
    },
  );
});

Deno.test("returns only the platform-selected store-offer reference", () => {
  const rpcResult = {
    success: true,
    benefit_kind: "store_offer",
    entitlement_key: "premium",
    expires_at: null,
    is_permanent: false,
    apple_offer_ref: "TEST-APPLE-OFFER-REF",
    google_offer_ref: "  TEST-GOOGLE-OFFER-REF  ",
  };

  assertEquals(buildSuccessResponse(rpcResult, "android"), {
    success: true,
    data: {
      benefit_kind: "store_offer",
      entitlement_key: "premium",
      expires_at: null,
      is_permanent: false,
      offer: {
        platform: "android",
        reference: "TEST-GOOGLE-OFFER-REF",
      },
    },
  });
  assertThrows(
    () => buildSuccessResponse(rpcResult, "unknown"),
    Error,
    "invalid_redeem_response",
  );
  assertThrows(
    () =>
      buildSuccessResponse({
        ...rpcResult,
        apple_offer_ref: "   ",
      }, "ios"),
    Error,
    "invalid_redeem_response",
  );
});

Deno.test("fails closed for malformed new RPC data", () => {
  assertThrows(
    () =>
      buildSuccessResponse({
        success: true,
        benefit_kind: "future_unknown_kind",
        entitlement_key: "premium",
        expires_at: null,
        is_permanent: true,
      }, "ios"),
    Error,
    "invalid_redeem_response",
  );
  assertThrows(
    () =>
      buildSuccessResponse(
        {
          success: true,
          benefit_kind: "internal_grant",
          entitlement_key: "studio",
          expires_at: "2026-08-01T00:00:00Z",
          is_permanent: false,
        },
        "ios",
        Date.parse("2026-08-02T00:00:00Z"),
      ),
    Error,
    "invalid_redeem_response",
  );
  assertThrows(
    () =>
      buildSuccessResponse({
        success: true,
        benefit_kind: "internal_grant",
        entitlement_key: "future_unknown_entitlement",
        expires_at: null,
        is_permanent: true,
      }, "ios"),
    Error,
    "invalid_redeem_response",
  );
  assertThrows(
    () =>
      buildSuccessResponse({
        success: true,
        benefit_kind: "store_offer",
        entitlement_key: "premium",
        expires_at: null,
        is_permanent: false,
        apple_offer_ref: null,
      }, "ios"),
    Error,
    "invalid_redeem_response",
  );
  assertThrows(
    () =>
      buildSuccessResponse({
        success: true,
        benefit_kind: "internal_grant",
        entitlement_key: "studio",
        expires_at: "not-a-timestamp",
        is_permanent: false,
      }, "ios"),
    Error,
    "invalid_redeem_response",
  );
  assertThrows(
    () =>
      buildSuccessResponse({
        success: true,
        premium_type: "code",
        redeemed_at: "not-a-timestamp",
      }, "unknown"),
    Error,
    "invalid_redeem_response",
  );
});

Deno.test("keeps the T24 JSON result compatible as a permanent premium grant", () => {
  assertEquals(
    buildSuccessResponse({
      success: true,
      premium_type: "code",
      redeemed_at: "2026-07-08T00:00:00Z",
    }, "unknown"),
    {
      success: true,
      data: {
        benefit_kind: "internal_grant",
        entitlement_key: "premium",
        expires_at: null,
        is_permanent: true,
        offer: null,
      },
    },
  );
});

Deno.test("HMAC redemption never sends the raw code to the RPC", async () => {
  const { factory, rpcCalls } = mockClientFactory([{
    data: {
      success: true,
      benefit_kind: "internal_grant",
      entitlement_key: "premium",
      expires_at: null,
      is_permanent: true,
    },
    error: null,
  }]);

  const response = await handleRequest(
    redeemRequest("  test-only-code  "),
    factory,
    testEnvironment("S".repeat(32)),
  );

  assertEquals(response.status, 200);
  assertEquals(rpcCalls.length, 1);
  assertEquals(rpcCalls[0].functionName, "redeem_access_code");
  assertEquals(rpcCalls[0].args.p_code, null);
  assertMatch(String(rpcCalls[0].args.p_code_hmac), /^[0-9a-f]{64}$/);
  assertEquals(rpcCalls[0].args.p_platform, "ios");
});

Deno.test("a definite HMAC miss retries only the raw T24 legacy path", async () => {
  const { factory, rpcCalls } = mockClientFactory([
    { data: null, error: { message: "benefit_code_not_found" } },
    {
      data: {
        success: true,
        premium_type: "code",
        redeemed_at: "2026-07-08T00:00:00Z",
      },
      error: null,
    },
  ]);

  const response = await handleRequest(
    redeemRequest("  legacy-test-only  "),
    factory,
    testEnvironment("S".repeat(32)),
  );

  assertEquals(response.status, 200);
  assertEquals(rpcCalls.length, 2);
  assertEquals(rpcCalls[0].args.p_code, null);
  assertMatch(String(rpcCalls[0].args.p_code_hmac), /^[0-9a-f]{64}$/);
  assertEquals(rpcCalls[1].args.p_code, "LEGACY-TEST-ONLY");
  assertEquals(rpcCalls[1].args.p_code_hmac, null);
});

Deno.test("inactive HMAC codes fail without a raw legacy retry", async () => {
  const { factory, rpcCalls } = mockClientFactory([{
    data: null,
    error: { message: "benefit_code_inactive" },
  }]);

  const response = await handleRequest(
    redeemRequest(),
    factory,
    testEnvironment("S".repeat(32)),
  );

  assertEquals(response.status, 400);
  assertEquals(await response.json(), { error: "invalid_code" });
  assertEquals(rpcCalls.length, 1);
  assertEquals(rpcCalls[0].args.p_code, null);
});

Deno.test("a short secret keeps the valid T24 legacy path available", async () => {
  const { factory, rpcCalls } = mockClientFactory([{
    data: {
      success: true,
      premium_type: "code",
      redeemed_at: "2026-07-08T00:00:00Z",
    },
    error: null,
  }]);

  const response = await handleRequest(
    redeemRequest("legacy-test-only"),
    factory,
    testEnvironment("S".repeat(31)),
  );

  assertEquals(response.status, 200);
  assertEquals(rpcCalls.length, 1);
  assertEquals(rpcCalls[0].args.p_code, "LEGACY-TEST-ONLY");
  assertEquals(rpcCalls[0].args.p_code_hmac, null);
});
