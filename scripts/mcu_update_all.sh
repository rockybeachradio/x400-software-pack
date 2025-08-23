#!/usr/bin/env bash
set -euo pipefail

################################################################################################
# File: mcu_update_all.sh
# Author: Andreas
# Date: 20250822
# Purpose: Calls the muc_update.sh for each MCU.
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
# Update the MCUs
################################################################################################
read -p "ℹ️  Shall Klipper be updated on the MCUs? [Y/n]" answer
answer=${answer:-N}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Installing MCU updates ..."
    cd "$REPO_DIR/scripts"
    ./mcu_update.sh -x linux                 # Update Linux MCU
    ./mcu_update.sh -x baord_mcu             # Update SKIPR MCU
    .//mcu_update.sh -x toolhead_mcu         # Update RP2040 MCU
    #./mcu_update.sh -x toolehad_sensor       # Update Sensor on RP2040
else
    echo "Please do it later."
fi

exit 0
