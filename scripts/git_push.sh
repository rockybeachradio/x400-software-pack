#!/usr/bin/env bash

################################################################################################
# File: git_push.sh
# Author: ChatGPT & Andreas
# Date: 20250821
# Purpose: Update the GitHub repo with changes in local repo folder
################################################################################################

################################################################################################
# Manually update repo on GitHub
################################################################################################
# Update repo
#   git status                          # reports the status of stage, repo, etc.
#   git add -A                          # looks for changes in all directories.
#   git commit -m "$commit_comment"     # set a commit with comment. determiens which files were changed.
#   git push -u origin main             # Push changes to GitHub: main branch
#
# Set a tag
#   git tag -a v1.0.0 -m "Erstes Release"      # Create a tag with version and comment
#   git push origin v1.0.0                     # Push tag to GitHub. Current commit will be tagged
#
# Create a release
#   GitHub → Repo → Releases → Draft a new release.
#   Chosse the tag which will be the base for the realease


################################################################################################
# Error handling
################################################################################################
set -euo pipefail                                   # Definiert Abbruchkriterien für Skript:
                                                    # set -e - Wenn ein Befehl fehlschlägt.
                                                    # set -u - Wenn eine nicht gesetzte Variable verwendet wird.
                                                    # set -o pipefail - Bei Befehlen mit Pipe (|) wir der erste Fehler im Pipeline-Verlauf erkannt.
error_exit() { echo "! ERROR: $1" >&2; exit 1; }    # Funktion error_exit: Shows an error message and EXIT the script. error_exit is called whenever an error in the script occures


################################################################################################
# Varibale declaration
################################################################################################
SOURCE="$HOME/OneDrive\ -\ privat/Heimwerken\ 3D\ druck/Eryone\ Thinker\ x400/6\ Firmware/x400-software-pack"                       # Name of the Service which will be stopped / started
REMOTE="origin"
BRANCH=""
COMMENT=""
TAG=""
TAG_MESSAGE=""

################################################################################################
# shell help output
################################################################################################
usage() {
  cat <<EOF

This script uploads a local repo folder to the GitHub repo.

Usage: $(basename "$0") -m|--comment "message" [-r|--remote origin] [-b|--branch current [-t|--tag "version_number"] [-T|--tag-message "message"]
  -m, --comment       Commit message (required)
  -r, --remote        Remote name (default: origin)
  -b, --branch        Branch name (default: current branch)
  -t, --tag           Tag name to create/push (e.g., v1.0.0)
  -T, --tag-message   Tag message (default: commit message, else "Release <tag>") (required if -t is set)

Examples:
  ./$(basename "$0") -m "your commit message here"
  ./$(basename "$0") -m "Initial import (skip '0 git repos')" -b main -t "v1.0.0" -T "first tag"
  
The script can be in the root or in a subdirectory of the local repo folder.
Make the script executable before first run: $ chmod +x bit_push.sh

EOF
}


################################################################################################
# Get input parameters
################################################################################################
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--comment) COMMENT="${2:-}"; shift 2;;       # case "$1" in -m|--comment) matches the current flag ($1) when it’s -m or --comment. COMMENT="${2:-}" stores the next argument ($2) as the comment. The ${2:-} form is safe with set -u (it substitutes an empty string if $2 is unset). shift 2 drops the flag and its value from the argument list so the loop can continue with the next option.
    -r|--remote)  REMOTE="${2:-}";  shift 2;;
    -b|--branch)  BRANCH="${2:-}";  shift 2;;
    -t|--tag)     TAG="${2:-}";     shift 2;;
    -T|--tag-message) TAG_MESSAGE="${2:-}"; shift 2;;
    -h|--help)    usage; exit 0;;
    *) echo "Unknown argument: $1"; usage; exit 1;;
  esac
done

if [[ -z "$COMMENT" ]]; then
  echo "❌ Error: a commit message is required (-m|--comment)."
  usage
  exit 1
fi
if [[ -n "$TAG" && -z "$TAG_MESSAGE" ]]; then
    echo "❌ Error: if tag is set, a tag comment message is required (-T|--tag-comment)."
    usage
    exit 1
fi


################################################################################################
# Preconditions: check & set
################################################################################################
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a Git repository."
  exit 1
