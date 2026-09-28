"""Resume the four-model experiment on the 104 published Astra failures.

Raw prompts and trajectories stay in the local GameDevBench tree. This script
does not upload results or print task instructions.
"""
from __future__ import annotations

import argparse
import csv
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import subprocess
import sys

from run_shader_comparison import catalog_ids

BASE = Path(__file__).resolve().parent
REPO = BASE.parent / 'gamedevbench-main' / 'gamedevbench-main'
ROOT = BASE / 'batch_runs'
COMPARISON = ROOT / 'official_failures_comparison'
BASELINE = REPO / 'results/gpt6_astra_codex_runtime_video_high_full_333/final_results.json'
FAILURES_CSV = BASE / 'audit/official_failures.csv'
TASK_COUNT = 104


def selected_tasks() -> list[str]:
    baseline = json.loads(BASELINE.read_text(encoding='utf-8'))
    config = baseline['configuration']
    required = {'agent': 'codex', 'model': 'gpt-6-astra', 'use_runtime_video': True,
                'effort': 'high', 'godot_version': '4.4.1.stable.official.49a5bc7b6'}
    if any(config.get(key) != value for key, value in required.items()):
        raise ValueError('Published Astra baseline configuration changed')
    failed = {item['task_name'] for item in baseline['tasks'] if item.get('success') is False
              and item.get('solver_success') is True}
    with FAILURES_CSV.open(encoding='utf-8-sig', newline='') as handle:
        tasks = [row['task_name'] for row in csv.DictReader(handle)]
    if len(tasks) != TASK_COUNT or len(set(tasks)) != TASK_COUNT or set(tasks) != failed:
        raise ValueError('104-task selection differs from the published baseline')
    for task in tasks:
        if not (REPO / 'tasks' / f'{task}.zip').is_file():
            raise FileNotFoundError(f'Missing input ZIP: {task}')
    return tasks


def models() -> tuple[str, list[dict]]:
    registry = json.loads((BASE / 'shader_comparison_models.json').read_text(encoding='utf-8'))
    selected = []
    for item in registry['models']:
        selected.append({**item, 'batch_id': item['key'] + '_official_failures_104'})
    if len(selected) != 4 or len({item['key'] for item in selected}) != 4:
        raise ValueError('Expected four unique models')
    return registry['provider_base_url'], selected


def state_for(model: dict) -> dict | None:
    path = ROOT / model['batch_id'] / 'state.json'
    return json.loads(path.read_text(encoding='utf-8')) if path.is_file() else None


def counts(state: dict | None) -> dict:
    result = {}
    if state:
        for item in state['items'].values():
            value = item['state']
            result[value] = result.get(value, 0) + 1
    return result


def save_comparison(selected: list[dict]) -> None:
    COMPARISON.mkdir(parents=True, exist_ok=True)
    rows = []
    for index, model in enumerate(selected, 1):
        csv_path = ROOT / model['batch_id'] / 'results.csv'
        summary_path = ROOT / model['batch_id'] / 'summary.json'
        if summary_path.is_file():
            summary = json.loads(summary_path.read_text(encoding='utf-8'))
            if summary.get('results_csv_stale'):
                pending = Path(summary.get('latest_csv', ''))
                if pending.is_file():
                    csv_path = pending
        if not csv_path.is_file():
            continue
        with csv_path.open(encoding='utf-8-sig', newline='') as handle:
            for row in csv.DictReader(handle):
                row['model_key'] = model['key']
                row['model_id'] = model['opencode_id']
                rows.append({'model_order': index, 'batch_id': model['batch_id'], **row})
    comparison_stale = False
    latest_comparison = COMPARISON / 'comparison.csv'
    if rows:
        fields = ['model_order', 'batch_id']
        for row in rows:
            fields.extend(key for key in row if key not in fields)
        temporary = COMPARISON / 'comparison.csv.tmp'
        with temporary.open('w', encoding='utf-8-sig', newline='') as handle:
            writer = csv.DictWriter(handle, fieldnames=fields)
            writer.writeheader()
            writer.writerows(rows)
        try:
            os.replace(temporary, COMPARISON / 'comparison.csv')
        except PermissionError:
            # Windows Excel may hold the CSV open. The checkpoint remains authoritative.
            comparison_stale = True
            latest_comparison = temporary
    baseline = json.loads(BASELINE.read_text(encoding='utf-8'))
    selected_set = set(selected_tasks())
    baseline_messages = {item['task_name']: item['message'] for item in baseline['tasks']
                         if item['task_name'] in selected_set}
    review = []
    for row in rows:
        if row['state'] != 'completed':
            finding = 'pending_or_interrupted'
        elif row['solver_success'].lower() != 'true':
            finding = 'solver_incomplete'
        elif row['official_success'].lower() == 'true':
            finding = 'local_official_pass_not_false_negative_proof'
        elif row['official_message'] == baseline_messages[row['task']]:
            finding = 'same_first_failure'
        else:
            finding = 'different_failure_review'
        review.append({'task': row['task'], 'model': row['model_id'],
                       'author_astra_message': baseline_messages[row['task']],
                       'local_success': row['official_success'],
                       'local_message': row['official_message'],
                       'solver_success': row['solver_success'],
                       'triage': finding, 'false_negative_verdict': 'not_reviewed',
                       'validator_error_line': row['validator_error_line'],
                       'artifact_dir': row['artifact_dir'],
                       'result_json': row['result_json'],
                       'trajectory_log': row['trajectory_log']})
    review_target = COMPARISON / 'review_queue.csv'
    review_tmp = review_target.with_suffix('.csv.tmp')
    with review_tmp.open('w', encoding='utf-8-sig', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=list(review[0]) if review else
                                ['task', 'model', 'false_negative_verdict'])
        writer.writeheader()
        writer.writerows(review)
    try:
        os.replace(review_tmp, review_target)
    except PermissionError:
        pass
    summary = {'updated_at': datetime.now(timezone.utc).isoformat(timespec='seconds'),
               'task_count_per_model': TASK_COUNT, 'expected_total': TASK_COUNT * len(selected),
               'published_baseline': str(BASELINE), 'published_agent': 'codex',
               'local_agent': 'opencode', 'prompt_publication': 'local_only',
               'comparison_csv': str(COMPARISON / 'comparison.csv'),
               'comparison_csv_stale': comparison_stale,
               'latest_csv': str(latest_comparison),
               'review_queue_csv': str(review_target),
               'models': [{'order': index, 'model': model['opencode_id'],
                           'batch_id': model['batch_id'], 'counts': counts(state_for(model))}
                          for index, model in enumerate(selected, 1)]}
    temporary = COMPARISON / 'summary.json.tmp'
    temporary.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    os.replace(temporary, COMPARISON / 'summary.json')


