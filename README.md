# UEProjectBootstrap

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) 

Boostrap an unreal engine project with various tools and scripts, like UEPyScripts and GameDevTools, using [Astral UV](https://docs.astral.sh/uv/)

## Installation 🛠️

This tool is a standalone Python package, run from outside the project you want to bootstrap — it is not added as a submodule anymore.

- Clone this repository.
- Run `setup-env.ps1` to install [Astral UV](https://docs.astral.sh/uv/) and sync the tool's own virtual environment.

## Quick Start 🚀

Bootstrap a project by pointing the tool at its `.uproject` file:

```
uv run ueprojectbootstrap "C:\Path\To\YourProject\YourProject.uproject"
```

For a native project (engine + game in the same repository), pass the `.uproject` file inside the game folder — the tool walks up from it to find the repository root (the folder containing `Engine/Build/Build.version`) automatically. For a foreign project, the repository root and the game project folder are the same.

The tool will:
   - Create `Setup.ps1` at the root of the repository.
   - Create `config.ini` in `Config/PyScripts` of the game project folder.
   - Create `CompileAndRunEditor.ps1` and `GenerateVSSolution.ps1` in the game project folder.
   - Create `.pre-commit-config.yaml` at the root of the repository.
   - Run any python script found in `Scripts/Python/Bootstrap`, using `uv run`.

When the script is done, you can now commit all the changes so that all the users have access to the various scripts.

When the project has been bootstrapped, each user can:

- Execute `Setup.ps1` (at the root of the repository) to:
   1. Ask whether to apply performance optimizations (Windows Defender and Search indexing exclusions on the repository root). If accepted and the script isn't already running elevated, it relaunches itself with an admin prompt to apply them, then continues. Skipped when `-BuildMachine` is passed.
   2. Run `Scripts/UE/Setup.bat` if the project is native.
   3. Install [Astral UV](https://docs.astral.sh/uv/) and the required Python version.
   4. Create the python virtual environment with the python packages [UEPyScripts](https://github.com/TheEmidee/UEPyScripts), [PyGameDevTools](https://github.com/TheEmidee/PyGameDevTools) and [pypyr](https://pypyr.io)
   5. Install [pre-commit](https://pre-commit.com/index.html) and its hooks.
   6. Call the script `ue-check-engine-installation` for a foreign project.
- Execute `CompileAndRunEditor.ps1` (in the game project folder) to compile your C++ code and run the editor when done!
- Execute `GenerateVSSolution.ps1` (in the game project folder) to regenerate the Visual Studio solution.
- For native projects, `.pre-commit-config.yaml` also runs `ue-ugs-pull` on the `post-checkout` and `post-merge` git hooks.

## Custom bootstrap / setup scripts

You can run custom python scripts at two points:
- When the project is bootstrapped (once, by whoever runs `ueprojectbootstrap`): put scripts in `Scripts/Python/Bootstrap`, they are run in alphabetical order with `uv run`.
- Every time a developer runs `Setup.ps1`: put scripts in `Scripts/Python/Setup`, they are run in alphabetical order using the project's virtual environment.

Since these scripts run as separate processes, they are given context through environment variables instead of arguments:
- `UE_BOOTSTRAP_REPOSITORY_ROOT`: path to the repository root.
- `UE_BOOTSTRAP_PROJECT_ROOT`, `UE_BOOTSTRAP_PROJECT_NAME`, `UE_BOOTSTRAP_UPROJECT_PATH`, `UE_BOOTSTRAP_IS_FOREIGN_PROJECT` (`1`/`0`): only set by `ueprojectbootstrap` itself, i.e. for `Scripts/Python/Bootstrap` scripts.
- `UE_BOOTSTRAP_ENGINE_VERSION`: the engine's `Major.Minor` version (e.g. `5.8`), read from `Engine/Build/Build.version`. Set for both `Bootstrap` and `Setup` scripts whenever that file can be found.

See [Examples](Examples/) for sample scripts.

## Developing this tool

The tool's source lives in `src/ueprojectbootstrap`. Each bootstrap step is its own class in `src/ueprojectbootstrap/steps`, implementing the abstract `Step` class (an `execute()` method and an `order` property); the CLI discovers and runs them in order automatically. Run `setup-env.ps1` to set up a dev environment with `uv`.