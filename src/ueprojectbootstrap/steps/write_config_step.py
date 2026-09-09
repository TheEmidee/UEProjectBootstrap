from __future__ import annotations

from ueprojectbootstrap.context import BootstrapContext
from ueprojectbootstrap.steps.base import Step
from ueprojectbootstrap.template_utils import render_template, write_file


class WriteConfigStep(Step):
    order = 30

    def execute(self, context: BootstrapContext) -> None:
        tokens = {
            "projectName": context.project_name,
        }
        content = render_template("config.ini", tokens)
        destination = context.project_config_folder / "PyScripts" / "config.ini"
        write_file(destination, content, force=False)
