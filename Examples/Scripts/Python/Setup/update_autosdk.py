# /// script
# dependencies = ["GitPython"]
# ///

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

from git import GitCommandError, InvalidGitRepositoryError, NoSuchPathError, Repo

AUTOSDK_REPOSITORY_URL = "https://github.com/FishingCactus/UEAutoSDK.git"
DEFAULT_AUTOSDK_ROOT = r"C:\UE\AutoSDK"
UE_SDKS_ROOT_ENV_VAR = "UE_SDKS_ROOT"


def ask_yes_no(question, default=False):
    suffix = " [Y/n] " if default else " [y/N] "
    answer = input(question + suffix).strip().lower()
    if not answer:
        return default
    return answer in ("y", "yes")


def get_engine_version():
    engine_version = os.environ.get("UE_BOOTSTRAP_ENGINE_VERSION")
    if engine_version:
        return engine_version

    # Fallback for when the script is run outside of the bootstrap/setup pipeline,
    # which is what normally sets UE_BOOTSTRAP_ENGINE_VERSION.
    repository_root = os.environ.get("UE_BOOTSTRAP_REPOSITORY_ROOT")
    if not repository_root:
        return None

    build_version_path = Path(repository_root) / "Engine" / "Build" / "Build.version"
    if not build_version_path.is_file():
        return None

    data = json.loads(build_version_path.read_text(encoding="utf-8"))
    return f"{data['MajorVersion']}.{data['MinorVersion']}"


def get_sdks_root_from_env():
    path = os.environ.get(UE_SDKS_ROOT_ENV_VAR)
    return Path(path) if path else None


def set_persistent_env_var(name, value):
    # setx only affects future processes, so the current process' environment is
    # updated separately for this script's own use.
    os.environ[name] = value
    try:
        subprocess.run(["setx", name, value], check=True, stdout=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, FileNotFoundError) as error:
        print(f"Warning: failed to persist environment variable {name}: {error}")


def prompt_for_sdks_root():
    answer = input(f"Where do you want the AutoSDK folder to be located? [{DEFAULT_AUTOSDK_ROOT}] ").strip()
    path = Path(answer) if answer else Path(DEFAULT_AUTOSDK_ROOT)
    set_persistent_env_var(UE_SDKS_ROOT_ENV_VAR, str(path))
    print(f"Set {UE_SDKS_ROOT_ENV_VAR} to '{path}'.")
    return path


def open_git_repository(path):
    try:
        return Repo(path)
    except (InvalidGitRepositoryError, NoSuchPathError):
        return None


def print_git_repository_state(repo):
    if repo.is_dirty(untracked_files=True):
        print(f"Warning: the AutoSDK repository at '{repo.working_dir}' has uncommitted changes.")
    else:
        print(f"The AutoSDK repository at '{repo.working_dir}' is clean.")

    if repo.head.is_detached:
        print(f"The AutoSDK repository at '{repo.working_dir}' is on a detached HEAD.")
    else:
        print(f"The AutoSDK repository at '{repo.working_dir}' is currently on branch '{repo.active_branch.name}'.")


def prepare_empty_folder(path):
    if not path.exists():
        path.mkdir(parents=True, exist_ok=True)
        return True

    contents = list(path.iterdir())
    if not contents:
        return True

    if not ask_yes_no(
        f"'{path}' exists and is not a git repository. Delete all its contents before cloning {AUTOSDK_REPOSITORY_URL}?"
    ):
        return False

    for entry in contents:
        if entry.is_dir():
            shutil.rmtree(entry)
        else:
            entry.unlink()

    return True


def clone_autosdk(path):
    if not prepare_empty_folder(path):
        return None

    print(f"Cloning {AUTOSDK_REPOSITORY_URL} into '{path}'...")
    return Repo.clone_from(AUTOSDK_REPOSITORY_URL, path)


def checkout_branch(repo, branch_name):
    try:
        repo.remotes.origin.fetch()
    except GitCommandError as error:
        print(f"Warning: failed to fetch from origin: {error}")

    try:
        repo.git.checkout(branch_name)
        print(f"Checked out branch '{branch_name}'.")
    except GitCommandError as error:
        print(f"Error: failed to checkout branch '{branch_name}': {error}")
        sys.exit(1)


def main():
    if not ask_yes_no("Do you want to update AutoSDK on this machine?"):
        print("Skipping AutoSDK update.")
        return

    engine_version = get_engine_version()
    if not engine_version:
        print("Error: could not determine the engine version. Aborting AutoSDK update.")
        sys.exit(1)

    branch_name = f"UE_{engine_version}"

    sdks_root = get_sdks_root_from_env()
    if sdks_root is None:
        print(f"{UE_SDKS_ROOT_ENV_VAR} is not set.")
        sdks_root = prompt_for_sdks_root()
    elif not sdks_root.is_dir():
        print(f"{UE_SDKS_ROOT_ENV_VAR} points to '{sdks_root}', which does not exist.")
        sdks_root = prompt_for_sdks_root()

    repo = open_git_repository(sdks_root) if sdks_root.exists() else None
    if repo is not None:
        print_git_repository_state(repo)
    else:
        repo = clone_autosdk(sdks_root)
        if repo is None:
            print("Aborting AutoSDK update.")
            return

    checkout_branch(repo, branch_name)


if __name__ == "__main__":
    main()
