#!/usr/bin/env bash
set -euo pipefail

################################################################################################
# File: ~/x400-software-pack/.git/hooks/post-merge
# Author: Andreas
# Date: 20251126
# Purpose: Calls the copy_configs.sh in x400-software-pack to update printer.
#
# This script will be executed by git after git pull.
# It is a post-merge command from git. Normally the file needs to be in /x400-software-pack/.git/hooks.
# The .git folder is not pushed/piulle by git. So the copy_configs.sh creates a symling there which refers to this file.
# The output of the copy_configs.sh is stored in ~/x400-software-pack/git.-pist.merge.log
################################################################################################
echo "This is $(basename "$0")"
echo " "

# Go to repo root
cd "$(dirname "$0")/../../"

# Optional logging
LOG_FILE="./git-post-update.log"
echo "[$(date)] post-merge hook running..." >> "$LOG_FILE"

# Run your script
bash ./scripts/copy_configs.sh --auto >> "$LOG_FILE" 2>&1

echo "[$(date)] post-merge hook done." >> "$LOG_FILE"