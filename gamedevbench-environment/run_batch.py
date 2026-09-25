"""Resumable, evidence-preserving GameDevBench runner (WSL entry point)."""
from __future__ import annotations

import argparse
from concurrent.futures import FIRST_COMPLETED, ThreadPoolExecutor, wait
import csv
from datetime import datetime, timezone
import fcntl
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import queue
import re
import signal
import sqlite3
import subprocess
import sys
import threading
import time
from zipfile import ZipFile
from api_retry import api_rejection_status, api_transport_error

BASE = Path(__file__).resolve().parent
REPO = BASE.parent / 'gamedevbench-main' / 'gamedevbench-main'
ROOT = BASE / 'batch_runs'
TASK_RE = re.compile(r'^task_\d{4}$')
RUN_RE = re.compile(r'^Starting: ([a-zA-Z0-9_]+)$')
FIELDS = ['task', 'model_key', 'model_id', 'reported_model', 'model_match', 'state', 'attempts', 'official_success', 'official_message',
          'official_details', 'validator_error_line',
          'solver_success', 'solver_message', 'solver_duration', 'cost_usd',
          'input_tokens', 'output_tokens', 'is_rate_limited', 'run_name',
          'result_json', 'solver_result_json', 'artifact_dir', 'trajectory_log',
          'console_log', 'archive_sha256', 'validator_sha256', 'started_at',
          'finished_at', 'exit_code', 'classification', 'api_http_status',
          'transport_error']


def now():
    return datetime.now(timezone.utc).isoformat(timespec='seconds')


def atomic_json(path: Path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + '.tmp')
    tmp.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    os.replace(tmp, path)


def sha256(path: Path):
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def prepare(task: str):
    archive = REPO / 'tasks' / (task + '.zip')
    target = REPO / 'tasks' / task
    if not archive.is_file():
        raise FileNotFoundError(archive)
    with ZipFile(archive) as zipped:
        for item in zipped.infolist():
            parts = PurePosixPath(item.filename).parts
            if parts[:2] != ('tasks', task) or '..' in parts or item.filename.startswith('/'):
                raise ValueError(f'Unsafe archive member: {item.filename}')
        if not (target / 'task_config.json').is_file() or not (target / 'scripts/test.gd').is_file():
            zipped.extractall(REPO)
    validator = target / 'scripts/test.gd'
    if not (target / 'task_config.json').is_file() or not validator.is_file():
        raise FileNotFoundError(f'Incomplete task: {task}')
    return sha256(archive), sha256(validator)


def task_list(value):
    if value in ('shader', 'shader-authoring'):
        manifest = json.loads((BASE / 'audit/shader_task_selection.json').read_text(encoding='utf-8'))
        selected = manifest['selected']
        if value == 'shader-authoring':
            selected = [row for row in selected if row['category'] == 'shader_authoring']
        tasks = [row['task_name'] for row in selected]
        expected = 12 if value == 'shader' else 7
        if len(tasks) != expected or len(tasks) != len(set(tasks)) or any(not TASK_RE.fullmatch(x) for x in tasks):
            raise ValueError('Shader task selection is incomplete or invalid')
        return tasks
    if value == 'all':
        return sorted(p.stem for p in (REPO / 'tasks').glob('task_*.zip') if TASK_RE.fullmatch(p.stem))
    if value == 'official-failures':
        with (BASE / 'audit/official_failures.csv').open(encoding='utf-8-sig', newline='') as handle:
            tasks = [row['task_name'] for row in csv.DictReader(handle)]
        if len(tasks) != 104 or len(tasks) != len(set(tasks)) or any(not TASK_RE.fullmatch(x) for x in tasks):
            raise ValueError('Official failure inventory is incomplete or invalid')
        return tasks
    tasks = [x.strip() for x in value.split(',') if x.strip()]
    if not tasks or len(tasks) != len(set(tasks)) or any(not TASK_RE.fullmatch(x) for x in tasks):
        raise ValueError('Use all or a comma-separated list of unique task_XXXX names')
    return tasks


