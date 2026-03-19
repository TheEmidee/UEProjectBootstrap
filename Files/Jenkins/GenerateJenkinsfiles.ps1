$batchFilePath = Join-Path -Path $PSScriptRoot -ChildPath "config/batch.yml" 

& (Join-Path -Path $PSScriptRoot -ChildPath "../../Python/.venv/Scripts/jenkinsfilegenerator.exe") --batch $batchFilePath