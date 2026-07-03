"""Wires the context and the discovered steps together and runs the pipeline."""
from __future__ import annotations

from ue_bootstrap.context import Context
from ue_bootstrap.discovery import discover_command_classes


class Runner:
    def __init__(self, context: Context):
        self.context = context

    def run(self) -> None:
        command_classes = discover_command_classes()
        commands = [cls(self.context) for cls in command_classes]
        commands.sort(key=lambda command: command.get_step_number())

        for command in commands:
            command.run()
            if self.context.stop_reason:
                print(f"\nStopping: {self.context.stop_reason}")
                return

        print("\nDone.")
