#!/usr/bin/env python3
"""Check changed Dart files without rewriting source or unrelated formatting debt."""
import os
import subprocess
from pathlib import Path

base = os.environ.get('FORMAT_BASE_REF', 'HEAD')
if not base or set(base) == {'0'}:
    base = 'HEAD'
valid = subprocess.run(['git', 'rev-parse', '--verify', base], capture_output=True)
if valid.returncode:
    raise SystemExit('Formatting base commit unavailable; fetch complete history.')
args = ['git', 'diff', '--name-only', '--diff-filter=AM', '-z', base]
paths = [p for p in subprocess.check_output(args).decode().split('\0') if p.endswith('.dart') and Path(p).is_file()]
if paths:
    raise SystemExit(subprocess.call(['dart', 'format', '--output=none', '--set-exit-if-changed', *paths]))
print('No changed Dart files to format.')
