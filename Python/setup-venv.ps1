$configPath = Join-Path -Path $PSScriptRoot -ChildPath "..\config.ps1"

. $configPath

$pythonFolder = Resolve-Path( Join-Path -Path $PSScriptRoot -ChildPath "..\..\Python" )
$requirementsFilePath = Join-Path -Path $PSScriptRoot -ChildPath $PYTHON_REQUIREMENTS_FILE_NAME
$additionalrequirementsFilePath = Join-Path -Path $pythonFolder -ChildPath $PYTHON_REQUIREMENTS_FILE_NAME
$vEnvFolderPath = Join-Path -Path $pythonFolder -ChildPath $PYTHON_VENV_NAME

Write-Host "Setting up Python virtual environment in $vEnvFolderPath" -ForegroundColor Green

Push-Location $pythonFolder

try {
    # 1. Only create the venv if the directory doesn't exist
    if (-not (Test-Path ".venv")) {
        Write-Host "Creating virtual environment..." -ForegroundColor Cyan
        uv venv --python $PYTHON_VERSION
    } else {
        Write-Host "✓ Virtual environment already exists." -ForegroundColor Green
    }

    $pipArgs = @("-r", $requirementsFilePath)

    if (Test-Path $additionalrequirementsFilePath) {
        $pipArgs += "-r"
        $pipArgs += $additionalrequirementsFilePath
        Write-Host "Found additional requirements at: $additionalrequirementsFilePath" -ForegroundColor Cyan
    }

    uv pip install @pipArgs --link-mode=copy

    Write-Host "`nSetup complete! Virtual environment is now active" -ForegroundColor Green

} finally {
    Pop-Location
}