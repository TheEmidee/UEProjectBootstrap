$ErrorActionPreference = "Stop"

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host "Installing UV..." -ForegroundColor Cyan
    Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
    $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
} else {
    Write-Host "UV is already installed." -ForegroundColor Green
}

Write-Host "Syncing environment with uv..." -ForegroundColor Cyan
uv sync

Write-Host "`nEnvironment ready. Run the tool with: uv run ueprojectbootstrap <path-to-uproject>" -ForegroundColor Green
