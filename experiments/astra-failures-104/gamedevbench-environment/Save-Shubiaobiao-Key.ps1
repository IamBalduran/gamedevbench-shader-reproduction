$ErrorActionPreference = 'Stop'
& 'D:\ShaderAgent\shader-lab\.venv\Scripts\python.exe' (Join-Path $PSScriptRoot 'secure_key.py') save
if ($LASTEXITCODE -ne 0) { throw 'Encrypted key was not updated.' }
Write-Host 'The independent benchmark now uses the newly saved local encrypted key.'
Read-Host 'Press Enter to close'
