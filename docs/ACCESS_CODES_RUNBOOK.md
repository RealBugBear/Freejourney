# Access Codes Runbook (T24)

Use this only in Supabase SQL Editor (service-role context). Never create or
share real codes in chat, commits, logs, screenshots, or test fixtures.

## 1) Create a founding code

```sql
-- Generate a random, uppercase code server-side.
-- Copy the result once and share it only through your secure founder channel.
with generated as (
  select upper(substr(encode(gen_random_bytes(12), 'hex'), 1, 12)) as code_value
)
insert into public.access_codes (
  code,
  type,
  grants,
  max_redemptions,
  created_by
)
select
  generated.code_value,
  'free',
  '{"premium": true, "premium_type": "code"}'::jsonb,
  1,
  '<FOUNDER_PROFILE_UUID>'::uuid
from generated
returning id, created_at, expires_at;
```

## 2) Check whether a code was redeemed

```sql
select
  id,
  redemption_count,
  redeemed_by,
  redeemed_at,
  expires_at
from public.access_codes
where id = '<ACCESS_CODE_UUID>'::uuid;
```

## 3) Optional: expire a code before redemption

```sql
update public.access_codes
set expires_at = now()
where id = '<ACCESS_CODE_UUID>'::uuid
  and redemption_count = 0;
```

## Security notes

- `access_codes` remains RLS-protected with zero client policies (deny-all).
- App clients cannot list, create, or modify codes directly.
- Redemption is only via the `redeem-access-code` Edge Function calling
  `public.redeem_access_code(...)` atomically.
