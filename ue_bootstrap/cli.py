"""Command line entry point.

Usage:
    python -m ue_bootstrap --project-name MyGame --target-folder D:/Projects --engine-version 5.7.4
"""
from __future__ import annotations

import argparse
from pathlib import Path
from typing import Optional, Sequence

from ue_bootstrap.context import Context
from ue_bootstrap.runner import Runner


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="ue_bootstrap",
        description="Bootstrap an Unreal Engine project as a native project of the engine sources.",
    )
    parser.add_argument(
        "--project-name", required=True,
        help="Name of the project to create.",
    )
    parser.add_argument(
        "--target-folder", required=True, type=Path,
        help="Folder in which the project (and the engine sources) will be created.",
    )
    parser.add_argument(
        "--engine-version", required=True,
        help="Unreal Engine version tag to bootstrap, e.g. 5.7.4",
    )
    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = build_arg_parser()
    args = parser.parse_args(argv)

    context = Context(
        project_name=args.project_name,
        target_folder=args.target_folder,
        engine_version=args.engine_version,
    )

    Runner(context).run()
    return 0
