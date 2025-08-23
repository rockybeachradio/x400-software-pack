#!/bin/bash
set -euo pipefail

################################################################################################
# File: install.sh
# Author: Andreas
# Date: 20250822
# Purpose:  Downlaod and Installaiton of x400-software-pack
#           Call the download_x400-software-pack.sh, install_software.sh, copy_config.sh, mcu_update.sh
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
# install required software
################################################################################################
echo "ℹ️  Start software installer (install_software.sh) ..."
cd "$REPO_DIR/scripts/"
./install_software.sh


################################################################################################
# copy config files
################################################################################################
echo "ℹ️  Start confoguration copy script (copy_configuration.sh) ..."
cd "$REPO_DIR/scripts/"
./copy_config.sh


echo "✅ Installation complete."
read -p "Restart required. Restart now? [Y/n]: " answer
answer=${answer:-N}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    sudo reboot
    exit 0
else
    echo "See you later."
fi
exit 0