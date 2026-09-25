"""Run the same twelve shader tasks sequentially across four models, with resume."""
from __future__ import annotations

import argparse
import csv
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import subprocess
import sys
import urllib.error
import urllib.request

BASE = Path(__file__).resolve().parent
PYTHON = sys.executable
RUNNER = BASE / 'run_batch.py'
ROOT = BASE / 'batch_runs'
COMPARISON = ROOT / 'shader_comparison'


def models():
    registry = json.loads((BASE / 'shader_comparison_models.json').read_text(encoding='utf-8'))
    return registry['provider_base_url'], registry['models']


def state_for(model):
    path = ROOT / model['batch_id'] / 'state.json'
    return json.loads(path.read_text(encoding='utf-8')) if path.is_file() else None


def counts(state):
    result = {}
    if state:
        for item in state['items'].values():
            value = item['state']
            result[value] = result.get(value, 0) + 1
    return result


def save_comparison(selected):
    COMPARISON.mkdir(parents=True, exist_ok=True)
    rows = []
    for index, model in enumerate(selected, 1):
        csv_path = ROOT / model['batch_id'] / 'results.csv'
        summary_path = ROOT / model['batch_id'] / 'summary.json'
        if summary_path.is_file():
            batch_summary = json.loads(summary_path.read_text(encoding='utf-8'))
            if batch_summary.get('results_csv_stale'):
                pending = Path(batch_summary.get('latest_csv', ''))
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
            fields.extend(field for field in row if field not in fields)
        target = COMPARISON / 'comparison.csv'
        temporary = target.with_suffix('.csv.tmp')
        with temporary.open('w', encoding='utf-8-sig', newline='') as handle:
            writer = csv.DictWriter(handle, fieldnames=fields)
            writer.writeheader()
            writer.writerows(rows)
        try:
            os.replace(temporary, target)
        except PermissionError:
            # A Windows spreadsheet can hold the comparison CSV open too.
            comparison_stale = True
            latest_comparison = temporary
    summary = {'updated_at': datetime.now(timezone.utc).isoformat(timespec='seconds'),
               'task_count_per_model': 12,
               'models': [{'order': index, 'model': model['opencode_id'],
                           'batch_id': model['batch_id'], 'counts': counts(state_for(model))}
                          for index, model in enumerate(selected, 1)],
               'comparison_csv': str(COMPARISON / 'comparison.csv'),
               'comparison_csv_stale': comparison_stale,
               'latest_csv': str(latest_comparison)}
    target = COMPARISON / 'summary.json'
    temporary = target.with_suffix('.json.tmp')
    temporary.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    os.replace(temporary, target)


def catalog_ids(base_url):
    key = os.environ.get('OPENAI_API_KEY', '').strip()
    if not key:
        raise RuntimeError('No saved Shubiaobiao key was forwarded; no model call was made')
    request = urllib.request.Request(base_url.rstrip('/') + '/models',
                                     headers={'Authorization': 'Bearer ' + key})
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = json.load(response)
    except urllib.error.HTTPError as exc:
        raise RuntimeError(f'Provider model catalog returned HTTP {exc.code}; no benchmark task started') from None
    except urllib.error.URLError as exc:
        raise RuntimeError(f'Provider model catalog unavailable: {exc.reason}; no benchmark task started') from None
    if not isinstance(payload, dict) or not isinstance(payload.get('data'), list):
        raise RuntimeError('Provider model catalog has an unexpected format; no benchmark task started')
    return {entry['id'] for entry in payload['data'] if isinstance(entry, dict) and isinstance(entry.get('id'), str)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--parallel', type=int, default=2)
    parser.add_argument('--status', action='store_true')
    parser.add_argument('--stop', action='store_true')
    parser.add_argument('--init-only', action='store_true')
    args = parser.parse_args()
    if not 1 <= args.parallel <= 16:
        parser.error('--parallel must be between 1 and 16')
    base_url, selected = models()
    if args.status:
        save_comparison(selected)
        print(json.dumps([{'order': index, 'model': model['opencode_id'],
                           'batch_id': model['batch_id'], 'counts': counts(state_for(model)),
                           'results_csv': str(ROOT / model['batch_id'] / 'results.csv')}
                          for index, model in enumerate(selected, 1)], ensure_ascii=False, indent=2))
        return 0
    if args.stop:
        for model in selected:
            subprocess.run([PYTHON, str(RUNNER), '--batch-id', model['batch_id'],
                            '--model-key', model['key'], '--stop'], check=False)
        return 0
    if args.init_only:
        for model in selected:
            command = [PYTHON, str(RUNNER), '--batch-id', model['batch_id'],
                       '--model-key', model['key'], '--tasks', 'shader', '--init-only']
            result = subprocess.run(command, check=False)
            if result.returncode:
                return result.returncode
        save_comparison(selected)
        return 0

    for index, model in enumerate(selected, 1):
        state = state_for(model)
        if state and len(state['tasks']) == 12 and all(item['state'] == 'completed' for item in state['items'].values()):
            print(f'[{index}/{len(selected)}] {model["opencode_id"]}: 已完成 12/12，继续下一模型', flush=True)
            continue
        print(f'[{index}/{len(selected)}] 当前模型：{model["opencode_id"]}；检查 API 模型目录', flush=True)
        available = catalog_ids(base_url)
        if model['api_id'] not in available:
            raise RuntimeError(f'{model["api_id"]} is absent from the provider model catalog; '
                               'no task was started for this model. Check shader_comparison_models.json')
        print(f'[{index}/{len(selected)}] {model["opencode_id"]}: 目录确认可用，开始或恢复 12 题', flush=True)
        command = [PYTHON, str(RUNNER), '--batch-id', model['batch_id'],
                   '--model-key', model['key'], '--tasks', 'shader', '--parallel', str(args.parallel)]
        result = subprocess.run(command, check=False)
        save_comparison(selected)
        if result.returncode:
            print(f'{model["opencode_id"]}: 批次暂停，退出码 {result.returncode}；重启同一命令可续跑', flush=True)
            return result.returncode
        state = state_for(model)
        if not state or len(state['tasks']) != 12 or any(item['state'] != 'completed' for item in state['items'].values()):
            print(f'{model["opencode_id"]}: 有未完成的任务；检查 results.csv 后重新启动续跑', flush=True)
            return 2
        print(f'[{index}/{len(selected)}] {model["opencode_id"]}: 12/12 已保存', flush=True)
    save_comparison(selected)
    print('四个模型共 48 个任务均已保存。', flush=True)
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (RuntimeError, OSError, ValueError) as exc:
        print(f'对照实验未继续：{exc}', file=sys.stderr, flush=True)
        sys.exit(2)
