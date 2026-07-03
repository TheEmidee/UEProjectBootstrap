"""Step 1: gather (or confirm) the information needed to bootstrap the project."""
from __future__ import annotations

from pathlib import Path

from ue_bootstrap.command import Command


class GatherInformationCommand(Command):
    def get_step_number(self):
        return 1

    def get_step_name(self):
        return "Gather information"

    def ask_user(self):
        context = self.context

        if not context.project_name:
            context.project_name = input("Project name: ").strip()

        if not context.target_folder:
            raw = input("Target folder (where the project will be created): ").strip()
            context.target_folder = Path(raw)

        if not context.engine_version:
            context.engine_version = input("Unreal Engine version (e.g. 5.7.4): ").strip()

    def execute(self):
        context = self.context

        context.target_folder = Path(context.target_folder).expanduser().resolve()
        context.root_project_folder = context.target_folder / context.project_name
        context.child_project_folder = context.root_project_folder / context.project_name

        context.project_already_bootstrapped = context.root_project_folder.exists()

        print(f"  project name         : {context.project_name}")
        print(f"  engine version       : {context.engine_version}")
        print(f"  root project folder  : {context.root_project_folder}")
        print(f"  child project folder : {context.child_project_folder}")

        if context.project_already_bootstrapped:
            print("  -> root project folder already exists, engine download/extract will be skipped")
