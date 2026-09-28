import json
from pathlib import Path
import tempfile
import unittest

import run_batch


class ValidationFallbackTest(unittest.TestCase):
    def test_saved_solver_validation_survives_missing_top_level_json(self):
        with tempfile.TemporaryDirectory() as temporary:
            old_repo = run_batch.REPO
            run_batch.REPO = Path(temporary)
            try:
                task = "task_0048"
                path = run_batch.REPO / "tasks/test_result/example/task_0048_opencode_test/result.json"
                path.parent.mkdir(parents=True)
                path.write_text(json.dumps({
                    "validation": {"success": False, "message": "Validation timed out"},
                    "solver": {"success": True, "model": "openai/deepseek-v4-pro", "message": "done"}
                }), encoding="utf-8")
                item = {}
                self.assertTrue(run_batch.capture_result(item, ["example"], task))
                self.assertEqual(item["state"], "completed")
                self.assertEqual(item["classification"], "validation_timeout_review_needed")
                self.assertEqual(item["validation_source"], "solver_artifact_validation")
                self.assertEqual(item["result_json"], "")
                self.assertEqual(item["solver_result_json"], str(path))
            finally:
                run_batch.REPO = old_repo


if __name__ == "__main__":
    unittest.main()
