"""Offline checks for the batch checkpoint and progress reader."""
import csv
import json
import os
from pathlib import Path
import sqlite3
import tempfile
import threading
import time
import unittest
from unittest.mock import patch

import run_batch as batch


class BatchTests(unittest.TestCase):
    def test_open_results_csv_does_not_abort_checkpoint(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            state = {'batch_id': 'test', 'tasks': ['task_0019'],
                     'items': {'task_0019': {'state': 'completed', 'attempts': 1}}}
            real_replace = os.replace

            def locked_csv(source, target):
                if Path(target) == directory / 'results.csv':
                    raise PermissionError('results.csv is open in Excel')
                return real_replace(source, target)

            with patch.object(batch.os, 'replace', side_effect=locked_csv):
                batch.persist(directory, state)
            summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
            self.assertTrue(summary['results_csv_stale'])
            self.assertTrue((directory / 'state.json').is_file())
            with Path(summary['latest_csv']).open(encoding='utf-8-sig', newline='') as handle:
                self.assertEqual(list(csv.DictReader(handle))[0]['state'], 'completed')

    def test_parallel_worker_creates_nested_console_before_model_start(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            state = {'batch_id': 'test', 'tasks': ['task_0019'],
                     'config': {'model': 'openai/gpt-6-astra', 'model_key': 'gpt6_astra'},
                     'items': {'task_0019': {'state': 'pending', 'attempts': 0}}}
            worker_dir = root / 'workers' / 'task_0019'
            with patch.object(batch, 'prepare', return_value=('archive', 'validator')):
                with patch.object(batch.subprocess, 'Popen', side_effect=RuntimeError('model start intercepted')):
                    with self.assertRaisesRegex(RuntimeError, 'model start intercepted'):
                        batch.run_one(worker_dir, state, 'task_0019', 1)
            self.assertTrue((worker_dir / 'console' / 'task_0019_attempt_1.log').parent.is_dir())

    def test_retry_preserves_previous_runner_error(self):
        with tempfile.TemporaryDirectory() as temp:
            state = {'batch_id': 'test', 'tasks': ['task_0019'],
                     'config': {'model': 'openai/gpt-6-astra', 'model_key': 'gpt6_astra'},
                     'items': {'task_0019': {'state': 'runner_error', 'attempts': 1,
                                             'classification': 'runner_exception',
                                             'solver_message': 'missing console directory'}}}
            with patch.object(batch, 'prepare', return_value=('archive', 'validator')):
                with patch.object(batch.subprocess, 'Popen', side_effect=RuntimeError('intercepted')):
                    with self.assertRaises(RuntimeError):
                        batch.run_one(Path(temp), state, 'task_0019', 1)
            item = state['items']['task_0019']
            self.assertEqual(item['attempts'], 2)
            self.assertEqual(item['attempt_history'][0]['solver_message'], 'missing console directory')

    def test_shader_selection_excludes_scene_only_tasks(self):
        selected = batch.task_list('shader')
        self.assertEqual(len(selected), 12)
        self.assertIn('task_0095', selected)
        self.assertIn('task_0107', selected)
        self.assertNotIn('task_0021', selected)
        self.assertNotIn('task_0062', selected)
        self.assertEqual(len(batch.task_list('shader-authoring')), 7)

    def test_completed_result_extracts_exact_validator_message(self):
        with tempfile.TemporaryDirectory() as temp, patch.object(batch, 'REPO', Path(temp)):
            repo = Path(temp)
            result = repo / 'results/demo/task_task_0095.json'
            artifact = repo / 'tasks/test_result/demo/task_0095_opencode_001/result.json'
            validator = repo / 'tasks/task_0095/scripts/test.gd'
            for path in (result, artifact, validator):
                path.parent.mkdir(parents=True, exist_ok=True)
            result.write_text(json.dumps({'success': False, 'message': 'Shader must compile'}))
            artifact.write_text(json.dumps({'solver': {'success': True, 'duration_seconds': 12}}))
            validator.write_text('assert_or_fail(ok, "Shader must compile")\n')
            (artifact.parent / 'agent_trajectory.log').write_text('')
            item = {}
            found = batch.capture_result(item, ['demo'], 'task_0095')
            self.assertTrue(found)
            self.assertEqual(item['classification'], 'official_fail_review_needed')
            self.assertEqual(item['official_message'], 'Shader must compile')
            self.assertEqual(item['validator_error_line'], '1')
            self.assertTrue(Path(item['trajectory_log']).is_file())

    def test_transport_failure_is_not_a_model_validation_result(self):
        with tempfile.TemporaryDirectory() as temp, patch.object(batch, 'REPO', Path(temp)):
            repo = Path(temp)
            result = repo / 'results/demo/task_task_0095.json'
            artifact = repo / 'tasks/test_result/demo/task_0095_opencode_001/result.json'
            for path in (result, artifact):
                path.parent.mkdir(parents=True, exist_ok=True)
            result.write_text(json.dumps({'success': False, 'message': 'Shader check failed'}))
            artifact.write_text(json.dumps({'solver': {'success': False, 'message': 'OpenCode failed'}}))
            (artifact.parent / 'agent_trajectory.log').write_text(json.dumps({
                'type': 'error', 'error': {'name': 'APIError', 'data': {
                    'statusCode': None, 'message': 'Cannot connect to API: socket connection was closed unexpectedly'}}
            }) + '\n')
            item = {}
            self.assertTrue(batch.capture_result(item, ['demo'], 'task_0095'))
            self.assertEqual(item['state'], 'blocked_transport')
            self.assertEqual(item['classification'], 'api_transport_failure')
            self.assertEqual(item['official_message'], 'Shader check failed')

    def test_checkpoint_and_csv_are_written(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            state = {'batch_id': 'test', 'tasks': ['task_0001'],
                     'items': {'task_0001': {'state': 'pending', 'attempts': 0}}}
            batch.persist(directory, state)
            self.assertEqual(json.loads((directory / 'state.json').read_text())['items']['task_0001']['state'], 'pending')
            with (directory / 'results.csv').open(encoding='utf-8-sig', newline='') as handle:
                rows = list(csv.DictReader(handle))
            self.assertEqual(len(rows), 1)
            self.assertEqual(rows[0]['task'], 'task_0001')

    def test_live_progress_reads_counts_without_content(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            database = home / '.local/share/opencode/opencode.db'
            database.parent.mkdir(parents=True)
            with sqlite3.connect(database) as db:
                db.execute('CREATE TABLE part (data TEXT)')
                db.execute('CREATE TABLE message (data TEXT)')
                db.execute('INSERT INTO part VALUES (?)', ('{"type":"reasoning","text":"private"}',))
                db.execute('INSERT INTO part VALUES (?)', ('{"type":"tool","secret":"private"}',))
                db.execute('INSERT INTO message VALUES (?)', ('private',))
            counts = batch.live_opencode_counts(home)
            self.assertEqual(counts['reasoning'], 1)
            self.assertEqual(counts['tool'], 1)
            self.assertEqual(counts['messages'], 1)
            self.assertNotIn('private', str(counts))

    def test_parallel_scheduler_limits_workers_and_saves_results(self):
        tasks = [f'task_{n:04d}' for n in range(1, 6)]
        active = 0
        peak = 0
        gate = threading.Lock()

        def fake_worker(directory, batch_id, task, index, total, item, stop_event, config):
            nonlocal active, peak
            with gate:
                active += 1
                peak = max(peak, active)
            time.sleep(0.03)
            with gate:
                active -= 1
            return {**item, 'state': 'completed', 'classification': 'official_pass'}

        with tempfile.TemporaryDirectory() as temp, patch.object(batch, 'run_worker', fake_worker):
            state = {'batch_id': 'test', 'tasks': tasks, 'config': {'model': 'openai/gpt-6-astra'},
                     'items': {task: {'state': 'pending', 'attempts': 0} for task in tasks}}
            code = batch.run_parallel(Path(temp), state, list(enumerate(tasks, 1)), 2)
            self.assertEqual(code, 0)
            self.assertEqual(peak, 2)
            self.assertTrue(all(item['state'] == 'completed' for item in state['items'].values()))
            summary = json.loads((Path(temp) / 'summary.json').read_text())
            self.assertEqual(summary['counts']['completed'], 5)

    def test_parallel_scheduler_stops_launching_after_missing_result(self):
        tasks = [f'task_{n:04d}' for n in range(1, 7)]
        launched = []

        def fake_worker(directory, batch_id, task, index, total, item, stop_event, config):
            launched.append(task)
            if task == tasks[0]:
                return {**item, 'state': 'runner_error', 'classification': 'no_complete_result'}
            time.sleep(0.02)
            return {**item, 'state': 'interrupted', 'classification': 'stopped_before_model'}

        with tempfile.TemporaryDirectory() as temp, patch.object(batch, 'run_worker', fake_worker):
            state = {'batch_id': 'test', 'tasks': tasks, 'config': {},
                     'items': {task: {'state': 'pending', 'attempts': 0} for task in tasks}}
            code = batch.run_parallel(Path(temp), state, list(enumerate(tasks, 1)), 2)
            self.assertEqual(code, 2)
            self.assertLessEqual(len(launched), 2)


if __name__ == '__main__':
    unittest.main()
