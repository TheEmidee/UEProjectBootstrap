from __future__ import annotations

from abc import ABC, abstractmethod

from ueprojectbootstrap.context import BootstrapContext


class Step(ABC):
    @property
    @abstractmethod
    def order(self) -> int:
        raise NotImplementedError

    @abstractmethod
    def execute(self, context: BootstrapContext) -> None:
        raise NotImplementedError
