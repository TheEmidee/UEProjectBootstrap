"""Finds every concrete, top-level Command class in the `steps` package."""
from __future__ import annotations

import importlib
import inspect
import pkgutil
from typing import List, Type

from ue_bootstrap import steps as steps_package
from ue_bootstrap.command import Command, SubCommand


def discover_command_classes() -> List[Type[Command]]:
    """
    Import every module in ue_bootstrap/steps and collect the Command
    subclasses defined directly in it (not imported from elsewhere, not
    SubCommand subclasses, not abstract).
    """
    command_classes: List[Type[Command]] = []

    for _, module_name, _ in pkgutil.iter_modules(steps_package.__path__):
        module = importlib.import_module(f"{steps_package.__name__}.{module_name}")

        for _, obj in inspect.getmembers(module, inspect.isclass):
            if obj in (Command, SubCommand):
                continue
            if not issubclass(obj, Command):
                continue
            if issubclass(obj, SubCommand):
                continue  # sub-commands are wired up by their parent, not discovered
            if inspect.isabstract(obj):
                continue
            if obj.__module__ != module.__name__:
                continue  # skip classes merely imported into this module
            command_classes.append(obj)

    return command_classes
