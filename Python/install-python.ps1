$configPath = Join-Path -Path $PSScriptRoot -ChildPath "..\config.ps1"

. $configPath

function Install-UV
{
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        Write-Host "UV is already installed. Skipping..." -ForegroundColor Green
        return
    }

    Write-Host "Installing UV..." -ForegroundColor Cyan
    Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
    $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
}

function Install-Python
{
    Write-Host "Installing Python $PYTHON_VERSION..." -ForegroundColor Cyan
    uv python install $PYTHON_VERSION --upgrade
}

Install-UV
Install-Python