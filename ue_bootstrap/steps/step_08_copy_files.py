"""Step 8: copy the standard root-level project files, one sub-command each."""
from __future__ import annotations

import shutil
from pathlib import Path

from ue_bootstrap import constants
from ue_bootstrap.command import Command, SubCommand


class CopyRootFilesCommand(Command):
    def get_step_number(self):
        return 8

    def get_step_name(self):
        return "Copy root project files"

    def execute(self):
        pass  # all the work happens in the sub-commands below

    def get_sub_commands(self):
        return [
            CopyTemplateFileCommand(self.context, "8a", constants.TEMPLATE_FILES["lfsconfig"]),
            CopyTemplateFileCommand(self.context, "8b", constants.TEMPLATE_FILES["gitattributes"]),
            CopyTemplateFileCommand(self.context, "8c", constants.TEMPLATE_FILES["gitignore"]),
            CopyTemplateFileCommand(self.context, "8d", constants.TEMPLATE_FILES["clang_format"]),
        ]


class CopyTemplateFileCommand(SubCommand):
    def __init__(self, context, step_number, filename):
        self._step_number = step_number
        self._filename = filename
        super().__init__(context)

    def get_step_number(self):
        return self._step_number

    def get_step_name(self):
        return f"Copy {self._filename}"

    def should_bypass(self):
        return self._destination().exists()

    def execute(self):
        source = self._source()
        destination = self._destination()
        print(f"  copying {source} -> {destination}")
        shutil.copyfile(source, destination)

    def _source(self) -> Path:
        return (
            Path(__file__).resolve().parent.parent
            / constants.RESOURCES_DIR_NAME
            / constants.TEMPLATES_DIR_NAME
            / self._filename
        )

    def _destination(self) -> Path:
        return self.context.root_project_folder / self._filename
