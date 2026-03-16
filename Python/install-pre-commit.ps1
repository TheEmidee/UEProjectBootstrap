$configPath = Join-Path -Path $PSScriptRoot -ChildPath "..\config.ps1"

. $configPath

function Install-PreCommit
{
    # Check if 'pre-commit' is available in the path
    if (Get-Command pre-commit -ErrorAction SilentlyContinue) {
        Write-Host "✓ Pre-Commit is already installed." -ForegroundColor Green
    } else {
        Write-Host "Installing Pre-Commit..." -ForegroundColor Cyan
        uv tool install pre-commit --with pre-commit-uv
    }

    pre-commit install
}

Install-PreCommit