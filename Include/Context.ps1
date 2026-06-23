class Context {
    [string] $AbsoluteBootstrapScriptsFolder
    [string] $RelativeBootstrapScriptsFolder
    [string] $ProjectRoot
    [string] $ProjectName
    [string] $ProjectConfigFolder
    [string] $ProjectScriptsFolder
    [string] $ProjectScriptsPythonFolder
    [string] $RelativeProjectScriptsPythonAliasFolder

    Context() {
        $this.SetProjectRoot()
        
        $BoostrapRootDirectory = ( Get-Item -Path $PSScriptRoot ).Parent
        $this.AbsoluteBootstrapScriptsFolder = Join-Path -Path $BoostrapRootDirectory -ChildPath "Scripts"
        $this.RelativeBootstrapScriptsFolder = $this.GetRelativePath( $this.AbsoluteBootstrapScriptsFolder )        
        $this.ProjectConfigFolder = Convert-Path ( Join-Path -Path $this.ProjectRoot -ChildPath "Config" )

        $this.ProjectScriptsFolder = Convert-Path ( Join-Path -Path $this.ProjectRoot -ChildPath "Scripts" )
        $this.ProjectScriptsPythonFolder = Convert-Path ( Join-Path -Path $this.ProjectScriptsFolder -ChildPath "Python" )
        $relativeProjectScriptsPythonFolder = $this.GetRelativePath( $this.ProjectScriptsPythonFolder )
        $this.RelativeProjectScriptsPythonAliasFolder = Convert-Path ( Join-Path -Path $relativeProjectScriptsPythonFolder -ChildPath ".venv/Scripts" )
    }

    [void] SetProjectRoot() {
        $currentDir = Get-Item -Path $PSScriptRoot

        while ($currentDir) {
            $uprojectFiles = Get-ChildItem -Path $currentDir -Filter "*.uproject" -File
            if ($uprojectFiles) {
                $this.ProjectRoot = $currentDir
                $this.ProjectName = [System.IO.Path]::GetFileNameWithoutExtension($uprojectFiles[0].Name)
                break
            }
            $parentDir = Split-Path -Parent $currentDir
            if ($parentDir -eq $currentDir) {
                # Reached the root of the filesystem
                break
            }
            $currentDir = $parentDir
        }

        if (-not $this.ProjectRoot) {
            Write-Error "Could not find project root. No .uproject file found in parent directories."
            exit 1
        }

        $this.ProjectRoot = Convert-Path $this.ProjectRoot
    }

    [string] GetRelativePath($path) {
        return Convert-Path( ( $path | Resolve-Path -Relative -RelativeBasePath $this.ProjectRoot ) )
    }

    [void] ReplaceTokensInFile($filePath) {
        (Get-Content $filePath) `
            -replace [regex]::Escape('@projectName@'), $this.ProjectName `
            -replace [regex]::Escape('@bootstrapScriptsFolder@'), $this.RelativeBootstrapScriptsFolder `
            -replace [regex]::Escape('@pythonScriptsFolder@'), $this.RelativeProjectScriptsPythonAliasFolder | 
            Set-Content $filePath
    }
}