"""Step 2: create <target_folder>/<project_name>/<project_name>."""
from __future__ import annotations

from ue_bootstrap.command import Command


class CreateFoldersCommand(Command):
    def get_step_number(self):
        return 2

    def get_step_name(self):
        return "Create project folders"

    def should_bypass(self):
        return self.context.project_already_bootstrapped

    def execute(self):
        context = self.context
        context.root_project_folder.mkdir(parents=True, exist_ok=True)
        context.child_project_folder.mkdir(parents=True, exist_ok=True)
        print(f"  created {context.root_project_folder}")
        print(f"  created {context.child_project_folder}")
