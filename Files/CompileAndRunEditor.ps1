$commands = @(
    "$pythonScriptsFolder/ue-close-editor.exe",
    "$pythonScriptsFolder/ue-compile-editor.exe",
    "$pythonScriptsFolder/ue-run-editor.exe"
)

foreach ($cmd in $commands) {
    & $cmd
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n[!] Error: Command failed with exit code $LASTEXITCODE" -ForegroundColor Red
        Write-Host "Press any key to close this window..."
        $null = [System.Console]::ReadKey($true)
        exit $LASTEXITCODE
    }
}