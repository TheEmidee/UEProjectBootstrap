from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class BootstrapContext:
    """Paths describing the Unreal Engine project being bootstrapped.

    For a foreign project, `repository_root` and `project_root` are the same folder.
    For a native project, `repository_root` is the folder containing the Engine, and
    `project_root` is the sub-folder containing the .uproject file.
    """

    uproject_path: Path
    project_root: Path
    project_name: str
    repository_root: Path
    is_foreign_project: bool

    @property
    def project_config_folder(self) -> Path:
        return self.project_root / "Config"

    @property
    def python_folder(self) -> Path:
        return self.repository_root / "Scripts" / "Python"

    @property
    def native_scripts_folder(self) -> Path:
        return self.repository_root / "Scripts" / "UE"

    @property
    def venv_scripts_folder(self) -> Path:
        return self.python_folder / ".venv" / "Scripts"

    def relative_venv_scripts_folder(self, from_dir: Path) -> str:
        relative_path = os.path.relpath(self.venv_scripts_folder, from_dir)
        return Path(relative_path).as_posix()

    @classmethod
    def from_uproject(cls, uproject_path: Path) -> "BootstrapContext":
        uproject_path = uproject_path.resolve()

        if not uproject_path.is_file() or uproject_path.suffix != ".uproject":
            raise ValueError(f"'{uproject_path}' is not a valid .uproject file.")

        project_root = uproject_path.parent
        project_name = uproject_path.stem

        repository_root = project_root
        is_foreign_project = True

        current_dir = project_root
        while True:
            if (current_dir / "Engine" / "Build" / "Build.version").is_file():
                repository_root = current_dir
                is_foreign_project = False
                break

            parent_dir = current_dir.parent
            if parent_dir == current_dir:
                break
            current_dir = parent_dir

        return cls(
            uproject_path=uproject_path,
            project_root=project_root,
            project_name=project_name,
            repository_root=repository_root,
            is_foreign_project=is_foreign_project,
        )
