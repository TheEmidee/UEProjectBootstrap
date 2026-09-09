from __future__ import annotations

from ueprojectbootstrap.context import BootstrapContext
from ueprojectbootstrap.steps.base import Step
from ueprojectbootstrap.template_utils import render_template, write_file


class WriteCompileAndRunEditorStep(Step):
    order = 40

    def execute(self, context: BootstrapContext) -> None:
        tokens = {
            "pythonScriptsFolder": context.relative_venv_scripts_folder(context.project_root),
        }
        content = render_template("CompileAndRunEditor.ps1", tokens)
        write_file(context.project_root / "CompileAndRunEditor.ps1", content, force=True)
