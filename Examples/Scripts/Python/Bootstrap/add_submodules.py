# /// script
# dependencies = ["GitPython"]
# ///

import pathlib
from git import Repo

script_dir = pathlib.Path(__file__).parent.resolve()
repo_root = script_dir.parent.parent.parent

def add_git_submodule(parent_folder, repository_url, destination_folder):
    try:
        repo = Repo(repo_root)

        path = f"{parent_folder}/{destination_folder}"

        print(f"Adding submodule to root: {repo_root}")
        repo.create_submodule(
            name=destination_folder,
            path=path,
            url=repository_url
        )

        print(f"Successfully added {repository_url} at {path}")
    except Exception as e:
        print(f"Error: {e}")


print(f"Adding Git submodules to repository {repo_root}")

submodules = {
    "Plugins": [
        {
            "RepositoryUrl": "https://github.com/TheEmidee/UENamingConventionValidation.git",
            "DestinationFolder": "NamingConventionValidation"
        },
        {
            "RepositoryUrl": "https://github.com/TheEmidee/UEGithubTools.git",
            "DestinationFolder": "GithubTools"
        }
    ]
}

for parent_folder, repositories in submodules.items():
    for repository_info in repositories:
        add_git_submodule(
            parent_folder,
            repository_info["RepositoryUrl"],
            repository_info["DestinationFolder"]
        )