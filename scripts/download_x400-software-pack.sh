#!/usr/bin/env bash
set -euo pipefail

################################################################################################
# File: download_x400-software-pack.sh
# Author: Andreas
# Date: 20250822
# Purpose: Download the x400-software-pack form GitHub and start the installer
#
################################################################################################


################################################################################################
## Variables
################################################################################################
FORCE_PULL=false    # script calle dwith -force_pull

######################################################
#Resolve repo root (parent of this script), then cd into it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR" || { echo "❌ x400-software-pack not found: $REPO_DIR"; exit 2; }


################################################################################################
# Get parameters
################################################################################################
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--force_pull)
      FORCE_PULL=true; shift ;;
    -h|--help)
      echo "Usage: $0 [--force_pull]"
      echo "  -f   Fetch remote and overwrite local changes (git reset --hard + clean)"
      exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Use --help for usage."; exit 0 ;;
  esac
done


################################################################################################
# Ask if force_pull is really wanted.
################################################################################################
if $FORCE_PULL; then
  echo "ℹ️  You selected force_pull. All local changes will be reset to the GitHub version."
  read -p "Do you want to run force_pull? [Y/n]: " answer
  answer=${answer:-N}     # default to "N" if empty
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    FORCE_PULL=true
  else
    FORCE_PULL=false
    echo "Lets continue normal"
  fi
fi


################################################################################################
# Upstream check
################################################################################################
# Ensure an upstream is configured (e.g., origin/master)
if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
  CURR_BRANCH=$(git symbolic-ref --short HEAD)        # Try to set upstream to origin/<current-branch>
  if git show-ref --verify --quiet "refs/remotes/origin/$CURR_BRANCH"; then
    git branch --set-upstream-to "origin/$CURR_BRANCH" >/dev/null
  else
    echo "❌ No upstream set and origin/$CURR_BRANCH doesn't exist. Aborting."
    exit 2
  fi
fi


################################################################################################
# Don’t pull over a dirty working tree
################################################################################################
if ! $FORCE_PULL; then
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "❌ Working tree has local changes:"
    git status --porcelain
    echo "ℹ️  Commit/stash them, or run: ./$(basename "$0") -force_pull"
    echo "force_pull will reset all local changes to the GitHub version."
    read -p "Do you want to run: force_pull? [Y/n]: " answer
    answer=${answer:-N}     # default to "N" if empty
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        FORCE_PULL=true
        echo "ℹ️  okay, lets forde_pull the new version form GitHub."
    else
        echo "ℹ️  Script willl exit now."
        exit 0
    fi
  fi
fi


################################################################################################
# Force pull from GitHub
################################################################################################
if $FORCE_PULL; then  # FORCE PULL: overwrite local changes with remote tracking branch
  echo "ℹ️  Force_pull latest from upstream and overwriting local changes..."
  git fetch --prune --quiet   # Download new files. Fetches new commits/refs from the remote GitHub and prunes deleted branches.
  git reset --hard @{u}       # Moves your current branch and your working directory to the upstream branch (@{u} = the configured upstream, e.g. origin/master).
  git clean -fd               # Deletes untracked files and directories (but leaves ignored ones).
  echo "✅ Repository was build up from scratch. Now in synce with GitHub Repo."
  exit 50
fi

################################################################################################
# Check for new Version on GitHub. If newer verison: Download it and execute update_printer.sh
################################################################################################
######################################################
# Get data
git fetch origin --quiet          # Fetch remote metadata

LOCAL=$(git rev-parse @)          # current local commit
REMOTE=$(git rev-parse @{u})      # Upstream-Commit (origin/master)
BASE=$(git merge-base @ @{u})     # gemeinsamer Vorfahre


if [[ "$LOCAL" == "$REMOTE" ]]; then
  echo "✅  Local Software Repo is up to date."
  exit 0
elif [[ "$LOCAL" == "$BASE" ]]; then
  echo "ℹ️  New version available. Downloading ..."
  git pull --ff-only                              # Fast-forward only (safer, no merge commit)
  exit 50                                         # 50 = Tells the calling script, that an download was performed.
elif [[ "$REMOTE" == "$BASE" ]]; then
  echo "ℹ️  Your local version is ahead of the remote version. To go back to last stable version delet the current x400-software-pack and follow the installation instruction."
  exit 3
else
  echo "❌ Local and remote have diverged. Resolve manually: $ $(basename "$0") -force_pull)."
  exit 2
fi
exit 0