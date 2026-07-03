# ue_bootstrap

Bootstraps an Unreal Engine project as a **native project of the engine sources**
(i.e. the project lives inside a checkout of the engine, rather than pointing
at a separately-installed engine).

## Usage

```bash
python -m ue_bootstrap \
    --project-name MyGame \
    --target-folder D:/Projects \
    --engine-version 5.7.4
```

or, if installed (`pip install .`):

```bash
ue-bootstrap --project-name MyGame --target-folder D:/Projects --engine-version 5.7.4
```

Any argument you omit will be prompted for interactively during step 1.

## What it does

1. **Gather information** - project name / target folder / engine version, stored on the `Context`.
2. **Create project folders** - `<target>/<project_name>/<project_name>`.
3. **Download engine sources** - zip of the requested engine tag from
   `EpicGames/UnrealEngine` on GitHub. This is a private repo — set the
   `EPIC_GITHUB_TOKEN` environment variable to a GitHub personal access token
   from an account linked to Epic, or the download will fail with a 404/403.
4. **Extract engine sources** into the root project folder.
5. **Check for a project** - if the child project folder (the inner
   `<project_name>` folder) is empty, the module stops and tells you to
   create your `.uproject` there manually using the freshly extracted engine,
   then re-run the module.
6. **Set up Python** (`Scripts/Python`), via sub-steps:
   a. create the folder, b. install `uv`, c. install the pinned Python
   version with `uv`, d. create the venv and `uv pip install -r requirements.txt`.
7. **Install pre-commit** into the venv and copy `.pre-commit-config.yaml` to
   the project root.
8. **Copy root files** - `.lfsconfig`, `.gitattributes`, `.gitignore`,
   `.clang-format`, each as its own sub-step.

Re-running the module is safe: every step implements `should_bypass()` so
already-completed work is skipped and reported as such.

## Layout

```
ue_bootstrap/
    command.py        # Command / SubCommand base classes
    context.py         # shared Context dataclass
    constants.py        # static data (python version, package pins, urls...)
    discovery.py         # auto-discovers step classes
    runner.py             # orders + runs discovered steps
    cli.py                 # argument parsing / entry point
    steps/                  # one file per top-level step
        step_01_gather_information.py
        step_02_create_folders.py
        step_03_download_engine.py
        step_04_extract_engine.py
        step_05_check_project.py
        step_06_setup_python.py     # + sub-commands 6a-6d
        step_07_pre_commit.py
        step_08_copy_files.py         # + sub-commands 8a-8d
    resources/
        requirements.txt
        templates/
            .pre-commit-config.yaml
            .lfsconfig
            .gitattributes
            .gitignore
            .clang-format
```

## Adding a new step

Drop a new file in `steps/`, subclass `Command`, implement
`get_step_number`, `get_step_name`, `execute` (and optionally
`should_bypass`, `ask_user`, `get_sub_commands`). It will be picked up
automatically — no registration needed. Use a step number that doesn't
collide with an existing one to control ordering.
