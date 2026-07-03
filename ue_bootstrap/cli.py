"""Command line entry point.

Usage:
    python -m ue_bootstrap --project-name MyGame --target-folder D:/Projects --engine-version 5.7.4
"""
from __future__ import annotations

from pathlib import Path
from typing import Optional, Sequence

from ue_bootstrap.context import Context
from ue_bootstrap.runner import Runner


def main(argv: Optional[Sequence[str]] = None) -> int:
    context = Context()

    Runner(context).run()
    return 0
