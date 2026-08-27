from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

from ueprojectbootstrap.context import BootstrapContext
from ueprojectbootstrap.steps import collect_steps

_MESSAGE = """The setup of the project is done.
Things you can do now:
* Update the config file in Config/PyScripts/config.ini
* Update the .pre-commit-config.yaml file if needed
* Commit the generated files so every developer has access to them
"""


def _parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="ueprojectbootstrap",
        description="Bootstrap an Unreal Engine project with various tools and scripts.",
    )
    parser.add_argument(
        "--uproject",
        type=Path,
        help="Path to the .uproject file of the project to bootstrap.",
    )
    return parser.parse_args(argv)

def _run_setup(context: BootstrapContext) -> None:
    setup_script = context.repository_root / "Setup.ps1"
    print(f"\nExecuting {setup_script}...")
    try:
        subprocess.run(
            ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(setup_script)],
            cwd=context.repository_root,
            check=True,
        )
    except subprocess.CalledProcessError as error:
        print(f"Failed to execute {setup_script}: {error}", file=sys.stderr)
        raise SystemExit(1) from error


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)

    try:
        context = BootstrapContext.from_uproject(args.uproject)
    except ValueError as error:
        print(error, file=sys.stderr)
        return 1

    print(f"Project name: {context.project_name}")
    print(f"Project root: {context.project_root}")
    print(f"Repository root: {context.repository_root}")
    print(f"Foreign project: {context.is_foreign_project}")

    for step in collect_steps():
        print(f"\n--- Running step: {type(step).__name__} ---")
        step.execute(context)

    print(f"\n{_MESSAGE}")

    answer = input("Would you like to execute Setup.ps1 now? (Y/N) ")
    if answer.strip().lower() == "y":
        _run_setup(context)
    else:
        print("You can execute Setup.ps1 later by running it from the repository root folder.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
