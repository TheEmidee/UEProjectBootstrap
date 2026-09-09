from __future__ import annotations

import shutil

from ueprojectbootstrap.context import BootstrapContext
from ueprojectbootstrap.steps.base import Step


class MoveGenerateProjectFilesStep(Step):
    order = 16

    def execute(self, context: BootstrapContext) -> None:
        if context.is_foreign_project:
            print("Skipping as the project is not native.")
            return

        source_files = sorted(path for path in context.repository_root.glob("GenerateProjectFiles*") if path.is_file())

        if not source_files:
            print(f"No GenerateProjectFiles* files found in {context.repository_root}. Skipping move.")
            return

        destination_folder = context.native_scripts_folder

        for source in source_files:
            destination = destination_folder / source.name

            if destination.is_file():
                print(f"{destination} already exists. Skipping move.")
                continue

            destination_folder.mkdir(parents=True, exist_ok=True)
            shutil.move(str(source), str(destination))
            print(f"Moved {source} to {destination}")
