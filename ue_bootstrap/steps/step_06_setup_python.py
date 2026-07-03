"""
Step 6: set up an isolated Python environment for the project, using uv.

Broken into sub-commands, matching the requested a/b/c/d breakdown:
    6a. create the Scripts/Python folder
    6b. install uv
    6c. use uv to install the pinned Python version
    6d. create the venv and install requirements.txt into it
"""
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

from ue_bootstrap import constants
from ue_bootstrap.command import Command, SubCommand


class SetupPythonCommand(Command):
    def get_step_number(self):
        return 6

    def get_step_name(self):
        return "Set up Python (Scripts/Python)"

    def execute(self):
        self.context.python_folder = self.context.child_project_folder / "Scripts" / "Python"
        print(f"  python folder: {self.context.python_folder}")

    def get_sub_commands(self):
        return [
            CreatePythonFolderCommand(self.context),
            InstallUvCommand(self.context),
            InstallPythonWithUvCommand(self.context),
            CreateVenvCommand(self.context),
        ]


class CreatePythonFolderCommand(SubCommand):
    def get_step_number(self):
        return "6a"

    def get_step_name(self):
        return "Create Scripts/Python folder"

    def should_bypass(self):
        return self.context.python_folder.exists()

    def execute(self):
        self.context.python_folder.mkdir(parents=True, exist_ok=True)
        print(f"  created {self.context.python_folder}")


class InstallUvCommand(SubCommand):
    def get_step_number(self):
        return "6b"

    def get_step_name(self):
        return "Install uv"

    def should_bypass(self):
        return shutil.which("uv") is not None

    def execute(self):
        cmd = constants.UV_INSTALL_CMD_WINDOWS if sys.platform == "win32" else constants.UV_INSTALL_CMD_UNIX
        print(f"  running: {' '.join(cmd)}")
        subprocess.run(cmd, check=True)


class InstallPythonWithUvCommand(SubCommand):
    def get_step_number(self):
        return "6c"

    def get_step_name(self):
        return f"Install Python {constants.PYTHON_VERSION} with uv"

    def execute(self):
        cmd = ["uv", "python", "install", constants.PYTHON_VERSION]
        print(f"  running: {' '.join(cmd)}")
        subprocess.run(cmd, check=True, cwd=self.context.python_folder)


class CreateVenvCommand(SubCommand):
    def get_step_number(self):
        return "6d"

    def get_step_name(self):
        return "Create the venv and install requirements"

    def should_bypass(self):
        return (self.context.python_folder / ".venv").exists()

    def execute(self):
        context = self.context
        venv_path = context.python_folder / ".venv"

        create_cmd = ["uv", "venv", str(venv_path), "--python", constants.PYTHON_VERSION]
        print(f"  running: {' '.join(create_cmd)}")
        subprocess.run(create_cmd, check=True, cwd=context.python_folder)

        requirements_path = (
            Path(__file__).resolve().parent.parent
            / constants.RESOURCES_DIR_NAME
            / constants.REQUIREMENTS_FILENAME
        )

        install_cmd = [
            "uv", "pip", "install",
            "-r", str(requirements_path),
            "--python", str(venv_path),
            *constants.UV_VENV_EXTRA_ARGS,
        ]
        print(f"  running: {' '.join(install_cmd)}")
        subprocess.run(install_cmd, check=True, cwd=context.python_folder)
