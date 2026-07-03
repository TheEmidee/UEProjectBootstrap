"""Base classes every bootstrap step is built on."""
from __future__ import annotations

from abc import ABC, abstractmethod
from typing import List, Union

from ue_bootstrap.context import Context

StepNumber = Union[int, float, str]


class Command(ABC):
    """
    Base class for a single bootstrap step.

    Concrete steps live in the `steps/` package, one class per file, and are
    discovered automatically (see `discovery.py`). They run in ascending
    `get_step_number()` order.

    A command can own sub-commands (see `get_sub_commands`) which run right
    after its own `execute()`, in list order. Sub-commands must subclass
    `SubCommand` so they aren't picked up by auto-discovery themselves.
    """

    def __init__(self, context: Context):
        self.context = context
        self._sub_commands: List["Command"] = self.get_sub_commands()

    # ---- required overrides ----------------------------------------------

    @abstractmethod
    def get_step_number(self) -> StepNumber:
        """Order relative to the other steps at the same level."""

    @abstractmethod
    def get_step_name(self) -> str:
        """Human readable name, printed before the step runs."""

    @abstractmethod
    def execute(self) -> None:
        """Actual work for the step. Only called if `should_bypass()` is False."""

    # ---- optional overrides ------------------------------------------------

    def should_bypass(self) -> bool:
        """
        Return True if this step has already been done and can be skipped.
        Lets the module be re-run safely on a partially bootstrapped project.
        """
        return False

    def ask_user(self) -> None:
        """Prompt the user for anything this step needs. No-op by default."""
        return None

    def get_sub_commands(self) -> List["Command"]:
        """Optional sub-commands, instantiated once with the same context."""
        return []

    # ---- orchestration -------------------------------------------------------

    def run(self) -> None:
        print(f"\n[Step {self.get_step_number()}] {self.get_step_name()}")

        if self.should_bypass():
            print("  -> already done, skipping")
            return

        self.ask_user()
        self.execute()

        for sub_command in self._sub_commands:
            sub_command.run()
            if self.context.stop_reason:
                return


class SubCommand(Command):
    """
    Marker base class for sub-commands.

    Sub-commands are never picked up by auto-discovery: they only ever get
    run because their parent `Command` returns them from `get_sub_commands()`.
    """
