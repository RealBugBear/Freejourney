# Access Codes Runbook (T24 compatibility + T25.0)

Use the SQL steps only in Supabase SQL Editor with the approved service-role
context. New codes are generated locally and stored only as keyed HMAC-SHA256
digests. Never put a real raw code or `BENEFIT_CODE_HMAC_SECRET` in SQL, chat,
commits, logs, screenshots, test fixtures, or evidence.

Live DDL, Edge Function deployment, secret changes, campaign activation, and
user communication each remain separately Founder-gated.

## 1) Create a campaign

This example creates a permanent internal Premium grant. Replace only the
synthetic placeholders after the campaign purpose, role, duration, and limits
have been approved.

```sql
insert into public.benefit_campaigns (
  internal_name,
  purpose,
  entitlement_key,
  benefit_kind,
  grant_source,
  grant_type,
  target_role,
  total_redemption_limit,
  per_account_limit,
  is_active
) values (
  '<UNIQUE_INTERNAL_CAMPAIGN_NAME>',
  '<AUDITABLE_PURPOSE_WITHOUT_PII>',
  'premium',
  'internal_grant',
  'benefit_code',
  'permanent',
  'both',
  <APPROVED_POSITIVE_TOTAL_LIMIT_OR_NULL>,
  1,
  false
)
returning id, entitlement_key, benefit_kind, is_active;
```

Keep a new campaign inactive until its separately gated activation. For a
time-limited internal grant, use exactly one supported shape:

- `grant_type = 'duration_days'` with a positive `duration_days`; or
- `grant_type = 'fixed_end'` with `fixed_end_at` in the future.

A store-offer campaign instead uses `benefit_kind = 'store_offer'`, leaves all
grant/duration fields null, and stores at least one approved
`apple_offer_ref`/`google_offer_ref`. It stores no internal price and grants no
access itself.

`eligibility_rules` is reserved for a later, explicitly tested evaluator and
must remain `{}` in T25.0. The database rejects nonempty rules fail-closed so
operators cannot assume that an unevaluated rule protects a campaign.

Compatibility gate: app builds predating T25.0 treat every successful code as
a Premium founding-code grant. Do not activate Studio or store-offer campaigns
until the benefit-aware mobile build is installed on the closed cohort (or a
separate minimum-version gate exists). Store-offer campaigns additionally wait
for their later purchase-flow task; T25.0 only recognizes them without
claiming access.

## 2) Generate one code and digest locally

The same high-entropy `BENEFIT_CODE_HMAC_SECRET` (at least 32 UTF-8 bytes) must
already be present in the local process environment and, behind its separate
secret/deploy gate, in the `redeem-access-code` Function. Do not place the
secret directly in the command or shell history. Run this only in a private,
non-recorded terminal with terminal capture and clipboard history disabled:

```sh
deno eval --allow-env=BENEFIT_CODE_HMAC_SECRET '
const secret = Deno.env.get("BENEFIT_CODE_HMAC_SECRET");
const secretBytes = new TextEncoder().encode(secret ?? "");
if (secret !== secret?.trim() || secretBytes.byteLength < 32) {
  throw new Error(
    "BENEFIT_CODE_HMAC_SECRET must have no surrounding whitespace and be at least 32 UTF-8 bytes",
  );
}
const bytes = crypto.getRandomValues(new Uint8Array(18));
const compact = Array.from(bytes, (b) => b.toString(16).padStart(2, "0"))
  .join("").toUpperCase();
const groups = compact.match(/.{1,6}/g);
if (!groups) throw new Error("Local code generation failed");
const code = groups.join("-");
const key = await crypto.subtle.importKey(
  "raw",
  new TextEncoder().encode(secret),
  { name: "HMAC", hash: "SHA-256" },
  false,
  ["sign"],
);
const signed = await crypto.subtle.sign(
  "HMAC",
  key,
  new TextEncoder().encode(code),
);
const digest = Array.from(new Uint8Array(signed), (b) =>
  b.toString(16).padStart(2, "0")
).join("");
console.log("RAW CODE (copy once to the approved secure channel):", code);
console.log("LOWERCASE HMAC DIGEST (store in SQL):", digest);
console.log("DISPLAY HINT (store in SQL):", `...${code.slice(-6)}`);
'
```

