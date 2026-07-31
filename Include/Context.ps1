class Context {
    [string] $AbsoluteBootstrapScriptsFolder
    [string] $RelativeBootstrapScriptsFolder
    [string] $RepositoryRoot
    [string] $ProjectRoot
    [string] $ProjectName
    [string] $ProjectConfigFolder
    [string] $ScriptsPythonFolder
    [string] $RelativeProjectScriptsPythonAliasFolder
    [bool] $IsForeignProject

    Context($ProjectFile) {
        $this.ProjectName = $ProjectFile.Basename
        $this.ProjectRoot = $ProjectFile.DirectoryName

        if (Test-Path -Path (Join-Path -Path $this.ProjectRoot -ChildPath "../Engine/Build/Build.version" ) ) {
            $this.IsForeignProject = $false
            $this.RepositoryRoot = Resolve-Path( Convert-Path ( Join-Path -Path $this.ProjectRoot -ChildPath ".." ) )
        } else {
            $this.IsForeignProject = $true
            $this.RepositoryRoot = $this.ProjectRoot
        }

        # $BoostrapRootDirectory = ( Get-Item -Path $PSScriptRoot ).Parent
        # $ScriptsFolder = ( Get-Item -Path $this.RepositoryRoot ).Parent

        # $this.AbsoluteBootstrapScriptsFolder = Convert-Path( Join-Path -Path $BoostrapRootDirectory -ChildPath "Scripts" )
        # $this.RelativeBootstrapScriptsFolder = $this.GetRelativePath( $this.AbsoluteBootstrapScriptsFolder )        
        # $this.ProjectConfigFolder = Convert-Path ( Join-Path -Path $this.ProjectRoot -ChildPath "Config" )

        $this.ScriptsPythonFolder = Convert-Path ( Join-Path -Path $this.RepositoryRoot -ChildPath "Scripts/Python" )

        if ( -not( Test-Path $this.ScriptsPythonFolder ) ) {
            New-Item -Path $this.ScriptsPythonFolder -ItemType Directory -Force
        }

        # $relativeProjectScriptsPythonFolder = $this.GetRelativePath( $this.ScriptsPythonFolder )
        # $this.RelativeProjectScriptsPythonAliasFolder = Convert-Path ( Join-Path -Path $relativeProjectScriptsPythonFolder -ChildPath ".venv/Scripts" )
    }

    [string] GetRelativePath($path) {
        return ( $path | Resolve-Path -Relative -RelativeBasePath $this.RepositoryRoot )
    }

    [void] ReplaceTokensInFile($filePath) {
        (Get-Content $filePath) `
            -replace [regex]::Escape('@projectName@'), $this.ProjectName `
            -replace [regex]::Escape('@bootstrapScriptsFolder@'), $this.RelativeBootstrapScriptsFolder `
            -replace [regex]::Escape('@isForeignProject@'), $this.IsForeignProject `
            -replace [regex]::Escape('@pythonScriptsFolder@'), $this.RelativeProjectScriptsPythonAliasFolder | 
            Set-Content $filePath
    }
}