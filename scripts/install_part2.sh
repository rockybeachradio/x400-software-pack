#!/bin/bash
set -euo pipefail

################################################################################################
# File: install.sh
# Author: Andreas
# Date: 20250925
# Purpose:  Start this to install the x400-software-pack
#           Calls the: download_x400-software-pack.sh, install_software.sh, copy_config.sh
#
################################################################################################
echo "This is $(basename "$0")"
echo " "

################################################################################################
# Variables
################################################################################################
#Resolve repo root (parent of this script), then cd into it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR" || { echo "❌ x400-software-pack not found: $REPO_DIR"; exit 1; }
echo " "

################################################################################################
# install required software part 2
################################################################################################
echo "ℹ️  Start software installer (install_software_2.sh) ..."
"$REPO_DIR/scripts/install_software_2.sh"
echo " "

################################################################################################
# copy config files
################################################################################################
echo "ℹ️  Start configuration copy script (copy_configs.sh) ..."
"$REPO_DIR/scripts/copy_configs.sh" -i  || echo "❌  Faild: Starting copy_configs.sh"
echo " "

################################################################################################
# Update MCUs
################################################################################################
echo "ℹ️  The following script only works if Katapult is already installed on the SKIPR MCU and the toolehaead MCU."
read -p "❓ Install/Update Klipper firmware on the MCUs? [y/N]: " answer
answer=${answer:-N}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
  "$REPO_DIR/scripts/mcu_update_all.sh"  || echo "❌  Faild: Starting mcu_update_all.sh"
else
  echo "... okay"
fi
echo " "


################################################################################################
# End
################################################################################################
echo "✅ Installation complete."
read -p "❓ Restart required. Restart now? [Y/n]: " answer
answer=${answer:-Y}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    sudo reboot
else
    echo "See you later."
fi

exit 0