#!/usr/bin/env python3
"""Create non-secret CI asset files; refuse to overwrite an existing local env."""
from pathlib import Path

for name in ('.env.dev', '.env.prod', '.env.staging'):
    target = Path(name)
    if target.exists():
        raise SystemExit(f'Refusing to overwrite {name}')
for name in ('.env.dev', '.env.prod', '.env.staging'):
    Path(name).write_text('SUPABASE_URL=http://127.0.0.1:54321\nSUPABASE_ANON_KEY=ci-placeholder-not-a-credential\nREVENUECAT_API_KEY=\nENVIRONMENT=development\n')
print('Created local-only CI config assets; these builds are not distributable.')
