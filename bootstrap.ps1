# Get the directory where this script is located
$scriptDir = (Get-Item -Path $PSScriptRoot )

# Walk up the hierarchy to find the project root (directory containing .uproject file)
$projectRoot = $null
$currentDir = $scriptDir

while ($currentDir) {
    $uprojectFiles = Get-ChildItem -Path $currentDir -Filter "*.uproject" -File
    if ($uprojectFiles) {
        $projectRoot = $currentDir
        break
    }
    $parentDir = Split-Path -Parent $currentDir
    if ($parentDir -eq $currentDir) {
        # Reached the root of the filesystem
        break
    }
    $currentDir = $parentDir
}

if (-not $projectRoot) {
    Write-Error "Could not find project root. No .uproject file found in parent directories."
    exit 1
}

function Convert-Path($path) {
    return $path -replace '^\\.\\', '' -replace '\\', '/'
}

function Get-RelativePath($path) {
    return Convert-Path( ( $path | Resolve-Path -Relative -RelativeBasePath $projectRoot ) )
}

function Copy-File($sourceFileName, $destinationFolder, $force) {
    $sourceFile = Join-Path -Path $scriptDir -ChildPath $sourceFileName

    if ( -not ( Test-Path -Path $sourceFile ) ) {
        Write-Host "Source file $sourceFile does not exist." -ForegroundColor Red
        exit 1
    }

    $fileNameOnly = Split-Path -Path $sourceFile -Leaf

    $destinationFile = Join-Path -Path $destinationFolder -ChildPath $fileNameOnly.
    if ($force -eq $false -and ( Test-Path -Path $destinationFile ) ) {
        Write-Host "File $destinationFile already exists. Skipping copy." -ForegroundColor Yellow
        return $False
    }

    New-Item -ItemType Directory -Force -Path $destinationFolder | Out-Null
    Copy-Item -Path $sourceFile -Destination $destinationFile -PassThru -Force | Out-Null
    Write-Host "Copied $sourceFile to $destinationFile" -ForegroundColor Green
    return $True
}

$bootStrapFolder = Get-RelativePath $scriptDir
$bootstrapPythonFolder = Convert-Path ( Join-Path -Path $bootStrapFolder -ChildPath "Python" )

$pythonAbsoluteFolder = Convert-Path ( Join-Path -Path $projectRoot -ChildPath "Scripts/Python" )
if ( -not ( Test-Path -Path $pythonAbsoluteFolder ) ) {
    New-Item -ItemType Directory -Force -Path $pythonAbsoluteFolder | Out-Null
}

$pythonRelativeFolder = Get-RelativePath $pythonAbsoluteFolder
$pythonScriptsFolder = Convert-Path ( Join-Path -Path $pythonRelativeFolder -ChildPath ".venv/Scripts" )

function Setup-PythonFolder {
    
    if (-not (Test-Path -Path $pythonAbsoluteFolder)) {
        Write-Host "`nCreating Python folder at $pythonAbsoluteFolder..." -ForegroundColor Cyan
        New-Item -ItemType Directory -Force -Path $pythonAbsoluteFolder | Out-Null
    } else {
        Write-Host "`nPython folder already exists at $pythonAbsoluteFolder. Skipping creation." -ForegroundColor Yellow
    }

    Copy-File "Python/.gitignore" $pythonAbsoluteFolder $true
}

function Write-SetupFile {
    $setupFilePath = Join-Path -Path $projectRoot -ChildPath "Setup.ps1"

    if ( Copy-File "Files/Setup.ps1" $projectRoot $true ) {
        
        (Get-Content $setupFilePath) `
            -replace [regex]::Escape('$bootstrapPythonFolder'), $bootstrapPythonFolder `
            -replace [regex]::Escape('$pythonScriptsFolder'), $pythonScriptsFolder | 
            Set-Content $setupFilePath
    }
}

function Write-ConfigFile {
    Copy-File "Files/config.ini" "Config/PyScripts" $false
}

function Write-CompileAndRunEditorFile {
    $compileAndRunEditorPath = Join-Path -Path $projectRoot -ChildPath "CompileAndRunEditor.ps1"
        if ( Copy-File "Files/CompileAndRunEditor.ps1" $projectRoot $true ) {        
            (Get-Content $compileAndRunEditorPath) `
                -replace [regex]::Escape('$pythonScriptsFolder'), $pythonScriptsFolder | 
                Set-Content $compileAndRunEditorPath
    }
}

function Write-BuildgraphFile {
    $buildGraphScriptDirPath = Join-Path -Path $projectRoot -ChildPath "Scripts/Project"
    if (-not (Test-Path -Path $buildGraphScriptDirPath)) {
        $executeConfirmation = Read-Host "`nDo you want to create a Buildgraph script example? (Y/N)"
        
        if ($executeConfirmation -eq 'Y' -or $executeConfirmation -eq 'y') {        
            $executeConfirmation = Read-Host "`nDo you want to create a script example about how to run a buildgraph task? (Y/N)"
            $buildGraphScriptPath = Join-Path -Path $buildGraphScriptDirPath -ChildPath "BuildgraphTask.ps1"

            New-Item -ItemType Directory -Force -Path $buildGraphScriptDirPath

            $bootStrapFolder = [System.IO.Path]::GetRelativePath($buildGraphScriptDirPath, $scriptDir)
            $bootStrapFolder = Convert-Path $bootStrapFolder

            $buildgraphSampleContent = @"
& "$pythonScriptsFolder/ue-run-buildgraph.exe" --target "Buildgraph Task Name" -set:Clean=True -set:Targets=MyGameClient+MyGameServer -set:TargetConfigurations=Development+Shipping
"@

        Set-Content -Path $buildGraphScriptPath -Value $buildgraphSampleContent -Encoding UTF8
        Write-Host "`BuildgraphTask.ps1 has been successfully created!" -ForegroundColor Green
        Write-Host "Location: $buildGraphScriptPath" -ForegroundColor Green
        }
    } else {
        Write-Host "`nBuildgraph script directory already exists at $buildGraphScriptDirPath. Skipping creation." -ForegroundColor Yellow
    }
}

function Write-PreCommitConfig {
    Copy-File "Files/.pre-commit-config.yaml" $projectRoot $true
}

function Invoke-Setup {
    $executeConfirmation = Read-Host "`nDo you want to execute Setup.ps1 now? (Y/N)"
    if ($executeConfirmation -eq 'Y' -or $executeConfirmation -eq 'y') {
        Write-Host "`nExecuting Setup.ps1..." -ForegroundColor Cyan
        try {
            $setupFile = Join-Path -Path $projectRoot -ChildPath "Setup.ps1"
            & $setupFile
        }
        catch {
            Write-Error "Failed to execute Setup.ps1: $_"
            exit 1
        }
    }
    else {
        Write-Host "Setup.ps1 was not executed. You can run it manually later." -ForegroundColor Yellow
    }
}

Setup-PythonFolder
Write-SetupFile
Write-ConfigFile
Write-CompileAndRunEditorFile
Write-BuildgraphFile
Write-PreCommitConfig
Invoke-Setup