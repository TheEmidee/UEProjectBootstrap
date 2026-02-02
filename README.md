# UEProjectBootstrap

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) 

Boostrap an unreal engine project with various tools and scripts, like UEPyScripts and GameDevTools, using [Astral UV](https://docs.astral.sh/uv/)

## Installation 🛠️

- Add to your unreal engine repository as a submodule: `git submodule add git@github.com:TheEmidee/UEPyScriptsBootstrap Scripts/Bootstrap`

## Quick Start 🚀

Bootstrap the project:

Execute the script `bootstrap.ps1`. This script will create:
   - `Setup.ps1` at the root of the project.
   - `Config.ini` in `Config/PyScripts`
   - `CompileAndRunEditor.ps1` also at the root
   - `BuildgraphTask.ps1` in the folder `Scripts/Project`
   - `.pre-commit-config.yaml` at the root of the project

When the project has been bootstrapped, you can:

- Execute `Setup.ps1` to:
   1. Install the required python version
   2. Install [pre-commit](https://pre-commit.com/index.html)
   3. Create the python virtual environment with the python packages [UEPyScripts](https://github.com/TheEmidee/UEPyScripts), [PyGameDevTools](https://github.com/TheEmidee/PyGameDevTools) and [pypyr](https://pypyr.io)
   4. Install the pre-commit hooks
   5. Execute the python custom setup scripts
   6. call the script `ue-check-engine-installation`
- Execute `CompileAndRunEditor.ps1` to compile your C++ code and run the editor when done !
- If you use buildgraph in your project:
   1. Uncomment the buildgraph properties in `Config/PyScripts/config.ini` and adapt to your project
   2. Duplicate the script `BuildgraphTask.ps1` and adapt it to run your own targets.

## Custom setup code

If you want to run custom python scripts when `Setup.ps1` is executed, you need to put those scripts in the folder `Scripts/Python/.setup` of your project. 

Those scripts will be executed by alphabetical order.

Note that if those scripts require any dependency, you will have to add them to a file named `requirements.txt` that you will also to place in the folder `Scripts/Python`.

Some ideas of custom scripts:
* Update the file `BuildConfiguration.xml` with default values for the `MaxProcessorCount`
* Install [Horde Agent](https://dev.epicgames.com/documentation/en-us/unreal-engine/horde-agent-deployment-for-unreal-engine) to setup a build farm
* Setup [AutoSDK](https://dev.epicgames.com/documentation/en-us/unreal-engine/using-the-autosdk-system-in-unreal-engine)
* etc...