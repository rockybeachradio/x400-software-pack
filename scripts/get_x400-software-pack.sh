#!/usr/bin/env bash
set -euo pipefail

################################################################################################
# File: get_x400-software-pack.sh
# Author: Andreas
# Date: 20250821
# Purpose: Download the x400-software-pack form GitHub and start the installer
#
################################################################################################


################################################################################################
# Variables
REPO_DIR="$HOME/x400-software-pack"
cd "$REPO_DIR" || { echo "❌ x-400-software-pack not found: $REPO_DIR"; exit 1; }

## Resolve repo root (parent of this script), then cd into it
#REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
#cd "$REPO_DIR" || { echo "❌ x400-software-pack not found: $REPO_DIR"; exit 1; }

################################################################################################
# Get parameters
FORCE_PULL=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -force-pull|--force-pull)
      FORCE_PULL=true; shift ;;
    -h|--help)
      echo "Usage: $0 [--force-pull]"
      echo "  --force-pull   Fetch remote and overwrite local changes (git reset --hard + clean)"
      exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Use --help for usage."; exit 1 ;;
  esac
done


################################################################################################
# Upstream check
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
# Force pull from GIT
if $FORCE_PULL; then  # FORCE PULL: overwrite local changes with remote tracking branch
  echo "ℹ️  Force-pulling latest from upstream and overwriting local changes..."
  git fetch --prune --quiet
  # Hard reset to upstream and remove untracked (but keep ignored files)
  git reset --hard @{u}
  git clean -fd
  echo "✅ Repository synced to upstream."

  # Make scripts executable (safer than 777)
  if [[ -d "$REPO_DIR/scripts" ]]; then
    find "$REPO_DIR/scripts" -type f -name '*.sh' -print0 | xargs -0 chmod +x || true
  fi

  if [[ -x "./update_printer.sh" ]]; then           # tests whether the file exists and has the executable permission
    echo "ℹ️ Starting printer update ..."
    ./update_printer.sh
    echo "✅ Printer update completed."
  elif [[ -f "./update_printer.sh" ]]; then         # If file found but not executable
    echo "ℹ️ Start printer update via bash ..."     # run explicity with bash
    bash ./update_printer.sh
    echo "✅ Printer update completed."
  else
    echo "❌ update_printer.sh not found. Please try again."
  fi
  exit 0
fi


#############################################################
# Don’t pull over a dirty working tree
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "❌ Working tree has local changes. Commit or stash before updating."
  echo "ℹ️ Or force the git pull with $ get_x400-software-pack.sh -force-pull"
  exit 3
fi

#############################################################
# Get data
git fetch origin --quiet          # Fetch remote metadata

LOCAL=$(git rev-parse @)          # current local commit
REMOTE=$(git rev-parse @{u})      # Upstream-Commit (origin/master)
BASE=$(git merge-base @ @{u})     # gemeinsamer Vorfahre


#############################################################
# Check for new Version on GitHub. If newer verison: Download it and execute update_printer.sh
if [[ "$LOCAL" == "$REMOTE" ]]; then
  echo "✅  Local Software Repo is up to date."
  exit 0
elif [[ "$LOCAL" == "$BASE" ]]; then
  echo "ℹ️ Newe version available. Downloading ..."
  git pull --ff-only                              # Fast-forward only (safer, no merge commit)
  
  #chmod -Rf 777 "$REPO_DIR""/scripts/"          # make miles executable executable
  if [[ -d "$REPO_DIR/scripts" ]]; then
    find "$REPO_DIR/scripts" -type f -name '*.sh' -print0 | xargs -0 chmod +x || true
  fi
  echo "✅ Download complete."

  #############################################################
  if [[ -x "./update_printer.sh" ]]; then           # tests whether the file exists and has the executable permission
    echo "ℹ️ Starting printer update ..."
    ./update_printer.sh
    echo "✅ Printer update completed."
  elif [[ -f "./update_printer.sh" ]]; then                # If file found but not executable
    echo "ℹ️ Start printer update via bash ..."     # run explicity with bash
    bash ./update_printer.sh
    echo "✅ Printer update completed."
  else
    echo "❌ update_printer.sh not found. Please try again."
  fi
  exit 0

elif [[ "$REMOTE" == "$BASE" ]]; then
  echo "ℹ️ Your local version is ahead of the remote version. To go back to last stable version delet the current x400-software-pack and follow the installation instruction."
  exit 0
else
  echo "❌ Local and remote have diverged. Resolve manually (e.g., 'git pull --rebase')."
  exit 4
fi