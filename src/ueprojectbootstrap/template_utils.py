from __future__ import annotations

from importlib import resources
from pathlib import Path

_TEMPLATES_ANCHOR = "ueprojectbootstrap"


def read_template(name: str) -> str:
    return resources.files(_TEMPLATES_ANCHOR).joinpath("templates", name).read_text(encoding="utf-8")


def render_template(name: str, tokens: dict[str, str]) -> str:
    content = read_template(name)
    for key, value in tokens.items():
        content = content.replace(f"@{key}@", value)
    return content


def write_file(destination: Path, content: str, *, force: bool) -> bool:
    if destination.exists() and not force:
        print(f"File {destination} already exists. Skipping.")
        return False

    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(content, encoding="utf-8", newline="\n")
    print(f"Wrote {destination}")
    return True
