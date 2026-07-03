"""
Step 5: make sure there is an actual Unreal project (a .uproject file) in the
child project folder before continuing.

Steps 2-4 only ever create an *empty* child folder next to the freshly
extracted engine. The user is expected to create (or copy) their .uproject
and sources into that folder using the extracted engine, then re-run this
module so it can pick up from here and finish the setup (steps 6-8).
"""
from __future__ import annotations

from ue_bootstrap.command import Command


class CheckProjectExistsCommand(Command):
    def get_step_number(self):
        return 5

    def get_step_name(self):
        return "Check for an Unreal project in the child folder"

    def execute(self):
        context = self.context
        folder = context.child_project_folder

        has_uproject = folder.exists() and any(folder.glob("*.uproject"))

        if not has_uproject:
            print(f"  no .uproject found in {folder}")
            context.stop(
                f"No .uproject file found in {folder}. Create your Unreal "
                f"project there (using the engine extracted into "
                f"{context.root_project_folder}), then re-run this module "
                "to finish setting it up."
            )
        else:
            print(f"  found an Unreal project in {folder}")
