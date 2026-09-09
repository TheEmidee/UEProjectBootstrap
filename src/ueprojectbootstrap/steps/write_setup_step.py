from __future__ import annotations

from ueprojectbootstrap.context import BootstrapContext
from ueprojectbootstrap.steps.base import Step
from ueprojectbootstrap.template_utils import render_template, write_file


class WriteSetupStep(Step):
    order = 20

    def execute(self, context: BootstrapContext) -> None:
        tokens = {
            "isForeignProject": "True" if context.is_foreign_project else "False",
        }
        content = render_template("Setup.ps1", tokens)
        write_file(context.repository_root / "Setup.ps1", content, force=True)
