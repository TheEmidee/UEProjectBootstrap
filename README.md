# UEProjectBootstrap

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) 

Boostrap an unreal engine project with various tools and scripts, like UEPyScripts and GameDevTools, using [Astral UV](https://docs.astral.sh/uv/)

## Installation 🛠️

- Add to your unreal engine repository as a submodule: `git submodule add git@github.com:TheEmidee/UEPyScriptsBootstrap Scripts/Bootstrap`

## Quick Start 🚀

Bootstrap the project:

Execute the script `bootstrap.ps1`. This script will:
   - Create `Setup.ps1` at the root of the project.
   - Create `Config.ini` in `Config/PyScripts`
   - Create `CompileAndRunEditor.ps1` also at the root
   - Create `BuildgraphTask.ps1` in the folder `Scripts/Project`
   - Create `.pre-commit-config.yaml` at the root of the project
   - Install Python locally using [Astral UV](https://docs.astral.sh/uv/)
   - Install the python requirements
   - Execute the python bootstrap scripts if any

When the script is done, you can now commit all the changes so that all the users have access to the various scripts.

When the project has been bootstrapped, each user can:

- Execute `Setup.ps1` to:
   1. Install [Astral UV](https://docs.astral.sh/uv/)
   2. Install the required python version
   3. Install [pre-commit](https://pre-commit.com/index.html)
   4. Create the python virtual environment with the python packages [UEPyScripts](https://github.com/TheEmidee/UEPyScripts), [PyGameDevTools](https://github.com/TheEmidee/PyGameDevTools) and [pypyr](https://pypyr.io)
   5. Install the pre-commit hooks
   6. Execute the python custom setup scripts
   7. call the script `ue-check-engine-installation`
- Execute `CompileAndRunEditor.ps1` to compile your C++ code and run the editor when done !
- If you use buildgraph in your project:
   1. Uncomment the buildgraph properties in `Config/PyScripts/config.ini` and adapt to your project
   2. Duplicate the script `BuildgraphTask.ps1` and adapt it to run your own targets.

## Custom bootstrap / setup scripts

You can execute custom python scripts when you bootstrap the project the first time, or when you call `setup.ps1`.

You need to put those scripts in the folder `Scripts/Python/.bootstrap` or `Scripts/Python/.setup` of your project. 

Those scripts will be executed by alphabetical order.

Note that if those scripts require any dependency, you will have to add them to a file named `requirements.txt` that you will also to place in the folder `Scripts/Python`.

Some ideas of custom bootstrap scripts:
* The bootstrap custom scripts can add plugins you always use in each project, as submodules

Some ideas of custom setup scripts:
* Update the file `BuildConfiguration.xml` with default values for the `MaxProcessorCount`
* Install [Horde Agent](https://dev.epicgames.com/documentation/en-us/unreal-engine/horde-agent-deployment-for-unreal-engine) to setup a build farm
* Setup [AutoSDK](https://dev.epicgames.com/documentation/en-us/unreal-engine/using-the-autosdk-system-in-unreal-engine)
* etc...

You can find examples [here](Examples/).