#!/bin/bash
set -euo pipefail

################################################################################################
# File: update.sh
# Author: Andreas
# Date: 20250822
# Purpose: Call the download and update scripts
#
################################################################################################

################################################################################################
# Variables
################################################################################################
dl=""      # Variable: (50 = new version was downloaded from GitHub)

#Resolve repo root (parent of this script), then cd into it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR" || { echo "❌ x400-software-pack not found: $REPO_DIR"; exit 1; }


################################################################################################
# download x400-software-pack
################################################################################################
echo "Check for updates ..."
cd "$REPO_DIR/scripts/"
./download_x400-software-pack.sh
de=$?       #capture exit code from script above (50 = new version was downloaded from GitHub)

################################################################################################
# install required software
################################################################################################
cd "$REPO_DIR/scripts/"
./install_software.sh


################################################################################################
# copy config files
################################################################################################
cd "$REPO_DIR/scripts/"
./copy_config.sh


################################################################################################
# Update the MCUs
################################################################################################
read -p "Shall the MCUs be updated? [Y/n]: " answer
answer=${answer:-N}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Installing MCU updates ..."
    "./""$HOME""/x400-software-pack/scripts/mcu_update.sh -x linux"                 # Update Linux MCU
    "./""$HOME""/x400-software-pack/scripts/mcu_update.sh -x baord_mcu"             # Update SKIPR MCU
    "./""$HOME""/x400-software-pack/scripts/mcu_update.sh -x toolhead_mcu"          # Update RP2040 MCU
    #"./""$HOME""/x400-software-pack/scripts/mcu_update.sh -x toolehad_sensor"       # Update Sensor on RP2040
else
    echo "Please do it later."
fi

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