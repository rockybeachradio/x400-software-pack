#!/usr/bin/env bash
set -euo pipefail

################################################################################################
# File: get_x400-software-pack.sh
# Author: Andreas
# Date: 20250819
# Purpose: Download the x400-software-pack form GitHub and start the installer
#
################################################################################################


################################################################################################
# Variables
REPO_DIR="$HOME""/x400-software-pack"
cd "$REPO_DIR" || { echo "x-400-software-pack not found: $REPO_DIR"; exit 1; }


################################################################################################
# Upstream check
# Ensure an upstream is configured (e.g., origin/master)
if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
  CURR_BRANCH=$(git symbolic-ref --short HEAD)        # Try to set upstream to origin/<current-branch>
  if git show-ref --verify --quiet "refs/remotes/origin/$CURR_BRANCH"; then
    git branch --set-upstream-to "origin/$CURR_BRANCH" >/dev/null
  else
    echo "No upstream set and origin/$CURR_BRANCH doesn't exist. Aborting."
    exit 2
  fi
fi

# Don’t pull over a dirty working tree
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree has local changes. Commit or stash before updating."
  exit 3
fi


################################################################################################
# get variables / information
git fetch origin --quiet          # Fetch remote metadata

LOCAL=$(git rev-parse @)          # current local commit
REMOTE=$(git rev-parse @{u})      # Upstream-Commit (origin/master)
BASE=$(git merge-base @ @{u})     # gemeinsamer Vorfahre


################################################################################################
# Check for new Version on GitHub. If newer verison: Download it and execute installer.sh
if [[ "$LOCAL" == "$REMOTE" ]]; then
  echo "Local Software Repo is up to date."
  exit 0
elif [[ "$LOCAL" == "$BASE" ]]; then
  echo "There is a newer version available. Downloading ..."
  git pull --ff-only                            # Fast-forward only (safer, no merge commit)
  chmod -Rf 777 "$REPO_DIR""/scripts/"          # make miles executable executable
  echo "Download complete."

  if [[ -x "./install.sh" ]]; then              # tests whether the file exists and has the executable permission
    echo "Starting installer ..."
    ./update_printer.sh
    echo "Instalaltion completed."
  elif [[ -f "./install.sh" ]]; then            # If file found but not executable
    echo "RStarting installer via bash ..."     # run explicity with bash
    bash ./update_printer.sh
    echo "Instalaltion completed."
  else
    echo "update_printer.sh not found. Please try again."
  fi

  exit 0

elif [[ "$REMOTE" == "$BASE" ]]; then
  echo "Your local version is ahead of the remote version. To go back to last stable version delet the current x400-software-pack and follow the installation instruction."
  exit 0
else
  echo "Local and remote have diverged. Resolve manually (e.g., 'git pull --rebase')."
  exit 4
fi