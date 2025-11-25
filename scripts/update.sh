#!/bin/bash
set -euo pipefail

################################################################################################
# File: update.sh
# Author: Andreas
# Date: 20250925
# Purpose:  Update the x400-software-pack
#           Calls the: download_x400-software-pack.sh, copy_config.sh, mcu_update.sh
#
################################################################################################
echo "This is $(basename "$0")"
echo " "


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
read -p "❓Update Linux, components and software? [Y/n]: " answer
answer=${answer:-Y}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "ℹ️  Updating Linux, components and software ..."
    sudo apt update
    sudo apt upgrade -y
    # sudo apt full-upgrade -y      # install new dependencies
fi
echo " "


################################################################################################
# Check for new x400-software-pack version on GitHub repo
################################################################################################
echo "ℹ️  Start update check & download script (download_x400-software-pack) ..."
cd "$REPO_DIR/scripts/"  || echo "❌  Faild: Go to scripts folder"
"$REPO_DIR/scripts/download_x400-software-pack.sh" || rc=$? || error_exit "❌  Faild: Starting download_x400-software-pack.sh"
rc=$?       #capture exit code from script above (0 = new version was downloaded from GitHub, 5 = no newer verison on GitHub)

if [[ $rc -ne 0 && $rc -ne 5 ]]; then
  echo "❌  Stop update. (download_x400-software-pack exit with $rc)"
  exit 1
fi
echo " "


################################################################################################
# Copy config files
################################################################################################
echo "ℹ️  Start configuration copy script (copy_configs.sh) ..."
cd "$REPO_DIR/scripts/"  || echo "❌  Faild: Go to scripts folder"
bash "$REPO_DIR/scripts/copy_configs.sh"   || echo "❌  Faild: Starting copy_configs.sh"
echo " "


################################################################################################
# Update the MCUs
################################################################################################
if [ "execute" = "no" ]; then # Auskommentierung --> Needs to be implemented
echo "ℹ️  Start script to update all MCUs (mcu_update_all.sh) ..."
cd "$REPO_DIR/scripts/"  || echo "❌  Faild: Go to scripts folder"
bash "$REPO_DIR/scripts/mcu_firmware_update_all.sh"   || echo "❌  Faild: Starting mcu_update_all.sh"
fi # Auskommentierung
echo " "


################################################################################################
# Info
################################################################################################
echo "ℹ️  Use also Mainsail to update printer software."
echo " "


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