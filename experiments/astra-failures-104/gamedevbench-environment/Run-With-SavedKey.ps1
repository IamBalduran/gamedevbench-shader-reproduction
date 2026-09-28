param(
    [ValidateSet('drop-reasoning-probe', 'stream-probe', 'stored-stream-probe', 'smoke', 'aligned-smoke', 'batch', 'shader-comparison', 'official-failures-comparison', 'official-failures-review')]
    [string]$Task = 'stream-probe',
    [ValidatePattern('^task_\d{4}$')]
    [string]$BenchmarkTask = 'task_0011',
    [string[]]$BatchArgs = @()
)
$ErrorActionPreference = 'Stop'
& 'D:\ShaderAgent\shader-lab\.venv\Scripts\python.exe' (Join-Path $PSScriptRoot 'secure_key.py') run $Task $BenchmarkTask @BatchArgs
