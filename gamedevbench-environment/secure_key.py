"""Windows DPAPI credential storage and WSL launcher. Never print the key."""
import ctypes
import getpass
import os
import re
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parent
KEY_FILE = Path(os.environ.get('GAMEDEVBENCH_KEY_FILE', ROOT / 'shubiaobiao-key.dpapi'))

def wslpath(path: Path) -> str:
    return subprocess.check_output(['wsl.exe', '-d', 'Ubuntu', '--', 'wslpath', '-a', str(path)], text=True).strip()

class Blob(ctypes.Structure):
    _fields_ = [('size', ctypes.c_ulong), ('data', ctypes.POINTER(ctypes.c_ubyte))]

def _dpapi(value: bytes, decrypt: bool) -> bytes:
    source = ctypes.create_string_buffer(value)
    source_blob = Blob(len(value), ctypes.cast(source, ctypes.POINTER(ctypes.c_ubyte)))
    result = Blob()
    crypt32 = ctypes.WinDLL('crypt32', use_last_error=True)
    method = crypt32.CryptUnprotectData if decrypt else crypt32.CryptProtectData
    method.argtypes = [ctypes.POINTER(Blob), ctypes.c_void_p, ctypes.c_void_p,
                       ctypes.c_void_p, ctypes.c_void_p, ctypes.c_ulong, ctypes.POINTER(Blob)]
    method.restype = ctypes.c_int
    if not method(ctypes.byref(source_blob), None, None, None, None, 1, ctypes.byref(result)):
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        return ctypes.string_at(result.data, result.size)
    finally:
        kernel32 = ctypes.WinDLL('kernel32', use_last_error=True)
        kernel32.LocalFree.argtypes = [ctypes.c_void_p]
        kernel32.LocalFree(ctypes.cast(result.data, ctypes.c_void_p))

def save() -> None:
    key = getpass.getpass('Shubiaobiao API Key (hidden): ').strip()
    if not key:
        raise ValueError('No key entered')
    ciphertext = _dpapi(key.encode(), False)
    temp = KEY_FILE.with_suffix('.tmp')
    temp.write_bytes(ciphertext)
    temp.replace(KEY_FILE)
    key = ''
    print('Encrypted key saved for your Windows account.')

def run(task: str, benchmark_task: str = 'task_0011') -> None:
    if not KEY_FILE.is_file():
        raise FileNotFoundError('Encrypted key file missing; run save first')
    key = _dpapi(KEY_FILE.read_bytes(), True).decode()
    env = os.environ.copy()
    env['OPENAI_API_KEY'] = key
    existing = [x for x in env.get('WSLENV', '').split(':')
                if x and not x.startswith('OPENAI_API_KEY')]
    env['WSLENV'] = ':'.join(existing + ['OPENAI_API_KEY/u'])
    script = {'drop-reasoning-probe': 'probe_drop_reasoning.py',
              'stream-probe': 'probe_streaming_roundtrip.py',
              'stored-stream-probe': 'probe_streaming_roundtrip.py',
              'smoke': 'run_gpt6_smoke.py',
              'aligned-smoke': 'run_gpt6_smoke.py',
              'batch': 'run_batch.py',
              'shader-comparison': 'run_shader_comparison.py'}[task]
    repo = ROOT.parent / 'gamedevbench-main' / 'gamedevbench-main'
    command = ['wsl.exe', '-d', 'Ubuntu', '--',
               wslpath(repo) + '/.venv/bin/python', wslpath(ROOT / script)]
    if task == 'stored-stream-probe':
        command.append('--store')
    if task == 'aligned-smoke':
        if not re.fullmatch(r'task_\d{4}', benchmark_task):
            raise ValueError('Invalid benchmark task name')
        command.extend(['--aligned', benchmark_task])
    if task in ('batch', 'shader-comparison'):
        command.extend(sys.argv[4:])
    key = ''
    try:
        code = subprocess.call(command, env=env)
    except KeyboardInterrupt:
        if task in ('batch', 'shader-comparison'):
            arguments = sys.argv[4:]
            stop_command = ['wsl.exe', '-d', 'Ubuntu', '--',
                            wslpath(repo) + '/.venv/bin/python']
            if task == 'batch':
                batch_id = arguments[arguments.index('--batch-id') + 1] if '--batch-id' in arguments else 'gpt6_astra_shader'
                stop_command += [wslpath(ROOT / 'run_batch.py'),
                                 '--batch-id', batch_id, '--stop']
            else:
                stop_command += [wslpath(ROOT / 'run_shader_comparison.py'), '--stop']
            subprocess.run(stop_command, env=os.environ.copy(), timeout=45, check=False)
        raise SystemExit(130)
    raise SystemExit(code)

if __name__ == '__main__':
    try:
        if sys.argv[1:] == ['save']:
            save()
        elif len(sys.argv) >= 3 and sys.argv[1] == 'run':
            run(sys.argv[2], sys.argv[3] if len(sys.argv) >= 4 else 'task_0011')
        else:
            raise ValueError('Usage: secure_key.py save | run stream-probe | run smoke')
    except Exception as exc:
        print('Credential operation failed:', type(exc).__name__, str(exc), file=sys.stderr)
        raise SystemExit(1)
