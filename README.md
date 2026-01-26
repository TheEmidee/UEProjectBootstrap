# UEPyScriptsBootstrap

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) 

Boostrap scripts to use UEPyScripts and GameDevTools

## Installation 🛠️

- Add to your unreal engine repository as a submodule: `git submodule add git@github.com:TheEmidee/UEPyScriptsBootstrap Scripts/Python`

## Quick Start 🚀

Bootstrap the project:

- Execute the script `bootstrap.ps1`. This script will create:
   - `Setup.ps1` at the root of the project.
   - `Config.ini` in `Config/PyScripts`
   - `CompileAndRunEditor.ps1` also at the root
   - `BuildgraphTask.ps1` in the folder `Scripts/Project`
- Execute `Setup.ps1` to:
   1. check if python is installed, and install it if not
   2. create the python virtual environment
   3. install the python packages [UEPyScripts](https://github.com/TheEmidee/UEPyScripts) and [PyGameDevTools](https://github.com/TheEmidee/PyGameDevTools).
   3. call the script `ue-check-engine-installation`
- Execute `CompileAndRunEditor.ps1` to compile your C++ code and run the editor when done !
- If you use buildgraph in your project:
   1. Uncomment the buildgraph properties in `Config/PyScripts/config.ini` and adapt to your project
   2. Duplicate the script `BuildgraphTask.ps1` and adapt it to run your own targets.