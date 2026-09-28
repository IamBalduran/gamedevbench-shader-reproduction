param(
    [ValidateRange(1, 16)] [int]$Parallel = 2,
    [ValidateRange(0, 104)] [int]$MaxTasks = 0,
    [switch]$Status,
    [switch]$Stop,
    [switch]$InitOnly,
    [switch]$ReviewOnly
)
$ErrorActionPreference = 'Stop'
$slashPath = $PSScriptRoot.Replace('\', '/')
if ($slashPath -notmatch '^([A-Za-z]):/(.+)$') { throw 'Experiment must be on a WSL-mounted Windows drive.' }
$wslRoot = '/mnt/' + $Matches[1].ToLowerInvariant() + '/' + $Matches[2]
$wslParent = ($wslRoot -replace '/gamedevbench-environment$', '')
$python = "$wslParent/gamedevbench-main/gamedevbench-main/.venv/bin/python"
$script = "$wslRoot/run_official_failures_comparison.py"
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
Write-Host 'Windows idle sleep is blocked while the experiment runs; the display may turn off. Normal sleep behavior is restored afterward.'
$completed = $false
try {
    $batchArgs = @('--parallel', [string]$Parallel)
    if ($MaxTasks -gt 0) { $batchArgs += @('--max-tasks', [string]$MaxTasks) }
    if ($ReviewOnly) { $batchArgs += '--review-only' }
    & (Join-Path $PSScriptRoot 'Run-With-SavedKey.ps1') -Task official-failures-comparison -BatchArgs $batchArgs
    $runExitCode = $LASTEXITCODE
    $completed = $true
} finally {
    try {
        if (-not $completed) { & wsl.exe -d Ubuntu -- $python $script --stop }
    } finally {
        [void][GameDevBenchPowerGuard]::SetThreadExecutionState($releaseRequest)
    }
}
exit $runExitCode
