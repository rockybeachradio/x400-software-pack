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

# Variable definition
LOG_FILE="./git-post-update.log"

echo "[$(date)] post-merge hook running..." | tee -a "$LOG_FILE"

cd "$(dirname "$0")/../../"     # Go to repo root

bash ./scripts/copy_configs.sh --auto >> "$LOG_FILE" 2>&1 | tee -a "$LOG_FILE"      # Run script
result=$?   # capture exit status

# Check result and print to Mainsail + logfile
if [ $result -eq 0 ]; then
  echo "[x400-software-pack] ✅ copy_configs.sh --auto completed successfully. For detailes see git-post-update.log" | tee -a "$LOG_FILE"
else
  echo "[x400-software-pack] ❌ copy_configs.sh --auto FAILED (exit reason: $result). For details see git-post-update.log" | tee -a "$LOG_FILE"
fi

echo "[$(date)] post-merge hook done." | tee -a "$LOG_FILE"