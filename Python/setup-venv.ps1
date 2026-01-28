$configPath = Join-Path -Path $PSScriptRoot -ChildPath "..\config.ps1"

. $configPath

$pythonFolder = Resolve-Path( Join-Path -Path $PSScriptRoot -ChildPath "..\..\Python" )

$requirementsFilePath = Join-Path -Path $PSScriptRoot -ChildPath $PYTHON_REQUIREMENTS_FILE_NAME
$vEnvFolderPath = Join-Path -Path $pythonFolder -ChildPath $PYTHON_VENV_NAME

Write-Host "Setting up Python virtual environment in $vEnvFolderPath" -ForegroundColor Green

# Save current location and move to script root
Push-Location $pythonFolder

try {
    # Check if Python is installed
    try {
        $pythonVersion = python --version 2>&1
        Write-Host "Found Python: $pythonVersion" -ForegroundColor Yellow
    } catch {
        Write-Host "Error: Python is not installed or not in PATH" -ForegroundColor Red
        return # Use return instead of exit to ensure 'finally' runs
    }

    # Check if requirements.txt exists
    if (!(Test-Path $requirementsFilePath)) {
        Write-Host "Warning: $requirementsFilePath not found" -ForegroundColor Yellow
        exit 1
    }

    # Function to get file hash
    function Get-FileHashString {
        param([string]$FilePath)
        if (Test-Path $FilePath) {
            $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
            return $hash.Hash
        }
        return $null
    }

    # Hash tracking file
    $hashFile = Join-Path -Path $vEnvFolderPath -ChildPath "requirements_hash"

    # Get current hash of pyproject.toml
    $currentHash = Get-FileHashString -FilePath $requirementsFilePath

    # Get stored hash if it exists
    $storedHash = $null
    if (Test-Path $hashFile) {
        $storedHash = Get-Content $hashFile -Raw
    }

    # Check if requirements have changed
    $requirementsChanged = ($currentHash -ne $storedHash) -or $Force

    # Create virtual environment if it doesn't exist
    if (!(Test-Path $PYTHON_VENV_NAME)) {
        Write-Host "Creating virtual environment '$PYTHON_VENV_NAME'..." -ForegroundColor Yellow
        python -m venv $PYTHON_VENV_NAME
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to create virtual environment" -ForegroundColor Red
            return
        }
        Write-Host "Virtual environment created successfully!" -ForegroundColor Green
        $requirementsChanged = $true  # Force install on new venv
    } else {
        Write-Host "Virtual environment '$PYTHON_VENV_NAME' already exists" -ForegroundColor Yellow
    }

    # Activate virtual environment
    Write-Host "Activating virtual environment..." -ForegroundColor Yellow
    & ".\$PYTHON_VENV_NAME\Scripts\Activate.ps1"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to activate virtual environment" -ForegroundColor Red
        return
    }

    # Upgrade pip
    Write-Host "Upgrading pip..." -ForegroundColor Yellow
    python -m pip install --upgrade pip

    # Install requirements only if they changed
    if (Test-Path $vEnvFolderPath) {
        if ($requirementsChanged) {
            Write-Host "Requirements have changed. Installing packages from $requirementsFilePath..." -ForegroundColor Yellow
            pip install -r $requirementsFilePath --upgrade
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "All packages installed successfully!" -ForegroundColor Green
                # Store the new hash
                $currentHash | Out-File -FilePath $hashFile -NoNewline
            } else {
                Write-Host "Error: Some packages failed to install" -ForegroundColor Red
            }
        } else {
            Write-Host "Requirements unchanged - skipping package installation" -ForegroundColor Cyan
        }
    } else {
        Write-Host "Skipping package installation - no requirements file found" -ForegroundColor Yellow
    }

    Write-Host "`nSetup complete!" -ForegroundColor Green
    Write-Host "Virtual environment is now active." -ForegroundColor Green

} finally {
    # This block runs no matter what happens in the 'try' block
    Pop-Location
    Write-Host "`nReturned to original directory." -ForegroundColor Gray
}