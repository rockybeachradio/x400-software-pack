#!/usr/bin/env bash
set -euo pipefail

################################################################################################
# File: git_repo_reset.sh
# Author: Andreas
# Date: 20250827
# Purpose: Deleat local repo and override repo on GitHub
################################################################################################
#
# How to Call
#   git_repo_reset <repo_name> <local_dir> <github_username> [branch]"
#   git_repo_reset "my-repo" "/path/to/local/folder" "your-username" "main"
#  
# Behavior with an Empty GitHub Repository:
#   If the repository is empty (no commits or branches), the force-push creates the specified branch (e.g., main) with the initial README.md commit.
#   If it has content, the force-push overwrites all history and branches.
# Behavior if the GitHub Repository Doesn’t Exist:
#   The git push fails with repository not found. Create the repository on GitHub without initializing files, then rerun the script.

git_repo_reset() {
    local repo_name="$1"
    local local_dir="$2"
    local gh_user="$3"

    local branch="${4:-main}"
    local gh_ssh_host="github.com"
    local gh_ssh_user="git"
    local remote_url="git@$gh_ssh_host:$gh_user/$repo_name.git"
    local readme_file="README.md"
    local initial_commit_msg="Initial commit"

    # Check if Git is installed
    if ! command -v git &> /dev/null; then
        echo "Error: Git is not installed. Please install Git and try again."
        exit 1
    fi

    # Verify SSH authentication with GitHub
    echo "Verifying SSH authentication with GitHub..."
    if ! ssh -T "$gh_ssh_user@$gh_ssh_host" > /dev/null 2>&1; then
        echo "Error: SSH authentication failed. Please ensure your SSH key is added to GitHub and test with 'ssh -T $gh_ssh_user@$gh_ssh_host'."
        exit 1
    fi
    echo "SSH authentication successful."

    # Validate input parameters
    if [ -z "$gh_user" ]; then
        echo "Error: GitHub username is required."
        exit 1
    fi
    if [ -z "$repo_name" ]; then
        echo "Error: Repository name is required."
        exit 1
    fi
    if [ -z "$local_dir" ]; then
        echo "Error: Local directory path is required."
        exit 1
    fi

    # Confirm with user before proceeding
    echo "This script will reset the local Git repository in '$local_dir' and overwrite the GitHub repository '$gh_user/$repo_name' via SSH."
    echo "WARNING: This will delete ALL existing history and branches in the GitHub repository if it contains data."
    read -p "Are you sure you want to proceed? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi

    # Reset local repository
    echo "Resetting local repository in '$local_dir'..."
    cd "$local_dir" || { echo "Error: Cannot access directory '$local_dir'"; exit 1; }
    rm -rf .git
    git init
    echo "Local repository initialized."

    # Set up local repository to track remote using SSH
    echo "Setting up remote repository connection..."
    git remote add origin "$remote_url"

    # Create an initial commit
    echo "# $repo_name" > "$readme_file"
    git add "$readme_file"
    git commit -m "$initial_commit_msg"

    # Force-push to GitHub to overwrite remote repository
    echo "Force-pushing to GitHub to override '$gh_user/$repo_name'..."
    git branch -M "$branch"
    if ! git push -f origin "$branch"; then
        echo "Error: Failed to push to GitHub. Ensure the repository exists and you have push access."
        echo "Check SSH configuration and verify the repository URL: '$remote_url'."
        echo "If the repository does not exist, create it on GitHub (https://github.com/new) without initializing files."
        exit 1
    fi

    # Info to user
    echo "Setup complete! The GitHub repository '$remote_url' has been overridden with the new local repository."
    echo "To upload files to GitHub, use:"
    echo "  git add ."
    echo "  git commit -m 'Your commit message'"
    echo "  git push origin $branch"
} # End of function: git_repo_reset()
