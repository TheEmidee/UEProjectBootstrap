param (
    [switch]$BuildMachine = $false,
    [switch]$RunPerformanceOptimizations = $false
)

$ErrorActionPreference = "Stop"

$IsForeignProject = $@isForeignProject@
$PythonVersion = "3.12"
$RequiredPackages = @("UEPyScripts", "GameDevTools", "JenkinsfileGenerator")

$RepositoryRoot = $PSScriptRoot
$PythonFolder = Join-Path -Path $RepositoryRoot -ChildPath "Scripts/Python"
$VenvScriptsFolder = Join-Path -Path $PythonFolder -ChildPath ".venv/Scripts"
$CustomSetupScriptsFolder = Join-Path -Path $RepositoryRoot -ChildPath "Scripts/Python/Setup"

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

function Invoke-CustomSetupScripts {
    if (-not (Test-Path $CustomSetupScriptsFolder)) {
        Write-Host "No custom setup scripts found in $CustomSetupScriptsFolder." -ForegroundColor Yellow
        return
    }

    $venvPython = Join-Path -Path $VenvScriptsFolder -ChildPath "python.exe"
    $scripts = Get-ChildItem -Path $CustomSetupScriptsFolder -Filter "*.py" -File | Sort-Object Name

    foreach ($script in $scripts) {
        Write-Host "Running custom setup script $($script.Name)..." -ForegroundColor Cyan
        & $venvPython $script.FullName
        if ($LASTEXITCODE -ne 0) {
            throw "Custom setup script $($script.Name) failed with exit code $LASTEXITCODE"
        }
    }
}

function Test-IsElevated {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Add-DefenderExclusions {
    if (-not (Get-Command Add-MpPreference -ErrorAction SilentlyContinue)) {
        Write-Host "Windows Defender PowerShell module not available. Skipping AV exclusions." -ForegroundColor Yellow
        return
    }

    Write-Host "Adding Windows Defender exclusion for $RepositoryRoot..." -ForegroundColor Cyan
    Add-MpPreference -ExclusionPath $RepositoryRoot
}

function Test-DefenderExclusionApplied {
    # Windows Defender redacts ExclusionPath for non-elevated callers (by design, so
    # malware can't enumerate excluded folders), so this can only be verified when
    # already running elevated. Returns $null for "unknown" rather than $false.
    if (-not (Test-IsElevated)) {
        return $null
    }

    if (-not (Get-Command Get-MpPreference -ErrorAction SilentlyContinue)) {
        return $false
    }

    try {
        $exclusions = (Get-MpPreference -ErrorAction Stop).ExclusionPath
    }
    catch {
        return $null
    }

    return @($exclusions) -contains $RepositoryRoot.TrimEnd('\')
}

function Test-SearchIndexingDisabled {
    $folder = Get-Item -Path $RepositoryRoot -Force -ErrorAction SilentlyContinue
    if (-not $folder) {
        return $false
    }

    return [bool]($folder.Attributes -band [IO.FileAttributes]::NotContentIndexed)
}

function Test-PerformanceOptimizationsApplied {
    $defenderExclusionApplied = Test-DefenderExclusionApplied
    if ($null -eq $defenderExclusionApplied) {
        Write-Host "Windows Defender exclusion state on $RepositoryRoot cannot be verified without administrator privileges." -ForegroundColor Yellow
    } elseif ($defenderExclusionApplied) {
        Write-Host "Windows Defender exclusion is already applied on $RepositoryRoot." -ForegroundColor Green
    } else {
        Write-Host "Windows Defender exclusion is not applied on $RepositoryRoot." -ForegroundColor Yellow
    }

    $searchIndexingDisabled = Test-SearchIndexingDisabled
    if ($searchIndexingDisabled) {
        Write-Host "Search indexing is already disabled on $RepositoryRoot." -ForegroundColor Green
    } else {
        Write-Host "Search indexing is not disabled on $RepositoryRoot." -ForegroundColor Yellow
    }

    # The Defender exclusion state can't be reliably read before elevation, so search
    # indexing - always disabled in the same pass as the Defender exclusion - is used
    # as the proxy signal for "optimizations already applied".
    return $searchIndexingDisabled
}

function Disable-SearchIndexing {
    Write-Host "Disabling Windows Search indexing on $RepositoryRoot..." -ForegroundColor Cyan

    $folders = @(Get-Item -Path $RepositoryRoot -Force)
    $folders += Get-ChildItem -Path $RepositoryRoot -Recurse -Directory -Force -ErrorAction SilentlyContinue

    foreach ($folder in $folders) {
        $folder.Attributes = $folder.Attributes -bor [IO.FileAttributes]::NotContentIndexed
    }
}

function Invoke-PerformanceOptimizations {
    try {
        Add-DefenderExclusions
        Disable-SearchIndexing
    }
    catch {
        Write-Host "Failed to apply performance optimizations: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Request-PerformanceOptimizations {
    if (Test-PerformanceOptimizationsApplied) {
        Write-Host "Performance optimizations are already applied on $RepositoryRoot. Skipping." -ForegroundColor Green
        return
    }

    $response = Read-Host "Apply performance optimizations for compiling/running Unreal Engine (Windows Defender + Search indexing exclusions on '$RepositoryRoot')? This requires administrator privileges. [y/N]"
    if ($response -notmatch '^[Yy]') {
        Write-Host "Skipping performance optimizations." -ForegroundColor Yellow
        return
    }

    if (Test-IsElevated) {
        Invoke-PerformanceOptimizations
        return
    }

    Write-Host "Elevating to apply performance optimizations..." -ForegroundColor Cyan
    try {
        $argumentList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"", "-RunPerformanceOptimizations")
        Start-Process -FilePath "powershell.exe" -ArgumentList $argumentList -Verb RunAs -Wait
    }
    catch {
        Write-Host "Elevation was cancelled or failed. Skipping performance optimizations." -ForegroundColor Yellow
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
        pre-commit install -f
    }
    finally {
        Pop-Location
    }
}

try {
    if ($RunPerformanceOptimizations) {
        Invoke-PerformanceOptimizations
        exit 0
    }

    Write-Host "Starting project setup..." -ForegroundColor Cyan

    if ($BuildMachine -eq $false) {
        Request-PerformanceOptimizations
    }

    if ($IsForeignProject) {
        Write-Host "Foreign project..." -ForegroundColor Green
    } else {
        Write-Host "Native project..." -ForegroundColor Green
        Write-Host "Executing Scripts/UE/Setup.bat..." -ForegroundColor Green
        & (Join-Path -Path $RepositoryRoot -ChildPath "Scripts/UE/Setup.bat")
    }

    Install-UV
    Install-Python
    Initialize-VirtualEnvironment

    Write-Host "Running custom setup scripts..." -ForegroundColor Cyan
    Invoke-CustomSetupScripts

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
