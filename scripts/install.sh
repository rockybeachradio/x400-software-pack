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
rc=""      # Return code  Variable for exit code of a called shell script

#Resolve repo root (parent of this script), then cd into it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR" || { echo "❌ x400-software-pack not found: $REPO_DIR"; exit 1; }


################################################################################################
# Check for new x400-software-pack version on GitHub repo
################################################################################################
echo "ℹ️  Start update check & download script (download_x400-software-pack) ..."
cd "$REPO_DIR/scripts/"
./download_x400-software-pack.sh || rc=$?
rc=$?       #capture exit code from script above (0 = new version was downloaded from GitHub, 5 = no newer verison on GitHub)

if [[ $rc -ne 0 && $rc -ne 5 ]]; then
  echo "❌  Stop update. (download_x400-software-pack exit with $rc)"
  exit 1
fi
echo " "

################################################################################################
# install software part 1
################################################################################################
echo "ℹ️  Start software installer (install_software_1.sh) ..."
cd "$REPO_DIR/scripts/" 
./install_software_1.sh
echo " "

################################################################################################
# further instructions
################################################################################################
echo " "
echo " "
echo "Next steps:"
echo " "
echo "Start KIAUH ~/kiauh/kiauh.sh"
echo "In KIAUH:"
echo "If asked select: 3) Yes, use v6 and remember choice"
echo " "
echo "ℹ️  Install the following in KIAUH:"
echo "    - 1) Install"
echo "        - 1) Klipper"
echo "        - 2) Moonraker"
echo "        - 3) Mainsail"
echo "        - 5) Mainsail-config"
echo "        - 7) KlipperScreen: With X11 and NetworkManager. The system will reboot after installation."
echo "        - 8) Crowsnest"
echo "    - 4) Advances"
echo "        - 5) Input Shaper Dependencies"
echo "    - E) Extension"
echo "        - 1) G-Code Shell Command"
echo "        - 3) Mobileraker   (optional)"
echo "        - 4) Klipper-Backup   (optional: Backup on boot, Cron, Backup on file changes)"
echo "        - 6) Obico for Klipper   (optional)"
echo "If you decide to install KlipperScreen, be aware that it may cause high-cpu load and therefor timeout errors druing printing. Reason: No GPU hardware acceleration."
echo " "
echo "After installing the software in KIAUH, launch the second part of the installation process: ~/x400-software-pack/scripts/install_part2.sh"
echo " "
echo " "


################################################################################################
# KIAUH launch
################################################################################################
read -p "❓ Launching KIAUH? [Y/n]" answer
answer=${answer:-Y}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
  echo "ℹ️  Starting KIAUH ..."
  ~/kiauh/kiauh.sh
else
  echo "okay. YOu can launch KIAUH by calling: ~/kiauh/kiauh.sh"
fi

exit 0