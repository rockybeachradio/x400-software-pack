#!/usr/bin/env bash

################################################################################################
# File: install_software.sh
# Author: Andreas
# Date: 20250822
# Purpose: Installs software that is needed by x400-software-pack
#
################################################################################################

################################################################################################
# Error handling
################################################################################################
set -euo pipefail


################################################################################################
# Pre check
################################################################################################
echo "ℹ️ Checking prerequisits ..."
if ! command -v sudo >/dev/null 2>&1; then
    echo "❌ sudo is not installed. Please install sudo and add your user '$USER' to the sudo group before executing this script."
    echo "$ su -"
    echo "$ apt-get install sudo"
    echo "$ /sbin/adduser $USER sudo"
    echo "$ exit"
    exit 1
else
    echo "✅ sudo ist installiert."
fi

if id -nG "$USER" | grep -qw sudo; then
    echo "✅ Benutzer '$USER' ist in der sudo-Gruppe."
else
    echo "❌ Your user '$USER' is not part of the sudo group. Please add your user before executing this script."
    echo "$ su -"
    echo "$ /sbin/adduser <USER> sudo"
    echo "$ exit"
    exit 1
fi


################################################################################################
# Update Linux
################################################################################################
echo "ℹ️ Updating Linux, components and software ..."
sudo apt update
sudo apt upgrade
sudo apt install


################################################################################################
# Install Linux software
################################################################################################
TARGET_DIR="configng"
REPO_URL="https://github.com/armbian/configng.git"

cd "$HOME"
if [[ -d "$TARGET_DIR/.git" ]]; then
    echo "✅ Repository '$TARGET_DIR' already exists."
else
    echo "ℹ️ Installing Armbian-config ..."
    echo "⬇️  Cloning $REPO_URL ..."
    sudo git clone "$REPO_URL" "$TARGET_DIR"
    echo "✅ Clone completed."
fi

################################################################################################
# Install fixes
################################################################################################
echo "ℹ️ Install fix for DFU utility ..."
cd /etc/udev/rules.d
sudo wget https://raw.githubusercontent.com/wiieva/dfu-util/refs/heads/master/doc/40-dfuse.rules -O 40-dfuse.rules
sudo usermod -aG plugdev $USER

echo "ℹ️ Install fix for Python 3 ..."
cd "$HOME"
sudo apt install python3-pip python3-serial


################################################################################################
# Install printer software
################################################################################################
TARGET_DIR="kiauh"
REPO_URL="https://github.com/dw-0/kiauh.git"

cd "$HOME"
if [[ -d "$TARGET_DIR/.git" ]]; then
    echo "✅ Repository '$TARGET_DIR' already exists."
else
    echo "ℹ️ Installing KIAUH ..."
    echo "⬇️  Cloning $REPO_URL ..."
    sudo git clone "$REPO_URL" "$TARGET_DIR"
    echo "✅ Clone completed."
fi

###################################################
TARGET_DIR="katapult"
REPO_URL="https://github.com/Arksine/katapult.git"

cd "$HOME"
if [[ -d "$TARGET_DIR/.git" ]]; then
    echo "✅ Repository '$TARGET_DIR' already exists."
else
    echo "ℹ️ Installing Katapult ..."
    echo "⬇️  Cloning $REPO_URL ..."
    sudo git clone "$REPO_URL" "$TARGET_DIR"
    echo "✅ Clone completed."
fi

###################################################
TARGET_DIR="Klipper-Adaptive-Meshing-Purging"
REPO_URL="https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging.git"

cd "$HOME"
if [[ -d "$TARGET_DIR/.git" ]]; then
    echo "✅ Repository '$TARGET_DIR' already exists."
else
    echo "ℹ️ Installing KAMP ..."
    echo "⬇️  Cloning $REPO_URL ..."
    sudo git clone "$REPO_URL" "$TARGET_DIR"
    echo "✅ Clone completed."
fi

###################################################
TARGET_DIR="moonraker-timelapse"
REPO_URL="https://github.com/mainsail-crew/moonraker-timelapse.git"

cd "$HOME"
if [[ -d "$TARGET_DIR/.git" ]]; then
    echo "✅ Repository '$TARGET_DIR' already exists."
else
    echo "ℹ️ Installing moonraker-timelapse ..."
    echo "⬇️  Cloning $REPO_URL ..."
    sudo git clone "$REPO_URL" "$TARGET_DIR"
    echo "✅ Clone completed."
    cd "$HOME""/moonraker-timelapse"
    make install 
fi


################################################################################################
# Install x11vnc
################################################################################################
echo "ℹ️ Installing x11vnc ..."
cd "$HOME"
sudo apt install x11vnc || echo "! Installation failed."

echo "ℹ️ Set password for remote access ..."
sudo x11vnc -storepasswd /etc/x11vnc.pass || echo "! Setting password failed."

#sudo cp "$config_source""/x11cnv.service" "/lib/systemd/system/" || echo "! Copying service failed."

sudo systemctl enable x11vnc.service || echo "! Enabling service failed."
sudo systemctl start x11vnc.service || echo "! Starting service failed."


################################################################################################
# Install software needed for farm3d
# The actual famr3d software is installed/updated by /x400-software-pack/scripts/update_printer.sh 
################################################################################################
echo "ℹ️ Installing needed tools for farm3d ...:"
cd "$HOME"
# ???
#pip3 install opencv-python || echo "! Faild pip3 install opencv-python"
# ???
#pip3 install qrcode[pil] || echo "! Faild pip3 install qrcode"


################################################################################################
# Backup script
################################################################################################
echo "ℹ️ Installing needed tools for backup ..:"
cd "$HOME"
sudo apt install zip || echo "! Installation failed."
mkdir "$HOME/printer_packup/"


################################################################################################
# Klipper-backup tool
# https://klipperbackup.xyz
################################################################################################
# --> USE KIAUH to install
#
# cd "$HOME"
# curl -fsSL get.klipperbackup.xyz | bash
# $HOME/klipper-backup/install.sh


################################################################################################
# Cleaning up
################################################################################################
echo "ℹ️ Clean up ..."
cd "$HOME"
sudo apt autoremove -y modem* cups* pulse* avahi* triggerhappy*


################################################################################################
# Ende
################################################################################################
echo "ℹ️ Installation completed."
exit 0;