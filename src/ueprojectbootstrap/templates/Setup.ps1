param (
    [switch]$BuildMachine = $false
)

$ErrorActionPreference = "Stop"

$IsForeignProject = $@isForeignProject@
$PythonVersion = "3.12"
$RequiredPackages = @("UEPyScripts", "GameDevTools", "JenkinsfileGenerator")

$RepositoryRoot = $PSScriptRoot
$PythonFolder = Join-Path -Path $RepositoryRoot -ChildPath "Scripts/Python"
$VenvScriptsFolder = Join-Path -Path $PythonFolder -ChildPath ".venv/Scripts"

function Install-UV {
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        Write-Host "UV is already installed. Skipping..." -ForegroundColor Green
        return
    }

    Write-Host "Installing UV..." -ForegroundColor Cyan
    Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
    $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
}

function Install-Python {
    Write-Host "Installing Python $PythonVersion..." -ForegroundColor Cyan
    uv python install $PythonVersion --upgrade
}

function Initialize-VirtualEnvironment {
    New-Item -ItemType Directory -Force -Path $PythonFolder | Out-Null

    Push-Location $PythonFolder
    try {
        if (-not (Test-Path ".venv")) {
            Write-Host "Creating virtual environment..." -ForegroundColor Cyan
            uv venv --python $PythonVersion
        } else {
            Write-Host "Virtual environment already exists." -ForegroundColor Green
        }

        Write-Host "Installing python packages..." -ForegroundColor Cyan
        uv pip install $RequiredPackages --link-mode=copy --upgrade
    }
    finally {
        Pop-Location
    }
}

function Install-PreCommit {
    if (Get-Command pre-commit -ErrorAction SilentlyContinue) {
        Write-Host "Pre-Commit is already installed." -ForegroundColor Green
    } else {
        Write-Host "Installing Pre-Commit..." -ForegroundColor Cyan
        uv tool install pre-commit --with pre-commit-uv
    }

    Push-Location $RepositoryRoot
    try {
        pre-commit install
    }
    finally {
        Pop-Location
    }
}

try {
    Write-Host "Starting project setup..." -ForegroundColor Cyan

    if ($IsForeignProject) {
        Write-Host "Foreign project..." -ForegroundColor Green
    } else {
        Write-Host "Native project..." -ForegroundColor Green
        Write-Host "Executing Scripts/Setup.bat..." -ForegroundColor Green
        & (Join-Path -Path $RepositoryRoot -ChildPath "Scripts/Setup.bat")
    }

    Install-UV
    Install-Python
    Initialize-VirtualEnvironment

    if ($BuildMachine -eq $false) {
        Write-Host "Installing pre-commit hooks..." -ForegroundColor Cyan
        Install-PreCommit
    } else {
        Write-Host "Skipping pre-commit hooks installation on build machine." -ForegroundColor Yellow
    }

    if ($IsForeignProject) {
        Write-Host "Checking engine installation..." -ForegroundColor Cyan
        & (Join-Path -Path $VenvScriptsFolder -ChildPath "ue-check-engine-installation.exe")
    }
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
