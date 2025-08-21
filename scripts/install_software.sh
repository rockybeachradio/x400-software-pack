#!/usr/bin/bash

################################################################################################
# File: isntall.sh
# Author: Andreas
# Date: 20250821
# Purpose: Installs software that is needed by x400-software-pack
#
################################################################################################



################################################################################################
# Update Linux
################################################################################################
sudo apt update
sudo apt upgrade
sudo apt install


################################################################################################
# Install Linux software
################################################################################################
echo "Install SUDO ..."
su -
apt-get install sudo
exit

echo "Install GIT ..."
cd "$HOME"
sudo apt install git

echo "Install Armbian-config ..."
cd "$HOME"
cd /
su -
sudo git clone https://github.com/armbian/configng.git
exit

################################################################################################
# Install printer software
################################################################################################
echo "Installing KIAUH ..."
cd "$HOME"
git clone https://github.com/dw-0/kiauh.git

echo "Installing Katapult ..."
cd "$HOME"
git clone https://github.com/Arksine/katapult

echo "Installing KAMP ..."
cd "$HOME"
git clone https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging.git

echo "Installing moonraker-timelapse ..."
cd "$HOME"
git clone https://github.com/mainsail-crew/moonraker-timelapse.git
cd "$HOME""/moonraker-timelapse"
make install


################################################################################################
# Install fixes
################################################################################################
echo "Install fix for DFU utility ..."
cd "$HOME"
su -
cd /etc/udev/rules.d
wget https://raw.githubusercontent.com/wiieva/dfu-util/refs/heads/master/doc/40-dfuse.rules -O 40-dfuse.rules
sudo usermod -aG plugdev $USER

echo "Install fix for Python 3 ..."
cd "$HOME"
sudo apt install python3-pip python3-serial


################################################################################################
# Cleaning up
################################################################################################
echo "Clean up ..."
cd "$HOME"
sudo apt autoremove -y modem* cups* pulse* avahi* triggerhappy*


################################################################################################
# Install x11vnc
################################################################################################
echo "Installing x11vnc ..:"
cd "$HOME"
sudo apt install x11vnc || echo "! Installation failed."

echo "Set password for remote access ..."
sudo x11vnc -storepasswd /etc/x11vnc.pass || echo "! Setting password failed."

#sudo cp "$config_source""/x11cnv.service" "/lib/systemd/system/" || echo "! Copying service failed."

sudo systemctl enable x11vnc.service || echo "! Enabling service failed."
sudo systemctl start x11vnc.service || echo "! Starting service failed."


################################################################################################
# Install software needed for farm3d
# The actual famr3d software is installed/updated by /x400-software-pack/scripts/update_printer.sh 
################################################################################################
echo "Installing needed tools for farm3d ...:"
cd "$HOME"
pip3 install opencv-python || echo "! Faild pip3 install opencv-python"
pip3 install qrcode[pil] || echo "! Faild pip3 install qrcode"


################################################################################################
# Backup script
################################################################################################
echo "Installing needed tools for backup ..:"
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
# Ende
################################################################################################
echo "Installation completed."
echo "Restart required. Restart now?."
answer=${answer:-N}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    sudo reboot
else
    echo "See you later."
fi
exit 0;