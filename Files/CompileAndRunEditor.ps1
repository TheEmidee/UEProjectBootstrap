try {
    & "$pythonScriptsFolder/ue-close-editor.exe"
    & "$pythonScriptsFolder/ue-compile-editor.exe"
    & "$pythonScriptsFolder/ue-run-editor.exe"
}
catch {
    Write-Error $_.Exception.Message
}