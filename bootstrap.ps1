$scriptDir = (Get-Item -Path $PSScriptRoot )

. "$scriptDir/Include/HelperFunctions.ps1"
. "$scriptDir/Include/Context.ps1"

$ctx = [Context]::new()

function Initialize-PythonFolder {
    
    if (-not (Test-Path -Path $ctx.ScriptsPythonFolder)) {
        Write-Host "`nCreating Python folder at $($ctx.ScriptsPythonFolder)..." -ForegroundColor Cyan
        New-Item -ItemType Directory -Force -Path $ctx.ScriptsPythonFolder | Out-Null
    } else {
        Write-Host "`nPython folder already exists at $($ctx.ScriptsPythonFolder). Skipping creation." -ForegroundColor Yellow
    }

    [void](Copy-File "Scripts/Python/.gitignore" $ctx.ScriptsPythonFolder $true)
}

function Write-SetupFile {
    $setupFilePath = Join-Path -Path $ctx.RepositoryRoot -ChildPath "Setup.ps1"
    if ( Copy-File "Files/Setup.ps1" $ctx.RepositoryRoot $true ) {
        $ctx.ReplaceTokensInFile($setupFilePath)
    }
}

function Write-ConfigFile {
    $configFilePath = Join-Path -Path $ctx.ProjectRoot -ChildPath "Config/PyScripts/config.ini"
    if ( Copy-File "Files/config.ini" ( Join-Path -Path $ctx.ProjectConfigFolder -ChildPath "PyScripts" ) $false ) {
        $ctx.ReplaceTokensInFile($configFilePath)
    }
}

function Write-CompileAndRunEditorFile {
    $compileAndRunEditorPath = Join-Path -Path $ctx.RepositoryRoot -ChildPath "CompileAndRunEditor.ps1"
    if ( Copy-File "Files/CompileAndRunEditor.ps1" $ctx.RepositoryRoot $true ) {
        $ctx.ReplaceTokensInFile($compileAndRunEditorPath)
    }
}

function Copy-GenerateVSSolution {
    [void]( Copy-File "Files/GenerateVSSolution.ps1" $ctx.ProjectRoot  $false )
}

function Install-AutomationScripts {
    $submodulePath = Join-Path -Path $ctx.ProjectRoot -ChildPath "Scripts/Automation"

    if ( -not( Test-Path $submodulePath ) ) {
        Write-Host "Submodule '$submodulePath' is NOT installed" -ForeroundColor Yellow

        Push-Location $ctx.ProjectRoot
        git submodule add git@github.com:TheEmidee/UEAutomationScripts.git "Scripts/Automation"
        Pop-Location
    }
    
    Write-Host "Submodule '$submodulePath' is installed" -Foreground Green
}

function Copy-BuildgraphFiles {
    Copy-Folder "Files/BuildGraph" ( Join-Path -Path $ctx.ProjectRoot -ChildPath "Scripts/Build/BuildGraph" ) $true
}

function Copy-JenkinsFiles {
    $destinationFolder = Join-Path -Path $ctx.ProjectRoot -ChildPath "Scripts/Build/Jenkins"
    if ( Copy-Folder "Files/Jenkins" $destinationFolder $true ) {
        $configFolder = Join-Path -Path $destinationFolder -ChildPath "config"

        Get-ChildItem -Path $configFolder -Filter "jenkinsfile_*" -File | ForEach-Object {
            $ctx.ReplaceTokensInFile($_.FullName)
        }
    }
}

