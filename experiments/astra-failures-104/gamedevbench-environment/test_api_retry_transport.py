import json
import unittest

from api_retry import run_attempts


class TransportRetryTest(unittest.TestCase):
    def test_retries_transport_three_times_then_succeeds(self):
        error = json.dumps({"type": "error", "error": {"name": "APIError", "data": {
            "statusCode": None, "message": "Cannot connect to API: socket connection was closed unexpectedly"}}})
        responses = iter([(1, {"solver_success": False}, error)] * 3 +
                         [(0, {"solver_success": True, "success": True}, "")])
        sleeps, notices = [], []
        self.assertEqual(run_attempts(lambda _: next(responses), sleeps.append, notices.append), 0)
        self.assertEqual(sleeps, [300, 300, 300])
        self.assertEqual(len(notices), 3)

    def test_does_not_retry_validator_failure(self):
        calls = []
        def attempt(index):
            calls.append(index)
            return 1, {"solver_success": True, "success": False}, ""
        self.assertEqual(run_attempts(attempt, lambda _: self.fail("unexpected sleep"), lambda _: None), 1)
        self.assertEqual(calls, [0])


if __name__ == "__main__":
    unittest.main()
