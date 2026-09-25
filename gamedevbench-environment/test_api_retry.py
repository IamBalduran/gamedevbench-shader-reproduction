import json
from api_retry import (run_attempts, api_rejection_status, load_attempt_result,
                       MAX_RETRIES, RETRY_DELAY_SECONDS)
from pathlib import Path

def failure(status=400):
    return 1, {'solver_success': False}, json.dumps({'type':'error','error':{
        'name':'APIError','data':{'statusCode':status}}})

def test_three_retries_exactly():
    calls, delays = [], []
    def attempt(index):
        calls.append(index)
        return failure(429)
    assert run_attempts(attempt, delays.append, lambda _: None) == 1
    assert calls == [0,1,2,3]
    assert MAX_RETRIES == 3
    assert RETRY_DELAY_SECONDS == 300
    assert delays == [300,300,300]

def test_success_stops_retries():
    calls, delays = [], []
    def attempt(index):
        calls.append(index)
        return failure(503) if index == 0 else (0,{'success':True},'')
    assert run_attempts(attempt,delays.append,lambda _:None)==0
    assert calls == [0,1]
    assert delays == [300]

def test_validation_failure_does_not_retry():
    assert api_rejection_status({'solver_success':True,'success':False},failure()[2]) is None
    assert api_rejection_status({'solver_success':False},'ripgrep execution failed') is None

def test_actual_encrypted_content_failure_triggers_three_retries():
    repo = Path('/mnt/d/ShaderAgent/re/gamedevbench-main/gamedevbench-main')
    result, trajectory = load_attempt_result(repo, 'gpt6_astra_opencode_smoke_20260923_201107')
    assert result == {'success':False,'solver_success':False}
    assert api_rejection_status(result, trajectory) == 400
    calls, delays = [], []
    def replay(index):
        calls.append(index)
        return 1,result,trajectory
    assert run_attempts(replay,delays.append,lambda _:None)==1
    assert calls == [0,1,2,3]
    assert delays == [300,300,300]
