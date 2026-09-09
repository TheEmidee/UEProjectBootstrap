from __future__ import annotations

import os
import subprocess
import sys

from ueprojectbootstrap.context import BootstrapContext
from ueprojectbootstrap.steps.base import Step


class RunBootstrapScriptsStep(Step):
    order = 70

    def execute(self, context: BootstrapContext) -> None:
        bootstrap_scripts_folder = context.bootstrap_scripts_folder

        if not bootstrap_scripts_folder.is_dir():
            print(f"No bootstrap scripts folder found at {bootstrap_scripts_folder}. Skipping.")
            return

        scripts = sorted(path for path in bootstrap_scripts_folder.glob("*.py") if path.is_file())

        if not scripts:
            print(f"No bootstrap scripts found in {bootstrap_scripts_folder}. Skipping.")
            return

        env = {**os.environ, **context.to_env()}

        for script in scripts:
            print(f"Running bootstrap script {script.name}...")
            try:
                subprocess.run(["uv", "run", str(script)], cwd=context.repository_root, check=True, env=env)
            except subprocess.CalledProcessError as error:
                print(f"Bootstrap script {script.name} failed: {error}", file=sys.stderr)
                raise SystemExit(1) from error
