# /// script
# dependencies = ["GitPython"]
# ///

import os
import pathlib
from git import Repo

script_dir = pathlib.Path(__file__).parent.resolve()
repo_root = script_dir.parent.parent.parent

def print_git_diagnostics(repo):
    for var in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE"):
        print(f"  {var}={os.environ.get(var, '<unset>')}")

    status = repo.git.status("--porcelain")
    print(f"  git status --porcelain:\n{status if status else '    <clean>'}")

def add_git_subtree(parent_folder, repository_url, destination_folder, branch):
    try:
        repo = Repo(repo_root)
        prefix = f"{parent_folder}/{destination_folder}"
        destination_path = repo_root / prefix

        (repo_root / parent_folder).mkdir(parents=True, exist_ok=True)

        print(f"Adding subtree for {repository_url}@{branch} at {destination_path}")
        print("Diagnostics before subtree add:")
        print_git_diagnostics(repo)

        repo.git.subtree(
            "add",
            f"--prefix={prefix}",
            repository_url,
            branch,
            "--squash"
        )

        print(f"Successfully added subtree {repository_url}@{branch} at {destination_path}")
    except Exception as e:
        print(f"Error: {e}")


print(f"Adding Git subtrees to repository {repo_root}")

subtrees = {
    "Plugins": [
        {
            "RepositoryUrl": "https://github.com/TheEmidee/UENamingConventionValidation.git",
            "DestinationFolder": "NamingConventionValidation",
            "Branch": "develop"
        }
    ]
}

for parent_folder, repositories in subtrees.items():
    for repository_info in repositories:
        add_git_subtree(
            parent_folder,
            repository_info["RepositoryUrl"],
            repository_info["DestinationFolder"],
            repository_info["Branch"]
        )