def model_config(key):
    registry = json.loads((BASE / 'shader_comparison_models.json').read_text(encoding='utf-8'))
    models = {item['key']: item for item in registry['models']}
    if key not in models:
        raise ValueError(f'Unknown model key: {key}')
    return models[key]


def save_summary(directory, state):
    rows = []
    for task in state['tasks']:
        item = state['items'][task]
        row = {'task': task, 'model_key': state.get('config', {}).get('model_key', ''),
               'model_id': state.get('config', {}).get('model', ''),
               **{name: item.get(name, '') for name in FIELDS[5:]}}
        rows.append(row)
    path = directory / 'results.csv'
    tmp = path.with_suffix('.csv.tmp')
    with tmp.open('w', encoding='utf-8-sig', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(rows)
    csv_stale = False
    try:
        os.replace(tmp, path)
    except PermissionError:
        # Windows programs such as Excel can hold results.csv open across WSL.
        # state.json remains authoritative; retain the newest CSV at the tmp path.
        csv_stale = True
    counts = {}
    for row in rows:
        counts[row['state']] = counts.get(row['state'], 0) + 1
    atomic_json(directory / 'summary.json', {
        'batch_id': state['batch_id'], 'model': state.get('config', {}).get('model', ''),
        'total': len(rows), 'counts': counts,
        'updated_at': now(), 'results_csv': str(path),
        'results_csv_stale': csv_stale,
        'latest_csv': str(tmp if csv_stale else path)})


def persist(directory, state):
    state['updated_at'] = now()
    atomic_json(directory / 'state.json', state)
    save_summary(directory, state)


def artifact_for(run_name, task):
    root = REPO / 'tasks/test_result' / run_name
    candidates = sorted(root.glob(f'{task}_opencode_*/result.json'))
    return candidates[-1] if candidates else None


def live_artifact_for(run_name, task):
    root = REPO / 'tasks/test_result' / run_name
    candidates = sorted(root.glob(f'{task}_opencode_*'))
    return candidates[-1] if candidates else None


def capture_result(item, run_names, task):
    for run_name in reversed(run_names):
        result_path = REPO / 'results' / run_name / f'task_{task}.json'
        solver_path = artifact_for(run_name, task)
        if not result_path.is_file() or not solver_path:
            continue
        official = json.loads(result_path.read_text(encoding='utf-8'))
        solver = json.loads(solver_path.read_text(encoding='utf-8'))
        validator = REPO / 'tasks' / task / 'scripts/test.gd'
        message = official.get('message', '')
        matches = []
        if message and validator.is_file():
            for number, line in enumerate(validator.read_text(encoding='utf-8').splitlines(), 1):
                if message in line:
                    matches.append(number)
        item.update({
            'official_success': bool(official.get('success')),
            'official_message': message,
            'official_details': json.dumps(official.get('details', {}), ensure_ascii=False),
            'validator_error_line': ','.join(map(str, matches)),
            'solver_success': bool(solver.get('solver', {}).get('success')),
            'reported_model': official.get('model') or solver.get('solver', {}).get('model', ''),
            'solver_message': solver.get('solver', {}).get('message', ''),
            'solver_duration': solver.get('solver', {}).get('duration_seconds', ''),
            'cost_usd': solver.get('solver', {}).get('cost_usd', ''),
            'input_tokens': solver.get('solver', {}).get('token_usage', {}).get('input_tokens', ''),
            'output_tokens': solver.get('solver', {}).get('token_usage', {}).get('output_tokens', ''),
            'is_rate_limited': solver.get('solver', {}).get('is_rate_limited', ''),
            'run_name': run_name,
            'result_json': str(result_path),
            'solver_result_json': str(solver_path),
            'artifact_dir': str(solver_path.parent),
            'trajectory_log': str(solver_path.parent / 'agent_trajectory.log'),
        })
        item['state'] = 'completed'
        item['classification'] = ('official_pass' if item['official_success'] else
                                  'official_fail_review_needed' if item['solver_success'] else
                                  'solver_incomplete')
        if not item['solver_success']:
            trajectory = solver_path.parent / 'agent_trajectory.log'
            if trajectory.is_file():
                http_status = api_rejection_status(
                    {'solver_success': False, 'success': False},
                    trajectory.read_text(encoding='utf-8', errors='replace'))
                if http_status is not None:
                    item['state'] = 'blocked_api'
                    item['classification'] = 'api_rejection_exhausted'
                    item['api_http_status'] = http_status
                else:
                    transport_message = api_transport_error(
                        {'solver_success': False, 'success': False},
                        trajectory.read_text(encoding='utf-8', errors='replace'))
                    if transport_message:
                        item['state'] = 'blocked_transport'
                        item['classification'] = 'api_transport_failure'
                        item['transport_error'] = transport_message
        return True
    return False


def track_trajectory(path, offset, counts):
    if not path.is_file():
        return offset, None
    size = path.stat().st_size
    if size < offset:
        offset = 0
    last = None
    with path.open('r', encoding='utf-8', errors='replace') as handle:
        handle.seek(offset)
        while True:
            line = handle.readline()
            if not line or not line.endswith('\n'):
                break
            offset = handle.tell()
            if not line.startswith('{'):
                continue
            try:
                event = json.loads(line)
            except ValueError:
                continue
            kind = event.get('type')
            if kind == 'step_start':
                counts['steps'] += 1
                last = f"模型正在输出（第 {counts['steps']} 轮）"
            elif kind == 'tool_use':
                counts['tools'] += 1
                tool = event.get('part', {}).get('tool', '?')
                last = f"模型调用工具 {tool}（累计 {counts['tools']} 次）"
            elif kind == 'error':
                counts['errors'] += 1
                last = f"模型/API 错误事件（累计 {counts['errors']} 次）"
    return offset, last


def live_opencode_counts(home: Path):
    database = home / '.local/share/opencode/opencode.db'
    if not database.is_file():
        return None
    try:
        with sqlite3.connect(f'file:{database}?mode=ro', uri=True, timeout=0.2) as db:
            rows = db.execute('SELECT json_extract(data, "$.type"), count(*) FROM part GROUP BY 1').fetchall()
            result = {kind: count for kind, count in rows}
            result['messages'] = db.execute('SELECT count(*) FROM message').fetchone()[0]
            return result
    except (sqlite3.Error, OSError):
        return None


def stream_lines(pipe, output):
    try:
        for line in pipe:
            output.put(line.rstrip('\r\n'))
    finally:
        output.put(None)


def stop_child(process):
    if process.poll() is not None:
        return
    os.killpg(process.pid, signal.SIGINT)
    try:
        process.wait(timeout=12)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()


class StopRequested(Exception):
    pass


def run_one(directory, state, task, index, stop_event=None):
    item = state['items'][task]
    total = state.get('display_total', len(state['tasks']))
    if item.get('attempts', 0):
        item.setdefault('attempt_history', []).append({
            'attempt': item['attempts'], 'state': item.get('state'),
            'classification': item.get('classification'),
            'solver_message': item.get('solver_message'),
            'run_name': item.get('run_name'),
            'started_at': item.get('started_at'),
            'finished_at': item.get('finished_at'),
        })
    for field in FIELDS[7:]:
        item.pop(field, None)
    item.pop('reported_model', None)
    item.pop('model_match', None)
    item['attempts'] += 1
    item['started_at'] = now()
    item['finished_at'] = ''
    item['state'] = 'running'
    item['classification'] = ''
    item['archive_sha256'], item['validator_sha256'] = prepare(task)
    log_path = directory / 'console' / f'{task}_attempt_{item["attempts"]}.log'
    log_path.parent.mkdir(parents=True, exist_ok=True)
    item['console_log'] = str(log_path)
    persist(directory, state)
    model_key = state.get('config', {}).get('model_key', 'gpt6_astra')
    model_id = state.get('config', {}).get('model', 'openai/gpt-6-astra')
    print(f'[{index}/{total}] {task} | {model_id}: 准备完成，启动模型', flush=True)
    if stop_event is not None and stop_event.is_set():
        item.update(state='interrupted', classification='stopped_before_model',
                    finished_at=now(), exit_code=130)
        persist(directory, state)
        raise StopRequested()
    command = [sys.executable, str(BASE / 'run_gpt6_smoke.py'), '--aligned', '--batch',
               '--model-key', model_key, task]
    existing_homes = set(Path('/tmp').glob('gdb-home-*'))
    process = subprocess.Popen(command, cwd=REPO, env=os.environ.copy(),
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               text=True, bufsize=1, start_new_session=True)
    lines = queue.Queue()
    threading.Thread(target=stream_lines, args=(process.stdout, lines), daemon=True).start()
    run_names = []
    offsets = {}
    counts = {'steps': 0, 'tools': 0, 'errors': 0}
    last_heartbeat = 0
    last_live_check = 0
    last_live_count = -1
    live_counts = None
    reader_done = False
    try:
        with log_path.open('w', encoding='utf-8') as log:
            while process.poll() is None or not reader_done:
                if stop_event is not None and stop_event.is_set():
                    raise StopRequested()
                try:
                    line = lines.get(timeout=1)
                except queue.Empty:
                    line = ''
                if line is None:
                    reader_done = True
                elif line:
                    log.write(line + '\n')
                    log.flush()
                    match = RUN_RE.match(line)
                    if match:
                        run_names.append(match.group(1))
                        item['run_name'] = run_names[-1]
                        persist(directory, state)
                        print(f'[{index}/{total}] {task}: 求解中，运行 {run_names[-1]}', flush=True)
                    elif line.startswith('API HTTP'):
                        print(f'[{index}/{total}] {task}: {line}', flush=True)
                    elif line.startswith('Validation result saved'):
                        print(f'[{index}/{total}] {task}: 官方验证完成', flush=True)
                if run_names:
                    artifact_dir = live_artifact_for(run_names[-1], task)
                    if artifact_dir:
                        path = artifact_dir / 'agent_trajectory.log'
                        offset, event = track_trajectory(path, offsets.get(str(path), 0), counts)
                        offsets[str(path)] = offset
                        if event:
                            print(f'[{index}/{total}] {task}: {event}', flush=True)
                if state.get('enable_live_counts', True) and time.monotonic() - last_live_check >= 5:
                    last_live_check = time.monotonic()
                    homes = set(Path('/tmp').glob('gdb-home-*')) - existing_homes
                    if len(homes) == 1:
                        live_counts = live_opencode_counts(next(iter(homes)))
                        if live_counts:
                            activity = sum(live_counts.get(k, 0) for k in ('text', 'reasoning', 'tool'))
                            if activity > last_live_count:
                                last_live_count = activity
                                print(f'[{index}/{total}] {task}: 模型活动：输出片段 {live_counts.get("text", 0)}，推理片段 {live_counts.get("reasoning", 0)}，工具调用 {live_counts.get("tool", 0)}', flush=True)
                if time.monotonic() - last_heartbeat >= 30:
                    last_heartbeat = time.monotonic()
                    elapsed = int((datetime.now(timezone.utc) - datetime.fromisoformat(item['started_at'])).total_seconds())
                    if live_counts:
                        detail = f'模型活动：输出片段 {live_counts.get("text", 0)}，推理片段 {live_counts.get("reasoning", 0)}，工具调用 {live_counts.get("tool", 0)}'
                        item['live_progress'] = live_counts
                        persist(directory, state)
                    elif counts['steps']:
                        detail = f'已观测模型轮次 {counts["steps"]}，工具调用 {counts["tools"]}'
                    else:
                        detail = '模型/项目求解中；原版 OpenCode 求解器结束后才写出逐步轨迹'
                    print(f'[{index}/{total}] {task}: 运行 {elapsed}s；{detail}', flush=True)
    except (KeyboardInterrupt, StopRequested):
        print(f'[{index}/{total}] {task}: 收到停止信号，保存检查点并停止子进程', flush=True)
        stop_child(process)
        item['state'] = 'interrupted'
        item['finished_at'] = now()
        item['exit_code'] = 130
        persist(directory, state)
        raise
    item['exit_code'] = process.wait()
    item['finished_at'] = now()
    if not capture_result(item, run_names, task):
        item['state'] = 'runner_error'
        item['classification'] = 'no_complete_result'
        item['solver_message'] = f'No complete result JSON; process exit {item["exit_code"]}'
    elif item.get('reported_model'):
        item['model_match'] = item['reported_model'].split('/')[-1] == model_id.split('/')[-1]
    persist(directory, state)
    print(f'[{index}/{total}] {task}: {item["classification"]} | {item.get("official_message", item.get("solver_message", ""))}', flush=True)


def run_worker(directory, batch_id, task, index, total, initial_item, stop_event, config=None):
    worker_dir = directory / 'workers' / task
    worker_state = {
        'batch_id': batch_id, 'tasks': [task], 'display_total': total,
        'items': {task: dict(initial_item)}, 'enable_live_counts': False,
        'config': config or {},
    }
    if stop_event.is_set():
        worker_state['items'][task].update(state='interrupted',
                                          classification='stopped_before_model',
                                          finished_at=now(), exit_code=130)
        persist(worker_dir, worker_state)
        return worker_state['items'][task]
    try:
        run_one(worker_dir, worker_state, task, index, stop_event)
    except StopRequested:
        pass
    except Exception as exc:
        item = worker_state['items'][task]
        item.update(state='runner_error', classification='runner_exception',
                    solver_message=f'{type(exc).__name__}: {exc}', finished_at=now())
        persist(worker_dir, worker_state)
        print(f'[{index}/{total}] {task}: 运行器错误 {type(exc).__name__}: {exc}', flush=True)
    return worker_state['items'][task]


def run_parallel(directory, state, pending, parallel):
    stop_event = threading.Event()
    active = {}
    remaining = iter(pending)
    interrupted = False
    api_blocked = False
    runner_blocked = False
    with ThreadPoolExecutor(max_workers=parallel) as pool:
        try:
            while True:
                while not stop_event.is_set() and len(active) < parallel:
                    try:
                        index, task = next(remaining)
                    except StopIteration:
                        break
                    item = state['items'][task]
                    item['state'] = 'running'
                    persist(directory, state)
                    future = pool.submit(run_worker, directory, state['batch_id'], task,
                                         index, len(state['tasks']), item, stop_event,
                                         state.get('config', {}))
                    active[future] = (index, task)
                if not active:
                    break
                done, _ = wait(active, timeout=1, return_when=FIRST_COMPLETED)
                for future in done:
                    index, task = active.pop(future)
                    state['items'][task] = future.result()
                    persist(directory, state)
                    if state['items'][task]['state'] in ('blocked_api', 'blocked_transport'):
                        api_blocked = True
                        stop_event.set()
                        print(f'{task}: API 请求未完成；停止启动新题，并中断仍在运行的任务', flush=True)
                    elif state['items'][task]['state'] == 'runner_error':
                        runner_blocked = True
                        stop_event.set()
                        print(f'{task}: 运行器未取得完整结果；停止启动新题，并中断仍在运行的任务', flush=True)
        except KeyboardInterrupt:
            interrupted = True
            stop_event.set()
            print('收到 Ctrl+C，正在停止所有运行中的任务并保存检查点', flush=True)
            for future, (_, task) in list(active.items()):
                try:
                    state['items'][task] = future.result(timeout=30)
                except Exception as exc:
                    state['items'][task].update(state='interrupted',
                                                solver_message=f'Stop cleanup: {type(exc).__name__}',
                                                finished_at=now())
                persist(directory, state)
    if interrupted:
        return 130
    if api_blocked:
        return 3
    if runner_blocked:
        return 2
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--batch-id', default='gpt6_astra_shader')
    parser.add_argument('--model-key', default='gpt6_astra')
    parser.add_argument('--tasks', default='shader', help='shader, shader-authoring, all, official-failures, or task_0001,task_0002')
    parser.add_argument('--max-tasks', type=int, default=0, help='0 means all pending tasks')
    parser.add_argument('--parallel', type=int, default=2, help='concurrent tasks (1-16; default 2)')
    parser.add_argument('--status', action='store_true', help='show checkpoint without API access')
    parser.add_argument('--stop', action='store_true', help='interrupt the running batch without API access')
    parser.add_argument('--init-only', action='store_true', help='create checkpoint without API access')
    args = parser.parse_args()
    if not re.fullmatch(r'[a-zA-Z0-9_-]{1,64}', args.batch_id):
        parser.error('Invalid batch ID')
    if not 1 <= args.parallel <= 16:
        parser.error('--parallel must be between 1 and 16')
    try:
        selected_model = model_config(args.model_key)
    except ValueError as exc:
        parser.error(str(exc))
    directory = ROOT / args.batch_id
    directory.mkdir(parents=True, exist_ok=True)
    state_path = directory / 'state.json'
    lock_path = directory / '.lock'
    if args.status:
        if not state_path.is_file():
            parser.error('No saved batch exists')
        state = json.loads(state_path.read_text(encoding='utf-8'))
        summary_path = directory / 'summary.json'
        summary = json.loads(summary_path.read_text(encoding='utf-8')) if summary_path.is_file() else {}
        counts = {}
        for item in state['items'].values():
            counts[item['state']] = counts.get(item['state'], 0) + 1
        print(json.dumps({'batch_id': args.batch_id, 'model': state.get('config', {}).get('model'),
                          'total': len(state['tasks']),
                          'counts': counts, 'results_csv': str(directory / 'results.csv'),
                          'results_csv_stale': summary.get('results_csv_stale', False),
                          'latest_csv': summary.get('latest_csv', str(directory / 'results.csv'))},
                         ensure_ascii=False, indent=2))
        return 0
    if args.stop:
        try:
            pid = int(lock_path.read_text(encoding='ascii').strip())
            command = Path(f'/proc/{pid}/cmdline').read_bytes()
        except (OSError, ValueError):
            print('该批次没有正在运行的进程', flush=True)
            return 0
        if b'run_batch.py' not in command or args.batch_id.encode() not in command:
            print('该批次没有匹配的运行进程；未发送停止信号', flush=True)
            return 0
        os.kill(pid, signal.SIGINT)
        for _ in range(60):
            time.sleep(0.5)
            try:
                command = Path(f'/proc/{pid}/cmdline').read_bytes()
            except OSError:
                print('批次进程已停止', flush=True)
                return 0
            if b'run_batch.py' not in command or args.batch_id.encode() not in command:
                print('批次进程已停止', flush=True)
                return 0
        print('已发送停止信号，但进程仍在清理；请稍后检查状态', flush=True)
        return 2
    with lock_path.open('w+') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            parser.error('This batch is already running')
        lock.write(str(os.getpid()))
        lock.flush()
        if state_path.is_file():
            state = json.loads(state_path.read_text(encoding='utf-8'))
            if state.get('config', {}).get('model', 'openai/gpt-6-astra') != selected_model['opencode_id']:
                parser.error('Model differs from saved batch; use its original model or a new --batch-id')
            if args.tasks != 'all' and task_list(args.tasks) != state['tasks']:
                parser.error('Task list differs from saved batch; use a new --batch-id')
        else:
            if args.status:
                parser.error('No saved batch exists')
            tasks = task_list(args.tasks)
            state = {'schema_version': 1, 'batch_id': args.batch_id, 'created_at': now(),
                     'tasks': tasks, 'items': {t: {'state': 'pending', 'attempts': 0} for t in tasks},
                     'config': {'agent': 'opencode', 'model': selected_model['opencode_id'],
                                'model_key': args.model_key,
                                'provider': 'https://api.shubiaobiao.cn/v1', 'effort': 'high',
                                'runtime_video': True, 'godot': '4.4.1',
                                'confinement': 'strict', 'solver_timeout_seconds': 600,
                                'parallel': args.parallel,
                                'api_error_retry_seconds': 300, 'api_error_max_retries': 3,
                                'comparability': 'OpenCode/Shubiaobiao adapter; not the authors Codex CLI run'}}
            persist(directory, state)
        if args.init_only:
            print(f'批次已创建：{directory / "state.json"}；题目数 {len(state["tasks"])}', flush=True)
            return 0
        reconciled = 0
        for task in state['tasks']:
            item = state['items'][task]
            worker_state_path = directory / 'workers' / task / 'state.json'
            if item['state'] != 'completed' and worker_state_path.is_file():
                worker_state = json.loads(worker_state_path.read_text(encoding='utf-8'))
                worker_item = worker_state.get('items', {}).get(task, {})
                if worker_item.get('state') == 'completed':
                    state['items'][task] = worker_item
                    reconciled += 1
                    continue
                if worker_item.get('attempts', 0) > item.get('attempts', 0):
                    state['items'][task] = worker_item
                    item = worker_item
            if item['state'] != 'completed' and item.get('run_name'):
                if capture_result(item, [item['run_name']], task):
                    item['finished_at'] = item.get('finished_at') or now()
                    reconciled += 1
        if reconciled:
            persist(directory, state)
            print(f'恢复了 {reconciled} 个已写入原始结果、尚未写入检查点的任务', flush=True)
        pending = [(i, task) for i, task in enumerate(state['tasks'], 1)
                   if state['items'][task]['state'] != 'completed']
        if args.max_tasks < 0:
            parser.error('--max-tasks must be nonnegative')
        if args.max_tasks:
            pending = pending[:args.max_tasks]
        print(f'批次 {args.batch_id}: 总计 {len(state["tasks"])} 题，本次待跑 {len(pending)} 题；Ctrl+C 可保存并退出', flush=True)
        state['config']['parallel'] = args.parallel
        persist(directory, state)
        print(f'并发任务数：{args.parallel}', flush=True)
        print(f'状态: {directory / "state.json"} | 汇总: {directory / "results.csv"}', flush=True)
        if args.parallel > 1:
            result = run_parallel(directory, state, pending, args.parallel)
            if result:
                return result
            print(f'批次本次运行结束；结果: {directory / "results.csv"}', flush=True)
            return 0
        for index, task in pending:
            try:
                run_one(directory, state, task, index)
                if state['items'][task]['state'] in ('blocked_api', 'blocked_transport'):
                    print(f'{task}: API 请求未完成；暂停批次，检查接口后再次运行同一命令续跑', flush=True)
                    return 3
            except KeyboardInterrupt:
                return 130
            except Exception as exc:
                item = state['items'][task]
                item.update(state='runner_error', classification='runner_exception',
                            solver_message=f'{type(exc).__name__}: {exc}', finished_at=now())
                persist(directory, state)
                print(f'[{index}/{len(state["tasks"])}] {task}: 运行器错误 {type(exc).__name__}: {exc}', flush=True)
                return 2
        print(f'批次本次运行结束；结果: {directory / "results.csv"}', flush=True)
    return 0


if __name__ == '__main__':
    sys.exit(main())
