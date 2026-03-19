param (
    [switch]$BuildMachine = $false
 )

try {
    Write-Host "Starting project setup..." -ForegroundColor Cyan
    Write-Host "Installing Python..." -ForegroundColor Cyan
    & "@bootstrapPythonFolder@/install-python.ps1"
    Write-Host "Creating Python's virtual environment..." -ForegroundColor Cyan
    & "@bootstrapPythonFolder@/setup-venv.ps1"

    if ($BuildMachine -eq $false) {
        Write-Host "Installing pre-commit hooks..." -ForegroundColor Cyan
        & "@bootstrapPythonFolder@/install-pre-commit.ps1"

        Write-Host "Running python setup scripts..." -ForegroundColor Cyan
        & "@bootstrapPythonFolder@/run-setup-scripts.ps1"
    } else {
        Write-Host "Skipping pre-commit hooks installation and setup scripts execution on build machine." -ForegroundColor Yellow
    }

    Write-Host "Checking engine installation..." -ForegroundColor Cyan
    & "@pythonScriptsFolder@/ue-check-engine-installation.exe"
}
catch {
    Write-Error $_.Exception.Message
}