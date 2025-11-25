#!/usr/bin/bash
set -euo pipefail

################################################################################################
# File: call_copy_configs-auto.sh
# Author: Andreas
# Date: 20250925
# Purpose: Calls the copy_configs.sh schript with --auto
# Needed for Moonraker Update-Manager
################################################################################################
echo "This is $(basename "$0")"
echo " "

################################################################################################
# Variables
################################################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source_base=$REPO_DIR
config_source="$REPO_DIR""/configurations"

config_destination="$HOME""/printer_data/config"

SCRIPT="$REPO_DIR/scripts/copy_configs.sh"

################################################################################################
# calling the script
################################################################################################
###############################################
# Safety checks
if [[ ! -f "$SCRIPT" ]]; then
    echo "ERROR: copy_configs.sh not found at $SCRIPT"
    exit 1
fi

if [[ ! -x "$SCRIPT" ]]; then
    echo "Making copy_configs.sh executable..."
    chmod +x "$SCRIPT"
fi

echo "Running copy_configs.sh in AUTO mode"
echo "Repo directory: $REPO_DIR"
echo "Executing: $SCRIPT --auto"
echo

###############################################
# Call the script
bash "$SCRIPT" --auto

exit $?