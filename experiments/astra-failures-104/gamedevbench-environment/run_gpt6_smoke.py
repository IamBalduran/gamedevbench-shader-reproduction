"""Run one benchmark task with a transient key from the local launcher."""
import getpass
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import time
from datetime import datetime
from public_dns import provider_dns_pins
from api_retry import run_attempts, load_attempt_result, MAX_RETRIES, RETRY_DELAY_SECONDS

base = Path(__file__).resolve().parent
repo = base.parent / 'gamedevbench-main' / 'gamedevbench-main'
uv = base / 'tools/uv-x86_64-unknown-linux-gnu/uv'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--aligned', action='store_true')
parser.add_argument('--batch', action='store_true')
parser.add_argument('--model-key', default='gpt6_astra')
parser.add_argument('task_name', nargs='?', default='task_0002')
args = parser.parse_args()
registry = json.loads((base / 'shader_comparison_models.json').read_text(encoding='utf-8'))
models = {item['key']: item for item in registry['models']}
if args.model_key not in models:
    parser.error('Unknown model key')
model = models[args.model_key]
aligned = args.aligned
batch_mode = args.batch
task_name = args.task_name
print(f'Single task: {task_name} | OpenCode | {model["api_id"]} | Shubiaobiao')
print('Key is supplied locally. Ctrl+C cancels.')
dns_pins = provider_dns_pins()
key = os.environ.get('OPENAI_API_KEY', '').strip()
if not key:
    if not sys.stdin.isatty():
        sys.exit('No local key is available; no model request was made.')
    key = getpass.getpass('Shubiaobiao API Key: ').strip()
if not key:
    sys.exit('No key entered; no model request was made.')
env = os.environ.copy()
env['GAMEDEVBENCH_PUBLIC_DNS_OVERRIDES'] = dns_pins
env['OPENAI_API_KEY'] = key
env['GODOT_EXEC_PATH'] = str(base / 'tools/Godot_v4.4.1-stable_linux.x86_64')
env['GODOT_ALLOW_NEWER'] = '0'
env['PATH'] = str(uv.parent) + ':' + str(Path.home()/'.local/bin') + ':' + env['PATH']
name = (model['key'] + ('_opencode_high_video_' if aligned else '_opencode_smoke_')) + datetime.now().strftime('%Y%m%d_%H%M%S')
if batch_mode:
    name += '_' + task_name + '_' + str(os.getpid())
cmd = [str(uv), 'run', '--locked', '--no-sync', 'gamedevbench',
       '--agent', 'opencode', '--model', model['opencode_id'],
       '--confinement', 'strict', '--provider-host', 'api.shubiaobiao.cn',
       '--run-name', name, '--parallel', '1', '--solver-timeout', '600']
if aligned:
    cmd += ['--effort', model['effort'], '--use-runtime-video']
cmd += ['run', task_name]
if not batch_mode:
    (base / 'latest-model-run.json').write_text(json.dumps({
        'run_name': name, 'task': task_name, 'model': model['api_id'],
        'agent': 'opencode', 'provider': 'https://api.shubiaobiao.cn/v1',
        'effort': 'high' if aligned else 'unset (provider default)',
        'use_runtime_video': aligned, 'solver_timeout_seconds': 600,
        'results': str(repo/'results'/name)}, indent=2)+'\n')
initial_name = name
def attempt(index):
    global name
    name = initial_name if index == 0 else initial_name + '_retry' + str(index)
    cmd[cmd.index('--run-name') + 1] = name
    if index:
        env['GAMEDEVBENCH_PUBLIC_DNS_OVERRIDES'] = provider_dns_pins()
    print('Starting:', name, flush=True)
    process_code = subprocess.call(cmd, cwd=repo, env=env)
    result_path = repo / 'results' / name / f'task_{task_name}.json'
    result, trajectory = load_attempt_result(repo, name, task_name)
    if not result:
        return process_code or 1, {}, ''
    if not batch_mode:
        index_path = base / 'latest-model-run.json'
        manifest = json.loads(index_path.read_text())
        manifest.update(run_name=name, results=str(result_path.parent), retry_index=index,
                        max_retries=MAX_RETRIES, retry_delay_seconds=RETRY_DELAY_SECONDS)
        index_path.write_text(json.dumps(manifest,indent=2)+'\n')
    return (0 if result.get('success') else 1), result, trajectory
try:
    code = run_attempts(attempt, time.sleep, lambda message: print(message,flush=True))
except KeyboardInterrupt:
    print('Cancelled. No further retries.')
    code = 130
finally:
    env.pop('OPENAI_API_KEY', None)
    key = ''
print('Results:', repo/'results'/name)
print('Final status:', 'PASS' if code == 0 else 'FAILED/CANCELLED', '| exit code:', code)
sys.exit(code)
