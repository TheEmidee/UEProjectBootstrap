from __future__ import annotations

import shutil
from pathlib import Path

from ueprojectbootstrap.context import BootstrapContext
from ueprojectbootstrap.steps.base import Step

_GIT_HOOKS_GOTO_MARKER = "goto no_git_hooks_directory"
_GIT_HOOKS_LABEL_MARKER = ":no_git_hooks_directory"


class MoveSetupBatStep(Step):
    order = 15

    def execute(self, context: BootstrapContext) -> None:
        if context.is_foreign_project:
            print("Skipping as the project is not native.")
            return

        bat_destination = self._move_file(context, "Setup.bat")
        if bat_destination is not None:
            self._disable_git_hooks_registration(bat_destination)

        # Setup.sh is moved alongside Setup.bat for consistency, but it isn't used by
        # this bootstrap tool, so its content is left untouched.
        self._move_file(context, "Setup.sh")

    def _move_file(self, context: BootstrapContext, file_name: str) -> Path | None:
        source = context.repository_root / file_name
        destination = context.repository_root / "Scripts" / file_name

        if destination.is_file():
            print(f"{destination} already exists. Skipping move.")
            return None

        if not source.is_file():
            print(f"{source} not found. Skipping move.")
            return None

        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(source), str(destination))
        print(f"Moved {source} to {destination}")
        return destination

    def _disable_git_hooks_registration(self, setup_bat_path: Path) -> None:
        # Setup.bat registers .git/hooks/post-checkout and post-merge itself to run
        # GitDependencies.exe. We manage those same hooks through pre-commit instead
        # (see WritePreCommitConfigStep's ugs-pull hook), so leaving this in would
        # fight pre-commit for ownership of the hook files.
        lines = setup_bat_path.read_text(encoding="utf-8").splitlines(keepends=True)

        start_index = next((i for i, line in enumerate(lines) if _GIT_HOOKS_GOTO_MARKER in line), None)
        if start_index is None:
            print(f"Could not find the git hooks block in {setup_bat_path}. Leaving it untouched.")
            return

        if start_index > 0 and lines[start_index - 1].lstrip().lower().startswith("rem"):
            start_index -= 1

        end_index = next(
            (i for i in range(start_index, len(lines)) if _GIT_HOOKS_LABEL_MARKER in lines[i]),
            None,
        )
        if end_index is None:
            print(f"Could not find the end of the git hooks block in {setup_bat_path}. Leaving it untouched.")
            return

        for i in range(start_index, end_index + 1):
            stripped = lines[i].lstrip()
            if stripped.lower().startswith("rem"):
                continue
            indent = lines[i][: len(lines[i]) - len(stripped)]
            lines[i] = f"{indent}rem {stripped}"

        lines.insert(
            start_index,
            "rem Git hooks are registered by pre-commit instead, see .pre-commit-config.yaml\n",
        )

        setup_bat_path.write_text("".join(lines), encoding="utf-8", newline="\r\n")
        print(f"Disabled git hook registration in {setup_bat_path} (handled by pre-commit instead).")
