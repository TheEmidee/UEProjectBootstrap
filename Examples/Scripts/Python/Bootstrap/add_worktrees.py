# /// script
# dependencies = ["GitPython"]
# ///

import pathlib
from git import Repo

script_dir = pathlib.Path(__file__).parent.resolve()
repo_root = script_dir.parent.parent.parent
worktree_repos_dir = repo_root / ".worktree-repos"

def add_git_worktree(parent_folder, repository_url, destination_folder, branch):
    try:
        repository_name = pathlib.PurePosixPath(repository_url).stem
        bare_repo_path = worktree_repos_dir / repository_name
        destination_path = repo_root / parent_folder / destination_folder

        if bare_repo_path.is_dir():
            bare_repo = Repo(bare_repo_path)
            print(f"Fetching {repository_url}...")
            bare_repo.remotes.origin.fetch()
        else:
            print(f"Cloning {repository_url} as bare repository to {bare_repo_path}...")
            worktree_repos_dir.mkdir(parents=True, exist_ok=True)
            bare_repo = Repo.clone_from(repository_url, bare_repo_path, bare=True)

        destination_path.parent.mkdir(parents=True, exist_ok=True)

        print(f"Adding worktree for {repository_name}@{branch} at {destination_path}")
        bare_repo.git.worktree(
            "add",
            "-B", branch,
            str(destination_path),
            f"origin/{branch}"
        )

        print(f"Successfully added worktree {repository_url}@{branch} at {destination_path}")
    except Exception as e:
        print(f"Error: {e}")


print(f"Adding Git worktrees to repository {repo_root}")

worktrees = {
    "Plugins": [
        {
            "RepositoryUrl": "https://github.com/TheEmidee/UENamingConventionValidation.git",
            "DestinationFolder": "NamingConventionValidation",
            "Branch": "develop"
        }
    ]
}

for parent_folder, repositories in worktrees.items():
    for repository_info in repositories:
        add_git_worktree(
            parent_folder,
            repository_info["RepositoryUrl"],
            repository_info["DestinationFolder"],
            repository_info["Branch"]
        )
