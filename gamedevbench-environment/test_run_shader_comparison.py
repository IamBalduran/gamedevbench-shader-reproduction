"""Offline checks for comparison output when a Windows program holds CSV open."""
import csv
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import run_shader_comparison as comparison


class ComparisonTests(unittest.TestCase):
    def test_locked_comparison_csv_keeps_latest_copy(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            model = {'key': 'gpt6_astra', 'opencode_id': 'openai/gpt-6-astra',
                     'batch_id': 'gpt6_astra_shader'}
            batch = root / model['batch_id']
            batch.mkdir()
            (batch / 'state.json').write_text(json.dumps({
                'tasks': ['task_0019'], 'items': {'task_0019': {'state': 'completed'}}}))
            with (batch / 'results.csv').open('w', newline='') as handle:
                writer = csv.DictWriter(handle, fieldnames=['task', 'state'])
                writer.writeheader()
                writer.writerow({'task': 'task_0019', 'state': 'completed'})
            target = root / 'shader_comparison' / 'comparison.csv'
            real_replace = os.replace

            def locked_csv(source, destination):
                if Path(destination) == target:
                    raise PermissionError('comparison.csv is open in Excel')
                return real_replace(source, destination)

            with patch.object(comparison, 'ROOT', root), \
                 patch.object(comparison, 'COMPARISON', target.parent), \
                 patch.object(comparison.os, 'replace', side_effect=locked_csv):
                comparison.save_comparison([model])
            summary = json.loads((target.parent / 'summary.json').read_text())
            self.assertTrue(summary['comparison_csv_stale'])
            with Path(summary['latest_csv']).open(encoding='utf-8-sig', newline='') as handle:
                rows = list(csv.DictReader(handle))
            self.assertEqual(rows[0]['model_id'], 'openai/gpt-6-astra')


if __name__ == '__main__':
    unittest.main()