fi
REPO_ROOT="$(git rev-parse --show-toplevel)"   # Asks Git for the absolute path to the top-level directory of the current working tree. Saves that path in a variable. The quotes ensure paths with spaces work.
pushd "$REPO_ROOT" >/dev/null                  # Changes directory to the repo root and pushes the previous directory onto a directory stack (so you can easily go back later with popd). Suppresses pushd’s usual output (it prints the directory stack).
trap 'popd >/dev/null' EXIT                     # always return, even on error


if [[ -z "${BRANCH}" ]]; then
  BRANCH="$(git rev-parse --abbrev-ref HEAD)"
fi

# Ensure .gitignore excludes "0 git repos"
touch .gitignore
if ! grep -qxF '0 git repos/' .gitignore; then
  echo '0 git repos/' >> .gitignore
  echo "Added '0 git repos/' to .gitignore"
fi

## If that folder was ever tracked, untrack it (keep files locally)
#if git ls-files --cached -- "0 git repos" "0 git repos/*" | grep -q .; then
#  git rm -r --cached "0 git repos" || true
#  echo "Removed '0 git repos' from Git index (kept locally)."
#fi


################################################################################################
# Stage
################################################################################################
git add -A      # Use git add -A when you want a complete, repo-wide snapshot (new, modified and deleted files), no matter where you run the command from.


################################################################################################
# Commit
################################################################################################
if git diff --cached --quiet; then
  echo "No staged changes to commit; will pull/push anyway."
else
  git commit -m "$COMMENT"
fi


################################################################################################
# Rebase on remote (if upstream exists)
################################################################################################
if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
  git pull --rebase --autostash   # Rebase local branch on its upstream and autostash uncommitted changes
else
  echo "No upstream set for '$BRANCH'. Will set upstream on first push."
fi


################################################################################################
# Create/verify tag
################################################################################################
if [[ -n "$TAG" ]]; then
  if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then    # Checks if local tag with that exact name already exists.
    echo "❌ Tag '$TAG' already exists locally; will push it as-is."
  else
    # Choose tag message
    if [[ -z "$TAG_MESSAGE" ]]; then
      if [[ -n "$COMMENT" ]]; then
        TAG_MESSAGE="$COMMENT"
      else
        TAG_MESSAGE="Release $TAG"
      fi
    fi
    git tag -a "$TAG" -m "$TAG_MESSAGE"
    echo "Created annotated tag '$TAG'."
  fi
fi


################################################################################################
# Push (set upstream if needed)
################################################################################################
set +e      # Turn off Bash’s “exit on error” mode
if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
  git push
  PUSH_RC=$?
else
  git push -u "$REMOTE" "$BRANCH"
  PUSH_RC=$?
fi
set -e      # Turn on Bash’s “exit on error” mode


################################################################################################
# Fallback: push failed → create a PR branch instead
################################################################################################
if [[ $PUSH_RC -ne 0 ]]; then
  echo "Primary push failed. This can happen with protected 'main' or insufficient rights."
  # Fallback: push the same commit to a new feature branch so you can open a PR
  FB="feature/auto-$(date +%Y%m%d%H%M%S)"     # timestamped to avoid collisions
  echo "Creating and pushing fallback branch: $FB"
  git branch "$FB"
  git push -u "$REMOTE" "$FB" || {
    echo "❌ Fallback push also failed. Check your permissions or authentication (PAT/SSH)."
    exit 1
  }
  echo "Pushed to '$FB'. Open a Pull Request on GitHub to merge."
else
  echo "✅ Successfully updated '$BRANCH' on '$REMOTE'."
fi


################################################################################################
# Push tag (if requested)
################################################################################################
if [[ -n "$TAG" ]]; then
  git push "$REMOTE" "$TAG" || error_exit "Failed to push tag '$TAG'."
  echo "🏷️  Pushed tag '$TAG'."


################################################################################################
# Print URL to draft a release on GitHub if remote is GitHub
################################################################################################
  REMOTE_URL="$(git config --get "remote.$REMOTE.url" || true)"
  if [[ "$REMOTE_URL" =~ github\.com[:/]+([^/]+)/([^/.]+)(\.git)?$ ]]; then
    OWNER="${BASH_REMATCH[1]}"; REPO="${BASH_REMATCH[2]}"
    echo "➡️  To draft a release go to: https://github.com/$OWNER/$REPO/releases/new?tag=$TAG"
  fi
fi