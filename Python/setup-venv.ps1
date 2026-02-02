$configPath = Join-Path -Path $PSScriptRoot -ChildPath "..\config.ps1"

. $configPath

$pythonFolder = Resolve-Path( Join-Path -Path $PSScriptRoot -ChildPath "..\..\Python" )
$requirementsFilePath = Join-Path -Path $PSScriptRoot -ChildPath $PYTHON_REQUIREMENTS_FILE_NAME
$vEnvFolderPath = Join-Path -Path $pythonFolder -ChildPath $PYTHON_VENV_NAME

Write-Host "Setting up Python virtual environment in $vEnvFolderPath" -ForegroundColor Green

Push-Location $pythonFolder

try {
    uv python pin $PYTHON_VERSION

    uv venv --python $PYTHON_VERSION --clear
    uv pip install -r $requirementsFilePath --link-mode=copy

    Write-Host "`nSetup complete!" -ForegroundColor Green
    Write-Host "Virtual environment is now active." -ForegroundColor Green

} finally {
    # This block runs no matter what happens in the 'try' block
    Pop-Location
    Write-Host "`nReturned to original directory." -ForegroundColor Gray
}