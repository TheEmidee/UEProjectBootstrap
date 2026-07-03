"""Step 3: download the engine source zip for the requested version."""
from __future__ import annotations

import os
import shutil
import urllib.request
from pathlib import Path

from ue_bootstrap import constants
from ue_bootstrap.command import Command


class DownloadEngineCommand(Command):
    def get_step_number(self):
        return 3

    def get_step_name(self):
        return "Download engine sources"

    def should_bypass(self):
        context = self.context
        if context.project_already_bootstrapped:
            return True

        zip_path = self._zip_path()
        context.set("engine_zip_path", zip_path)
        return zip_path.exists()

    def execute(self):
        context = self.context
        url = constants.ENGINE_DOWNLOAD_URL_TEMPLATE.format(version=context.engine_version)
        zip_path = self._zip_path()

        print(f"  downloading {url}")
        print(f"  -> {zip_path}")

        request = urllib.request.Request(url)
        token = os.environ.get("EPIC_GITHUB_TOKEN")
        if token:
            request.add_header("Authorization", f"Bearer {token}")

        # Note: EpicGames/UnrealEngine is a private repo. Downloading this
        # tag archive requires a GitHub account linked to your Epic Games
        # account and, for a non-interactive download like this one, a
        # personal access token exposed as EPIC_GITHUB_TOKEN.
        with urllib.request.urlopen(request) as response, open(zip_path, "wb") as out_file:
            shutil.copyfileobj(response, out_file)

        context.set("engine_zip_path", zip_path)

    def _zip_path(self) -> Path:
        return self.context.root_project_folder / f"UnrealEngine-{self.context.engine_version}.zip"
