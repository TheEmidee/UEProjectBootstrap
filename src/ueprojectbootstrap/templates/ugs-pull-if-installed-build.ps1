$ErrorActionPreference = "Stop"

$RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$MarkerPath = Join-Path -Path $RepositoryRoot -ChildPath "Engine/Build/InstalledBuild.txt"

if (-not (Test-Path $MarkerPath)) {
    exit 0
}

& (Join-Path -Path $RepositoryRoot -ChildPath "Scripts/Python/.venv/Scripts/ue-ugs-pull.exe")
exit $LASTEXITCODE
