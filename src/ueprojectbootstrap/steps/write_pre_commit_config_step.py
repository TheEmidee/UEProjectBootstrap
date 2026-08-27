from __future__ import annotations

from ueprojectbootstrap.context import BootstrapContext
from ueprojectbootstrap.steps.base import Step
from ueprojectbootstrap.template_utils import read_template, write_file


class WritePreCommitConfigStep(Step):
    order = 60

    def execute(self, context: BootstrapContext) -> None:
        content = read_template("pre-commit-config.yaml")

        if not context.is_foreign_project:
            install_hook_types = read_template("pre-commit-config.install-hook-types.yaml")
            ugs_pull_hook = read_template("pre-commit-config.ugs-pull-hook.yaml")
            content = install_hook_types + content + ugs_pull_hook

        write_file(context.repository_root / ".pre-commit-config.yaml", content, force=True)
