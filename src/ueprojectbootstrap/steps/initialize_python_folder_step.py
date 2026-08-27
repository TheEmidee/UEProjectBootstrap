from __future__ import annotations

from ueprojectbootstrap.context import BootstrapContext
from ueprojectbootstrap.steps.base import Step
from ueprojectbootstrap.template_utils import write_file


class InitializePythonFolderStep(Step):
    order = 10

    def execute(self, context: BootstrapContext) -> None:
        gitignore_path = context.python_folder / ".gitignore"
        write_file(gitignore_path, ".venv/\n", force=True)
