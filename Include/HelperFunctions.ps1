function Write-ImportantMessage {
    param(
        [string]$Message,
        [int]$Padding = 2
    )

    $lines      = $Message -split "`n"
    $maxLength  = ($lines | Measure-Object -Property Length -Maximum).Maximum
    $innerWidth = $maxLength + ($Padding * 2)
    $border     = "*" * ($innerWidth + 2)
    $spaces     = " " * $Padding

    Write-Host
    Write-Host $border
    foreach ($line in $lines) {
        # $padded = $line.PadRight($maxLength)
        # Write-Host "*$spaces$padded$spaces*"
        Write-Host $line
    }
    Write-Host $border
    Write-Host
}

function Convert-Path($path) {
    return $path -replace '^\\.\\', '' -replace '\\', '/'
}

function Copy-File($sourceFileName, $destinationFolder, $force) {
    # Source files are relative to the bootstrap.ps1 directory which is the parent of the "Include" folder where this function is defined
    $sourceFile = Join-Path -Path ( ( Get-Item -Path $PSScriptRoot ).Parent ) -ChildPath $sourceFileName

    if ( -not ( Test-Path -Path $sourceFile ) ) {
        Write-Host "Source file $sourceFile does not exist." -ForegroundColor Red
        exit 1
    }

    $fileNameOnly = Split-Path -Path $sourceFile -Leaf

    $destinationFile = Join-Path -Path $destinationFolder -ChildPath $fileNameOnly
    if ($force -eq $false -and ( Test-Path -Path $destinationFile ) ) {
        Write-Host "File $destinationFile already exists. Skipping copy." -ForegroundColor Yellow
        return $False
    }

    Write-Host "Copy $sourceFile to $destinationFile" -ForegroundColor Cyan

    New-Item -ItemType Directory -Force -Path $destinationFolder | Out-Null
    Copy-Item -Path $sourceFile -Destination $destinationFile -PassThru -Force | Out-Null
    
    Write-Host "Copied $sourceFile to $destinationFile" -ForegroundColor Green
    return $True
}

function Copy-Folder($sourceFolder, $destinationFolder, $force) {
    $sourceFolder = Join-Path -Path ( ( Get-Item -Path $PSScriptRoot ).Parent ) -ChildPath $sourceFolder

    Write-Host "Copy $sourceFolder to $destinationFolder..." -ForegroundColor Cyan

    if ( $force -or -not( Test-Path $destinationFolder ) ) {
        
            Get-ChildItem -Path $sourceFolder -Recurse | ForEach-Object {
            $relativePath = $_.FullName.Substring($sourceFolder.Length + 1)
            $targetPath = Join-Path -Path $destinationFolder -ChildPath $relativePath

            if ($_.PSIsContainer) {
                New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
            } else {
                Copy-Item -Path $_.FullName -Destination $targetPath -Force | Out-Null
            }
        }

        Write-Host "Copied $sourceFolder to $destinationFolder." -ForegroundColor Green

        return $true
    } else {
        Write-Host "Destination folder $destinationFolder already exists. Skipping copy." -ForegroundColor Yellow
        return $false
    }
}