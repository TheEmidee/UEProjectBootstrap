try {
    Write-Host "Starting project setup..." -ForegroundColor Cyan
    Write-Host "Installing Python..." -ForegroundColor Cyan
    & "$bootstrapPythonFolder/install-python.ps1"
    Write-Host "Creating Python's virtual environment..." -ForegroundColor Cyan
    & "$bootstrapPythonFolder/setup-venv.ps1"
    Write-Host "Installing pre-commit hooks..." -ForegroundColor Cyan
    pre-commit install
    Write-Host "Checking engine installation..." -ForegroundColor Cyan
    & "$pythonScriptsFolder/ue-check-engine-installation.exe"
}
catch {
    Write-Error $_.Exception.Message
}