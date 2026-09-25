param(
    [ValidateRange(1, 16)] [int]$Parallel = 2,
    [switch]$Status,
    [switch]$Stop,
    [switch]$InitOnly
)
$ErrorActionPreference = 'Stop'
$envRoot = Join-Path $PSScriptRoot 'gamedevbench-environment'
$repo = Join-Path $PSScriptRoot 'gamedevbench-main\gamedevbench-main'
$wslRepo = (& wsl.exe -d Ubuntu -- wslpath -a $repo).Trim()
$wslEnv = (& wsl.exe -d Ubuntu -- wslpath -a $envRoot).Trim()
$python = "$wslRepo/.venv/bin/python"
$script = "$wslEnv/run_shader_comparison.py"
if ($Status -or $Stop -or $InitOnly) {
    $action = if ($Status) { '--status' } elseif ($Stop) { '--stop' } else { '--init-only' }
    & wsl.exe -d Ubuntu -- $python $script $action
    exit $LASTEXITCODE
}
$powerType = 'GameDevBenchPowerGuard' -as [type]
if (-not $powerType) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class GameDevBenchPowerGuard {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint SetThreadExecutionState(uint flags);
}
'@
}
$keepSystemAwake = [uint32]2147483649
$releaseRequest = [uint32]2147483648
if ([GameDevBenchPowerGuard]::SetThreadExecutionState($keepSystemAwake) -eq 0) {
    throw 'Could not prevent Windows idle sleep; experiment was not started.'
}
try {
    & python (Join-Path $envRoot 'secure_key.py') run shader-comparison task_0011 --parallel ([string]$Parallel)
    $runExitCode = $LASTEXITCODE
} finally {
    [void][GameDevBenchPowerGuard]::SetThreadExecutionState($releaseRequest)
}
exit $runExitCode
