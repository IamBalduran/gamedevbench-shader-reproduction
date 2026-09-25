import json

def load_attempt_result(repo, run_name, task_name='task_0002'):
    """The results JSON is validation-only; solver data lives with artifacts."""
    artifacts = repo / 'tasks' / 'test_result' / run_name
    candidates = sorted(artifacts.glob(f'{task_name}_opencode_*/result.json'))
    if not candidates:
        return {}, ''
    path = candidates[-1]
    saved = json.loads(path.read_text())
    result = {
        'success': saved.get('validation', {}).get('success', False),
        'solver_success': saved.get('solver', {}).get('success', False),
    }
    log = path.parent / 'agent_trajectory.log'
    return result, log.read_text() if log.is_file() else ''

MAX_RETRIES = 3
RETRY_DELAY_SECONDS = 300

def api_rejection_status(result, trajectory):
    """Retry only a failed solver with an explicit HTTP API error event."""
    if result.get('solver_success') or result.get('success'):
        return None
    for line in reversed(trajectory.splitlines()):
        try:
            event = json.loads(line)
        except (ValueError, TypeError):
            continue
        if not isinstance(event, dict) or event.get('type') != 'error':
            continue
        error = event.get('error', {})
        if error.get('name') != 'APIError':
            continue
        status = error.get('data', {}).get('statusCode')
        if isinstance(status, int) and 400 <= status <= 599:
            return status
    return None


def api_transport_error(result, trajectory):
    """Return a network failure from the agent trace, never a validator failure."""
    if result.get('solver_success') or result.get('success'):
        return None
    for line in reversed(trajectory.splitlines()):
        try:
            event = json.loads(line)
        except (ValueError, TypeError):
            continue
        if not isinstance(event, dict) or event.get('type') != 'error':
            continue
        error = event.get('error', {})
        if error.get('name') != 'APIError':
            continue
        data = error.get('data', {})
        message = str(data.get('message', ''))
        if data.get('statusCode') is None and any(
            marker in message.lower() for marker in
            ('cannot connect to api', 'socket connection was closed',
             'connection reset', 'tls handshake')
        ):
            return message
    return None

def run_attempts(attempt, sleep, notify):
    """Initial attempt plus at most three delayed retries."""
    for index in range(MAX_RETRIES + 1):
        code, result, trajectory = attempt(index)
        status = api_rejection_status(result, trajectory)
        if status is None or index == MAX_RETRIES:
            return code
        notify(f'API HTTP {status}. Retrying task in {RETRY_DELAY_SECONDS} seconds ({index + 1}/{MAX_RETRIES}). Ctrl+C cancels.')
        sleep(RETRY_DELAY_SECONDS)
