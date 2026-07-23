param (
    [switch]$BuildMachine = $false
 )


$IsForeignProject = $@isForeignProject@

try {
    Write-Host "Starting project setup..." -ForegroundColor Cyan
    
    if ($IsForeignProject) {
        Write-Host "Foreign project..." -ForegroundColor Green
    } else {
        Write-Host "Native project..." -ForegroundColor Green
        Write-Host "Execute Setup.bat" -ForegroundColor Green

        & "./Scripts/Setup.bat"
    }

    Write-Host "Installing Python..." -ForegroundColor Cyan
    & "@bootstrapScriptsFolder@/Python/install-python.ps1"
    Write-Host "Creating Python's virtual environment..." -ForegroundColor Cyan
    & "@bootstrapScriptsFolder@/Python/setup-venv.ps1"

    if ($BuildMachine -eq $false) {
        Write-Host "Installing pre-commit hooks..." -ForegroundColor Cyan
        & "@bootstrapScriptsFolder@/Python/install-pre-commit.ps1"

        Write-Host "Running python setup scripts..." -ForegroundColor Cyan
        & "@bootstrapScriptsFolder@/Python/run-setup-scripts.ps1"
    } else {
        Write-Host "Skipping pre-commit hooks installation and setup scripts execution on build machine." -ForegroundColor Yellow
    }

    if ($IsForeignProject -eq $true ) {
        Write-Host "Checking engine installation..." -ForegroundColor Cyan
        & "@pythonScriptsFolder@/ue-check-engine-installation.exe"
    }
}
catch {
    Write-Error $_.Exception.Message
}