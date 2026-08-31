from __future__ import annotations

import json
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
    def engine_version(self) -> str | None:
        """The "Major.Minor" engine version, read from Engine/Build/Build.version.

        Returns None for a foreign project, or if the file can't be found/parsed.
        """
        build_version_path = self.repository_root / "Engine" / "Build" / "Build.version"
        if not build_version_path.is_file():
            return None

        data = json.loads(build_version_path.read_text(encoding="utf-8"))
        return f"{data['MajorVersion']}.{data['MinorVersion']}"

    def to_env(self) -> dict[str, str]:
        """Context values exposed as environment variables to custom bootstrap/setup
        scripts, which run as separate subprocesses and so can't be passed the
        dataclass directly."""
        env = {
            "UE_BOOTSTRAP_UPROJECT_PATH": str(self.uproject_path),
            "UE_BOOTSTRAP_PROJECT_ROOT": str(self.project_root),
            "UE_BOOTSTRAP_PROJECT_NAME": self.project_name,
            "UE_BOOTSTRAP_REPOSITORY_ROOT": str(self.repository_root),
            "UE_BOOTSTRAP_IS_FOREIGN_PROJECT": "1" if self.is_foreign_project else "0",
        }

        engine_version = self.engine_version
        if engine_version is not None:
            env["UE_BOOTSTRAP_ENGINE_VERSION"] = engine_version

        return env

    @property
    def python_folder(self) -> Path:
        return self.repository_root / "Scripts" / "Python"

    @property
    def native_scripts_folder(self) -> Path:
        return self.repository_root / "Scripts" / "UE"

    @property
    def bootstrap_scripts_folder(self) -> Path:
        return self.python_folder / "Bootstrap"

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
