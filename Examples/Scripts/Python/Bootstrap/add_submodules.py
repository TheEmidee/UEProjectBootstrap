# /// script
# dependencies = ["GitPython"]
# ///

import pathlib
from git import Repo

script_dir = pathlib.Path(__file__).parent.resolve()
repo_root = script_dir.parent.parent.parent

def add_git_submodule(submodule_owner, submodule_name):
    try:
        repo = Repo(repo_root)

        submodule_url = f"https://github.com/{submodule_owner}/{submodule_name}.git"
        path = f"Plugins/{submodule_name.replace('UE', '')}"
        
        print(f"Adding submodule to root: {repo_root}")
        repo.create_submodule(
            name=path.split('/')[-1],
            path=path,
            url=submodule_url
        )

        print(f"Successfully added {submodule_url} at {path}")
    except Exception as e:
        print(f"Error: {e}")


print(f"Adding Git submodules to repository {repo_root}")

submodules = {
    "YourCompany": [
        "UEPlugin1",
        "UEPlugin2"
        ],
    "TheEmidee" : [
        "UENamingConventionValidation",
        "UEGithubTools"
        ]
}

for owner, submodule_list in submodules.items():
    for submodule in submodule_list:
        add_git_submodule(owner, submodule)