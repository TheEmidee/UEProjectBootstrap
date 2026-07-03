"""Step 7: install pre-commit into the project's venv and drop its config file."""
from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from ue_bootstrap import constants
from ue_bootstrap.command import Command


class SetupPreCommitCommand(Command):
    def get_step_number(self):
        return 7

    def get_step_name(self):
        return "Install pre-commit"

    def should_bypass(self):
        target = self.context.root_project_folder / constants.TEMPLATE_FILES["pre_commit_config"]
        return target.exists()

    def execute(self):
        context = self.context
        venv_path = context.python_folder / ".venv"

        install_cmd = [
            "uv", "pip", "install",
            f"pre-commit=={constants.PRE_COMMIT_VERSION}",
            "--python", str(venv_path),
        ]
        print(f"  running: {' '.join(install_cmd)}")
        subprocess.run(install_cmd, check=True, cwd=context.python_folder)

        source = self._templates_folder() / constants.TEMPLATE_FILES["pre_commit_config"]
        destination = context.root_project_folder / constants.TEMPLATE_FILES["pre_commit_config"]

        print(f"  copying {source} -> {destination}")
        shutil.copyfile(source, destination)

    def _templates_folder(self) -> Path:
        return (
            Path(__file__).resolve().parent.parent
            / constants.RESOURCES_DIR_NAME
            / constants.TEMPLATES_DIR_NAME
        )
