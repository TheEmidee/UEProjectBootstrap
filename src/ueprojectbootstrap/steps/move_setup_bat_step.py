from __future__ import annotations

import shutil

from ueprojectbootstrap.context import BootstrapContext
from ueprojectbootstrap.steps.base import Step


class MoveSetupBatStep(Step):
    order = 15

    def execute(self, context: BootstrapContext) -> None:
        if context.is_foreign_project:
            print("Skipping as the project is not native.")
            return

        source = context.repository_root / "Setup.bat"
        destination = context.repository_root / "Scripts" / "Setup.bat"

        if destination.is_file():
            print(f"{destination} already exists. Skipping move.")
            return

        if not source.is_file():
            print(f"{source} not found. Skipping move.")
            return

        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(source), str(destination))
        print(f"Moved {source} to {destination}")
