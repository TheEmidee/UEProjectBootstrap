"""Static values used by the steps. Nothing here should come from user input."""

# Python version installed into the project's venv via `uv python install`.
PYTHON_VERSION = "3.11.8"

# EpicGames/UnrealEngine is a private repo - you need a GitHub account linked
# to your Epic Games account, AND to authenticate the download (the plain
# https://github.com/.../archive/... URL only works in a browser session that
# is already logged in). If the EPIC_GITHUB_TOKEN environment variable is set,
# step 3 will send it as a bearer token when downloading.
ENGINE_DOWNLOAD_URL_TEMPLATE = (
    "https://github.com/EpicGames/UnrealEngine/archive/refs/tags/{version}-release.zip"
)

# Packages installed into the project's venv (step 6d).
PIP_PACKAGES = [
    "UEPyScripts==1.2.7",
    "GameDevTools==1.1.0",
    "JenkinsfileGenerator==1.12.0",
]

# uv's official installers.
UV_INSTALL_CMD_WINDOWS = [
    "powershell", "-ExecutionPolicy", "Bypass", "-Command",
    "irm https://astral.sh/uv/install.ps1 | iex",
]
UV_INSTALL_CMD_UNIX = ["/bin/sh", "-c", "curl -LsSf https://astral.sh/uv/install.sh | sh"]

# Extra arguments applied when creating/populating the venv with uv.
UV_VENV_EXTRA_ARGS = ["--link-mode=copy", "--upgrade"]

PRE_COMMIT_VERSION = "3.7.0"

RESOURCES_DIR_NAME = "resources"
TEMPLATES_DIR_NAME = "templates"
REQUIREMENTS_FILENAME = "requirements.txt"

# filename -> template resource name, used by step 7 and step 8.
TEMPLATE_FILES = {
    "pre_commit_config": ".pre-commit-config.yaml",
    "lfsconfig": ".lfsconfig",
    "gitattributes": ".gitattributes",
    "gitignore": ".gitignore",
    "clang_format": ".clang-format",
}
