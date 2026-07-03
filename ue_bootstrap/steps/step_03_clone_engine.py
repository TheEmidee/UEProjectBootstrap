"""Step 3: clone the engine sources for the requested version via git.

We clone rather than downloading the tag zip archive because the archive
endpoint doesn't reliably accept token auth for a private repo like
EpicGames/UnrealEngine - a plain `git clone` with the token embedded in the
URL is the more reliable path.
"""
from __future__ import annotations

import os
import shutil
import subprocess

from ue_bootstrap import constants
from ue_bootstrap.command import Command


class CloneEngineCommand(Command):
    def get_step_number(self):
        return 3

    def get_step_name(self):
        return "Clone engine sources"

    def should_bypass(self):
        context = self.context
        if context.project_already_bootstrapped:
            return True
        return (context.root_project_folder / ".git").exists()

    def execute(self):
        context = self.context

        if shutil.which("git") is None:
            context.stop("git is not installed / not on PATH. Install git and re-run this module.")
            return

        tag = constants.ENGINE_TAG_TEMPLATE.format(version=context.engine_version)
        url = self._clone_url()

        # git refuses to clone into a non-empty directory. Step 2 already
        # created the (empty) child project folder inside root_project_folder,
        # which counts as an entry, so remove it, clone, then recreate it.
        child = context.child_project_folder
        child_existed = child.exists()
        if child_existed:
            child.rmdir()

        # Never print `url` - it may contain the token.
        print(f"  running: git clone --branch {tag} --depth 1 {url} {context.root_project_folder}")
        cmd = ["git", "clone", "--branch", tag, "--depth", "1", url, str(context.root_project_folder)]
        subprocess.run(cmd, check=True)

        if child_existed:
            child.mkdir(parents=True, exist_ok=True)

    def _clone_url(self) -> str:
        return f"https://github.com/{constants.ENGINE_REPO_PATH}"
