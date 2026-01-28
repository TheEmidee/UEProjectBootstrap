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

function Sanitize-Path($path) {
    return $path -replace '^\\.\\', '' -replace '\\', '/'
}

function Get-RelativePath($path) {
    return Sanitize-Path( ( $path | Resolve-Path -Relative -RelativeBasePath $projectRoot ) )
}

$bootStrapFolder = Get-RelativePath $scriptDir
$bootstrapPythonFolder = Sanitize-Path ( Join-Path -Path $bootStrapFolder -ChildPath "Python" )
$pythonAbsoluteFolder = Sanitize-Path ( Join-Path -Path $projectRoot -ChildPath "Scripts/Python" )

$pythonRelativeFolder = Get-RelativePath $pythonAbsoluteFolder
$pythonScriptsFolder = Sanitize-Path ( Join-Path -Path $pythonRelativeFolder -ChildPath ".venv/Scripts" )

function Copy-PythonFile($fileName) {
    $sourcePath = Join-Path -Path $scriptDir -ChildPath "Python/$fileName"
    $destinationPath = Join-Path -Path $pythonAbsoluteFolder -ChildPath $fileName

    if (Test-Path -Path $sourcePath) {
        if (-not (Test-Path -Path $destinationPath)) {
            Copy-Item -Path $sourcePath -Destination $destinationPath -Force
            Write-Host "Copied $fileName to $destinationPath" -ForegroundColor Green
        } else {
            Write-Host "File $fileName already exists at $destinationPath. Skipping copy." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Source file $sourcePath does not exist. Skipping copy." -ForegroundColor Yellow
    }
}

function Setup-PythonFolder {
    
    if (-not (Test-Path -Path $pythonAbsoluteFolder)) {
        Write-Host "`nCreating Python folder at $pythonAbsoluteFolder..." -ForegroundColor Cyan
        New-Item -ItemType Directory -Force -Path $pythonAbsoluteFolder | Out-Null
    } else {
        Write-Host "`nPython folder already exists at $pythonAbsoluteFolder. Skipping creation." -ForegroundColor Yellow
    }

    Copy-PythonFile ".gitignore"
}

function Write-SetupFile {
    # Define the output file path
    $outputFile = Join-Path -Path $projectRoot -ChildPath "Setup.ps1"

    if ( -not ( Test-Path -Path $outputFile ) ) {
        $setupContent = @"
    try {
        & "$bootstrapPythonFolder/install-python.ps1"
        & "$bootstrapPythonFolder/setup-venv.ps1"
        & "$pythonScriptsFolder/ue-check-engine-installation.exe"
    }
    catch {
        Write-Error `$_.Exception.Message
    }
"@

        Write-Host "`nSetup.ps1 will be created at:" -ForegroundColor Cyan
        Write-Host $outputFile -ForegroundColor Yellow
        Write-Host "`nWith the following content:" -ForegroundColor Cyan
        Write-Host $setupContent -ForegroundColor Gray

        $confirmation = Read-Host "`nDo you want to proceed? (Y/N)"
        if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            return
        }

        # Write the file
        try {
            Set-Content -Path $outputFile -Value $setupContent -Encoding UTF8
            Write-Host "`nSetup.ps1 has been successfully created!" -ForegroundColor Green
            Write-Host "Location: $outputFile" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to create Setup.ps1: $_"
            exit 1
        }
    } else {
        Write-Host "`nSetup.ps1 already exists at $outputFile. Skipping creation." -ForegroundColor Yellow
    }
}

function Write-ConfigFile {
    $configFilePath = Join-Path -Path $projectRoot -ChildPath "Config/PyScripts/config.ini"
    if (-not (Test-Path -Path $configFilePath)) {
        Write-Host "`nConfig file not found at $configFilePath. Creating a default config.ini..." -ForegroundColor Cyan
        $defaultConfigContent = @"
[Project]
; BuildgraphPath = Scripts\Build\BuildGraph\BuildGraph.xml
; BuildgraphSharedProperties = Publish_Directory=Saved/LocalBuilds
; AutomationScriptsDirectories = Build/Scripts+Plugins/BuildInformation/Scripts/Automation

[Jenkins]
; BuildgraphSharedStoragePath = \\nas\jenkins\UE-BuildGraph
"@

        Set-Content -Path $configFilePath -Value $defaultConfigContent -Encoding UTF8
        Write-Host "`nconfig.ini has been successfully created!" -ForegroundColor Green
        Write-Host "Location: $configFilePath" -ForegroundColor Green
    }
    else {
        Write-Host "`nConfig file already exists at $configFilePath. Skipping creation." -ForegroundColor Yellow
    }
}

function Write-CompileAndRunEditorFile {
    $compileAndRunEditorPath = Join-Path -Path $projectRoot -ChildPath "CompileAndRunEditor.ps1"

    if (-not (Test-Path -Path $compileAndRunEditorPath)) {
        $executeConfirmation = Read-Host "`nDo you want to create the CompileAndRunEditor.ps1 file? (Y/N)"
        if ($executeConfirmation -eq 'Y' -or $executeConfirmation -eq 'y') {
            
            $compileAndRunEditorContent = @"
try {
    & "$pythonScriptsFolder/ue-close-editor.exe"
    & "$pythonScriptsFolder/ue-compile-editor.exe"
    & "$pythonScriptsFolder/ue-run-editor.exe"
}
catch {
    Write-Error `$_.Exception.Message
}
"@

            Set-Content -Path $compileAndRunEditorPath -Value $compileAndRunEditorContent -Encoding UTF8
            Write-Host "`nCompileAndRunEditor.ps1 has been successfully created!" -ForegroundColor Green
            Write-Host "Location: $compileAndRunEditorPath" -ForegroundColor Green
        }
    } else {
        Write-Host "`nCompileAndRunEditor.ps1 already exists at $compileAndRunEditorPath. Skipping creation." -ForegroundColor Yellow
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
            $bootStrapFolder = $bootStrapFolder -replace '^\\.\\', '' -replace '\\', '/'

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
Invoke-Setup