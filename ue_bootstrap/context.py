"""
Shared, mutable state passed to every command.

Known/typed fields cover the things almost every step cares about
(paths, project name, engine version...). Anything more specific a
step wants to remember for later steps can go in `data` via
`Context.set()` / `Context.get()`.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, Optional


@dataclass
class Context:
    # ---- provided via CLI arguments / confirmed in step 1 ----
    project_name: Optional[str] = None
    target_folder: Optional[Path] = None
    engine_version: Optional[str] = None

    # ---- computed paths ----
    # <target_folder>/<project_name>            (holds the engine sources)
    root_project_folder: Optional[Path] = None
    # <root_project_folder>/<project_name>       (the actual Unreal project)
    child_project_folder: Optional[Path] = None
    # <child_project_folder>/Scripts/Python      (set by the "setup python" step)
    python_folder: Optional[Path] = None

    # ---- control-flow flags ----
    # True if root_project_folder already existed when step 1 ran -> engine
    # download/extract steps (2-4) are skipped.
    project_already_bootstrapped: bool = False
    # Set by any step to make the runner stop after it (with a message).
    stop_reason: Optional[str] = None

    # ---- free-form bag for anything else a step wants to remember ----
    data: Dict[str, Any] = field(default_factory=dict)

    def set(self, key: str, value: Any) -> None:
        self.data[key] = value

    def get(self, key: str, default: Any = None) -> Any:
        return self.data.get(key, default)

    def stop(self, reason: str) -> None:
        self.stop_reason = reason
