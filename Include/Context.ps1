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

    Context() {
        $this.SetProjectRoot()
        
        $BoostrapRootDirectory = ( Get-Item -Path $PSScriptRoot ).Parent
        $ScriptsFolder = ( Get-Item -Path $BoostrapRootDirectory ).Parent

        $this.AbsoluteBootstrapScriptsFolder = Convert-Path( Join-Path -Path $BoostrapRootDirectory -ChildPath "Scripts" )
        $this.RelativeBootstrapScriptsFolder = $this.GetRelativePath( $this.AbsoluteBootstrapScriptsFolder )        
        $this.ProjectConfigFolder = Convert-Path ( Join-Path -Path $this.ProjectRoot -ChildPath "Config" )

        $this.ScriptsPythonFolder = Convert-Path ( Join-Path -Path $ScriptsFolder -ChildPath "Python" )

        if ( -not( Test-Path $this.ScriptsPythonFolder ) ) {
            New-Item -Path $this.ScriptsPythonFolder -ItemType Directory -Force
        }

        $relativeProjectScriptsPythonFolder = $this.GetRelativePath( $this.ScriptsPythonFolder )
        $this.RelativeProjectScriptsPythonAliasFolder = Convert-Path ( Join-Path -Path $relativeProjectScriptsPythonFolder -ChildPath ".venv/Scripts" )
    }

    [void] SetProjectRoot() {
        $currentDir = Get-Item -Path $PSScriptRoot

        while ($currentDir) {
            $uprojectFiles = Get-ChildItem -Path $currentDir -Filter "*.uproject" -File
            if ($uprojectFiles) {
                $this.ProjectRoot = $currentDir
                $this.RepositoryRoot = $currentDir
                $this.ProjectName = [System.IO.Path]::GetFileNameWithoutExtension($uprojectFiles[0].Name)
                $this.IsForeignProject = $true
                break
            } elseif (Test-Path -Path "$($currentDir)/Engine/Build/Build.version" ) {
                $excludeFolders = @('Engine', 'FeaturePacks', 'Samples', 'Templates', '.git')
                $foundUproject = $this.FindUprojectExcluding($currentDir, $excludeFolders)

                if ($foundUproject) {
                    $this.RepositoryRoot = $currentDir
                    $this.ProjectRoot = $foundUproject.Directory
                    $this.ProjectName = [System.IO.Path]::GetFileNameWithoutExtension($foundUproject.Name)
                } else {
                    $this.ProjectRoot = $currentDir
                }

                $this.IsForeignProject = $false
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
        $this.RepositoryRoot = Convert-Path $this.RepositoryRoot
    }

    [System.IO.FileInfo] FindUprojectExcluding([string]$searchRoot, [string[]]$excludeNames) {
        $stack = [System.Collections.Generic.Stack[System.IO.DirectoryInfo]]::new()
        $stack.Push([System.IO.DirectoryInfo]::new($searchRoot))

        while ($stack.Count -gt 0) {
            $dir = $stack.Pop()

            $found = $dir.GetFiles("*.uproject") | Select-Object -First 1
            if ($found) {
                return $found
            }

            foreach ($subDir in $dir.GetDirectories()) {
                if ($excludeNames -notcontains $subDir.Name) {
                    $stack.Push($subDir)
                }
            }
        }

        return $null
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