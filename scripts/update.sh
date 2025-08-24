#!/bin/bash
set -euo pipefail

################################################################################################
# File: update.sh
# Author: Andreas
# Date: 20250822
# Purpose:  Update the x400-software-pack
#           Update Linux
#           Call the download_x400-software-pack.sh, copy_config.sh, mcu_update.sh
#
################################################################################################


################################################################################################
# Variables
################################################################################################
rc=""      # Return code  Variable for exit code of a called shell script

#Resolve repo root (parent of this script), then cd into it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR" || { echo "❌ x400-software-pack not found: $REPO_DIR"; exit 1; }


################################################################################################
# Update Linux
################################################################################################
echo "ℹ️  Updating Linux, components and software ..."
sudo apt update
sudo apt upgrade


################################################################################################
# download x400-software-pack
################################################################################################
echo "ℹ️  Start update check & download script (download_x400-software-pack) ..."
cd "$REPO_DIR/scripts/"
./download_x400-software-pack.sh || rc=$?
rc=$?       #capture exit code from script above (0 = new version was downloaded from GitHub, 5 = no newer verison on GitHub)

if [[ $rc -ne 0 && $rc -ne 5 ]]; then
  echo "❌  Stop update. (download_x400-software-pack exit with $rc)"
  exit 1
fi


################################################################################################
# copy config files
################################################################################################
echo "ℹ️  Start configuration copy script (copy_configs.sh) ..."
cd "$REPO_DIR/scripts/"
bash "$REPO_DIR/scripts/copy_configs.sh"


################################################################################################
# Update the MCUs
################################################################################################
echo "ℹ️  Start script to update all MCUs (mcu_update_all.sh) ..."
cd "$REPO_DIR/scripts/"
bash "$REPO_DIR/scripts/mcu_update_all.sh"


################################################################################################
# End
################################################################################################
echo "✅ update.sh complete"
read -p "❓ Restart required. Restart now? [Y/n]: " answer
answer=${answer:-N}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    sudo reboot
    exit 0
else
    echo "See you later."
fi
exit 0