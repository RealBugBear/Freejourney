#!/usr/bin/env python3
"""Run only an explicitly selected disposable simulator against loopback Supabase.
No local keys are printed. Never invoke with a real-user simulator/device.
"""
import argparse
import json
import subprocess
from urllib.parse import urlparse
p=argparse.ArgumentParser();p.add_argument('--simulator',required=True);args=p.parse_args()
devices=json.loads(subprocess.check_output(['xcrun','simctl','list','devices','available','-j']))
selected=[d for group in devices['devices'].values() for d in group if d['udid']==args.simulator]
if len(selected)!=1 or not selected[0]['name'].startswith('Reflex Readiness QA'):
    raise SystemExit('Use a dedicated Reflex Readiness QA simulator, never an existing user device.')
result=subprocess.run(['supabase','status','--output','json'],capture_output=True,text=True,check=True)
status=json.loads(result.stdout)
url=status['API_URL'];key=status['ANON_KEY']
if urlparse(url).hostname not in ('127.0.0.1','localhost'):
    raise SystemExit('Refusing non-local backend')
raise SystemExit(subprocess.call(['flutter','run','--flavor','development','-d',args.simulator,
  '-t','lib/main_local.dart','--dart-define=LOCAL_SUPABASE_URL='+url,
  '--dart-define=LOCAL_SUPABASE_ANON_KEY='+key]))
