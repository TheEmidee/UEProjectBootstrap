$configPath = Join-Path -Path $PSScriptRoot -ChildPath "..\config.ps1"

. $configPath

$pythonFolder = Resolve-Path( Join-Path -Path $PSScriptRoot -ChildPath "..\..\Python" )

Push-Location $pythonFolder

$hookFolder = Join-Path -Path $pythonFolder -ChildPath ".setup"

if (Test-Path $hookFolder) {
    Get-ChildItem -Path $hookFolder -Filter *.py | Sort-Object Name | ForEach-Object {
        Write-Host "--- Running Hook: $($_.Name) ---" -ForegroundColor Cyan
        uv run $_.FullName
    }
} else {
    Write-Host "No setup hooks found in $hookFolder" -ForegroundColor Yellow
}

Pop-Location