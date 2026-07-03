"""Step 4: extract the downloaded engine zip into the root project folder."""
from __future__ import annotations

import zipfile

from ue_bootstrap.command import Command


class ExtractEngineCommand(Command):
    def get_step_number(self):
        return 4

    def get_step_name(self):
        return "Extract engine sources"

    def should_bypass(self):
        context = self.context
        if context.project_already_bootstrapped:
            return True
        return self._marker_file().exists()

    def execute(self):
        context = self.context
        zip_path = context.get("engine_zip_path")

        print(f"  extracting {zip_path}")
        print(f"  -> {context.root_project_folder}")

        with zipfile.ZipFile(zip_path) as archive:
            archive.extractall(context.root_project_folder)

        self._marker_file().touch()

    def _marker_file(self):
        return self.context.root_project_folder / ".engine_extracted"