function Write-BuildgraphTaskFile {
    $buildGraphScriptDirPath = Join-Path -Path $ctx.ProjectRoot -ChildPath "Scripts/Project"
    if (-not (Test-Path -Path $buildGraphScriptDirPath)) {
        New-Item -ItemType Directory -Force -Path $buildGraphScriptDirPath
    }

    $buildGraphTaskPath = Join-Path -Path $buildGraphScriptDirPath -ChildPath "BuildgraphTask.ps1"

    if ( Copy-File "Files/BuildGraphTask.ps1" $buildGraphScriptDirPath $false ) {
        # TODO : ReplaceTokensInFile will use the relative path to Scripts/Python/.venv/Scripts/ from the project root
        # We need the relative path from Scripts/Project, which would be ../../Scripts/Python/.venv/Scripts/
        $ctx.ReplaceTokensInFile($buildGraphTaskPath)
        Write-Host "$buildGraphTaskPath has been successfully created!" -ForegroundColor Green
    } else {
        Write-Host "$buildGraphTaskPath already exists. Skipping creation." -ForegroundColor Yellow
    }
}

function Write-PreCommitConfig {
    [void](Copy-File "Files/.pre-commit-config.yaml" $ctx.RepositoryRoot $true)
}

function Install-Python {
    Write-Host "Installing Python..." -ForegroundColor Cyan
    & "$($ctx.AbsoluteBootstrapScriptsFolder)/Python/install-python.ps1"

    Write-Host "Setup Python virtual environment..." -ForegroundColor Cyan
    & "$($ctx.AbsoluteBootstrapScriptsFolder)/Python/setup-venv.ps1"
}

function Invoke-Setup {
    Write-Host "`nExecuting Setup.ps1..." -ForegroundColor Cyan
    try {
        Push-Location $ctx.RepositoryRoot
        & "./Setup.ps1"
    }
    catch {
        Write-Error "Failed to execute Setup.ps1: $_"
        exit 1
    }
    finally {
        Pop-Location
    }
}

function Invoke-PythonBootstrapScripts {
    Write-Host "Execute python bootstrap scripts..." -ForegroundColor Cyan
    & "$($ctx.AbsoluteBootstrapScriptsFolder)/Python/run-bootstrap-scripts.ps1"
}

Initialize-PythonFolder
Write-SetupFile
Write-ConfigFile
Write-CompileAndRunEditorFile

if ($ctx.IsForeignProject) {
    Copy-GenerateVSSolution
}
Write-PreCommitConfig

Install-Python

# TODO
# Install-AutomationScripts
# Copy-BuildgraphFiles
# Copy-JenkinsFiles
# Write-BuildgraphTaskFile

Invoke-PythonBootstrapScripts

$Message = @"
The setup of the project is done.
Things you can do now:
* Add custom python scripts in the folder Scripts/Python/.bootstrap to execute custom actions as part of the bootstrap process. 
  It is safe to execute bootstrap.ps1 multiple times in a row, the script won't override existing files.
  Some examples of what you can do in these custom bootstrap scripts:
  * Add plugins you commonly use to the project
* Update the config file in Config/PyScripts/config.ini
  * Add automation scripts to AutomationScriptsDirectories
  * Add Buildgraph shared properties
  * Define the buildgraph shared storage path in BuildgraphSharedProperties
* Update the config files in Scripts/Build/Jenkins/config
  * You can read the documentation here: https://github.com/TheEmidee/JenkinsFileGenerator
* Generate the jenkinsfiles by executing the script GenerateJenkinsfiles.ps1 in the Scripts/Build/Jenkins folder.
* Update the file Scripts/Build/BuildGraph/BuildGraph.xml with your project values and your own tasks
* Create custom powershell scripts in the folder Scripts/Project to easily execute your buildgraph tasks
* Add custom python scripts in the folder Scripts/Python/.setup to execute custom actions when someone executes Setup.ps1. For example you can:
  * Update BuildConfiguration.xml
  * Register the machine to a Horde Server
"@
Write-ImportantMessage $Message

$answer = Read-Host "Would you like to execute Setup.ps1 now? (Y/N)"

if ( $answer -eq "Y" -or $answer -eq "y" ) {
    Invoke-Setup
} else {
    Write-Host "You can execute Setup.ps1 later by running it from the project root folder." -ForegroundColor Yellow
}