The generator creates 144 bits of randomness. Copy the raw code once to the
approved secure founder channel. Copy only its lowercase 64-character digest
and 2–12 character display hint into SQL. Clear the terminal and clipboard
afterward. Rotating the HMAC secret invalidates every unredeemed new code, so
rotation requires a deliberate reissue plan.

## 3) Store the digest, never the raw code

```sql
insert into public.benefit_codes (
  campaign_id,
  code_digest,
  display_hint,
  usage_type,
  redemption_limit,
  is_active
) values (
  '<BENEFIT_CAMPAIGN_UUID>'::uuid,
  '<LOWERCASE_64_HEX_HMAC_FROM_LOCAL_GENERATOR>',
  '<NON_SECRET_DISPLAY_HINT>',
  'single_use',
  1,
  true
)
returning id, campaign_id, display_hint, usage_type, redemption_limit;
```

For an approved multi-use code, use `usage_type = 'multi_use'` and an explicit
positive `redemption_limit`. Campaign total and per-account limits still apply
atomically.

## 4) Check redemption state

Do not include query results containing user IDs in screenshots or evidence.

```sql
select
  bc.id,
  bc.campaign_id,
  bc.display_hint,
  bc.usage_type,
  bc.redemption_limit,
  bc.is_active,
  bc.expires_at,
  count(br.id) as redemption_count
from public.benefit_codes as bc
left join public.benefit_redemptions as br
  on br.benefit_code_id = bc.id
where bc.id = '<BENEFIT_CODE_UUID>'::uuid
group by bc.id;
```

## 5) Stop future redemption

Stopping a code or campaign blocks only new redemptions. It does not revoke an
already-created entitlement grant; revocation is a separate audited action.

```sql
update public.benefit_codes
set is_active = false,
    revoked_at = now(),
    updated_at = now()
where id = '<BENEFIT_CODE_UUID>'::uuid
  and is_active;
```

## T24 legacy compatibility

Existing cleartext founding codes in `public.access_codes` remain redeemable
through the same Edge Function, including while the HMAC secret is temporarily
unavailable. Do not issue new rows in `access_codes`; the former cleartext
creation procedure is legacy-only. To inspect or expire an existing legacy
code, identify it by its UUID, never by copying its raw `code` column:

```sql
select id, redemption_count, redeemed_by, redeemed_at, expires_at
from public.access_codes
where id = '<LEGACY_ACCESS_CODE_UUID>'::uuid;

update public.access_codes
set expires_at = now()
where id = '<LEGACY_ACCESS_CODE_UUID>'::uuid
  and redemption_count = 0;
```

## Security invariants

- `access_codes`, `benefit_campaigns`, and `benefit_codes` remain client
  deny-all; app clients never list, create, or modify them directly.
- The app sends a code only to `redeem-access-code` over the authenticated
  Function call. The Function logs neither code, digest, secret, nor PII.
- The Function computes lowercase HMAC-SHA256 over the normalized uppercase
  code. New codes reach `public.redeem_access_code(...)` only as a digest; a
  raw value is sent only after a definite digest miss on the T24 legacy path.
- The Function rejects request bodies over 4 KiB, normalized codes over 256
  characters, and HMAC secrets shorter than 32 UTF-8 bytes.
- Repeating a committed new-code redemption for the same account returns its
  durable original result without adding another grant, redemption, or limit
  count. A store-offer retry is restricted to its original platform and uses
  the snapshotted opaque offer reference.
- A store-offer response is only an opaque platform offer reference. It is not
  an entitlement and never represents an internal discounted price.