def run_batch(model: dict, args: argparse.Namespace, action: str | None = None) -> int:
    command = [sys.executable, str(BASE / 'run_batch.py'), '--batch-id', model['batch_id'],
               '--model-key', model['key']]
    if action:
        command.append(action)
        if action == '--init-only':
            command += ['--tasks', 'official-failures']
    else:
        command += ['--tasks', 'official-failures', '--parallel', str(args.parallel)]
        if args.max_tasks:
            command += ['--max-tasks', str(args.max_tasks)]
    return subprocess.run(command, check=False).returncode


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--parallel', type=int, default=2)
    parser.add_argument('--max-tasks', type=int, default=0,
                        help='For a pilot: run at most this many pending tasks in the current model')
    parser.add_argument('--status', action='store_true')
    parser.add_argument('--stop', action='store_true')
    parser.add_argument('--init-only', action='store_true')
    parser.add_argument('--review-only', action='store_true',
                        help='Resume the independent Astra post-score audit')
    args = parser.parse_args()
    if not 1 <= args.parallel <= 16 or args.max_tasks < 0:
        parser.error('--parallel must be 1..16 and --max-tasks nonnegative')
    base_url, selected = models()
    tasks = selected_tasks()
    if args.status:
        print(json.dumps([{'model': item['opencode_id'], 'batch_id': item['batch_id'],
                           'counts': counts(state_for(item))} for item in selected],
                         ensure_ascii=False, indent=2))
        return 0
    if args.stop:
        codes = [run_batch(item, args, '--stop') for item in selected]
        return max(codes)
    if args.init_only:
        for item in selected:
            code = run_batch(item, args, '--init-only')
            if code:
                return code
        save_comparison(selected)
        subprocess.run([sys.executable, str(BASE / 'review_failure_cases.py'), '--index-only'], check=True)
        print('Four 104-task checkpoints created; no model call was made.', flush=True)
        return 0
    if args.review_only:
        command = [sys.executable, str(BASE / 'review_failure_cases.py')]
        if args.max_tasks:
            command += ['--max-tasks', str(args.max_tasks)]
        return subprocess.run(command, check=False).returncode
    for index, model in enumerate(selected, 1):
        state = state_for(model)
        if state and state['tasks'] != tasks:
            raise ValueError(f'Task list changed for {model["batch_id"]}')
        if state and all(item['state'] == 'completed' for item in state['items'].values()):
            print(f'[{index}/4] {model["opencode_id"]}: 104/104 已完成', flush=True)
            continue
        print(f'[{index}/4] 当前模型：{model["opencode_id"]}；核对 API 模型目录', flush=True)
        available = catalog_ids(base_url)
        if model['api_id'] not in available:
            raise ValueError(f'{model["api_id"]} absent from provider catalog; no task started')
        print(f'[{index}/4] {model["opencode_id"]}: 开始或恢复 104 题', flush=True)
        code = run_batch(model, args)
        save_comparison(selected)
        if code:
            print(f'{model["opencode_id"]}: 批次暂停，退出码 {code}；重启可续跑', flush=True)
            return code
        state = state_for(model)
        if not state or any(item['state'] != 'completed' for item in state['items'].values()):
            print(f'{model["opencode_id"]}: 仍有未完成任务；重启可续跑', flush=True)
            return 2
    save_comparison(selected)
    subprocess.run([sys.executable, str(BASE / 'review_failure_cases.py'), '--prepare-evidence-only'], check=True)
    print('四模型 × 104 题已保存；Astra 事后评审索引已保存，外部评审调用未启用。', flush=True)
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (RuntimeError, OSError, ValueError, KeyError) as exc:
        print(f'实验未继续：{exc}', file=sys.stderr, flush=True)
        sys.exit(2)
