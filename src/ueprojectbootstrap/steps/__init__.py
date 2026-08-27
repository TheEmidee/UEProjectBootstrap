from __future__ import annotations

import importlib
import inspect
import pkgutil
from pathlib import Path

from ueprojectbootstrap.steps.base import Step

__all__ = ["Step", "collect_steps"]


def collect_steps() -> list[Step]:
    """Discover every concrete Step subclass defined in this package and return
    instances sorted by their `order`."""

    steps: list[Step] = []
    package_dir = Path(__file__).parent

    for module_info in pkgutil.iter_modules([str(package_dir)]):
        if module_info.name == "base":
            continue

        module = importlib.import_module(f"{__name__}.{module_info.name}")

        for _, klass in inspect.getmembers(module, inspect.isclass):
            if klass.__module__ != module.__name__:
                continue
            if not issubclass(klass, Step) or klass is Step:
                continue
            if inspect.isabstract(klass):
                continue
            steps.append(klass())

    steps.sort(key=lambda step: step.order)
    return steps
