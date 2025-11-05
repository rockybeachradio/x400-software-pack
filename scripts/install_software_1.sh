#!/usr/bin/env bash
set -euo pipefail

################################################################################################
# File: install_software.sh
# Author: Andreas
# Date: 20250925
# Purpose: Installs software that is needed by x400-software-pack
# Called by: install.sh, update.sh
#
################################################################################################
echo "This is $(basename "$0")"

################################################################################################
# Variables
################################################################################################
folder_of_script="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source_base=$REPO_DIR
config_source="$REPO_DIR""/configurations"

# Installation variables
    TARGET_DIR=""
    REPO_URL=""

# KLipper-Backup
    klipperbackup_dir=""
    klipperbackup_file=""

    github_username=""
    github_repository=""
    github_token=""


################################################################################################
# Include helper scripts
################################################################################################
source "$SCRIPT_DIR/read_write_config_files.sh"      # Include shell script with the read and write function for configuratin files.
echo " "

################################################################################################
# Pre check
################################################################################################
echo "ℹ️  Checking prerequisits ..."

if command -v sudo >/dev/null 2>&1; then
    echo "✅ sudo ist installiert."
else
    echo "❌ sudo is not installed. Please install sudo and add your user '$USER' to the sudo group before executing this script."
    echo "$ su -"
    echo "$ apt-get install sudo"
    echo "$ /sbin/adduser $USER sudo"
    echo "$ exit"
    exit 1
fi
echo " "

if id -nG "$USER" | grep -qw sudo; then
    echo "✅ Benutzer '$USER' ist in der sudo-Gruppe."
else
    echo "❌ Your user '$USER' is not part of the sudo group. Please add your user before executing this script."
    echo "$ su -"
    echo "$ /sbin/adduser '$USER' sudo"
    echo "$ exit"
    exit 1
fi
echo " "

################################################################################################
# Update Linux
################################################################################################
read -p "❓Changing printer name? [Y/n]: " answer
answer=${answer:-Y}     # default to "Y" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    
    echo "ℹ️  Changing printer name ..."
    
    read -p "❓New name of the system (Default: Thinker)?: " answer
    answer=$(echo "$answer" | xargs)    # Trim argument
    answer=${answer:-Thinker}           # default: Thinker

    sudo hostnamectl set-hostname $answer

else
    echo "... no installation."
fi
echo " "


################################################################################################
# Update Linux
################################################################################################
echo "ℹ️  Updating Linux, components and software ..."
sudo apt update
sudo apt upgrade -y

# sudo apt full-upgrade -y      # install new dependencies
echo " "

################################################################################################
# Install Linux software
################################################################################################
if [ "execute" = "no" ]; then # Auskommentierung --> Ist bereits installiert

TARGET_DIR="configng"
REPO_URL="https://github.com/armbian/configng.git"

cd "$HOME"
if [[ -d "$TARGET_DIR/.git" ]]; then
    echo "✅ Repository '$TARGET_DIR' already exists."
else
    echo "ℹ️  Installing Armbian-config ..."
    echo "⬇️  Cloning $REPO_URL ..."
    git clone "$REPO_URL"
    echo "✅ Clone completed."
fi

fi # Auskommentierung
echo " "


################################################################################################
# Install fixes
################################################################################################
###################################################
read -p "❓Install fix: python3-serial? [y/N]: " answer
answer=${answer:-N}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "ℹ️  Install fix for Python 3 ..."
    cd "$HOME"
    sudo apt install python3-pip python3-serial
else
    echo "... no installation."
fi
echo " "

###################################################
read -p "❓Install fix: dfu utility? [y/N]: " answer
answer=${answer:-N}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "ℹ️  Install fix for DFU utility ..."
    cd /etc/udev/rules.d
    sudo wget https://raw.githubusercontent.com/wiieva/dfu-util/refs/heads/master/doc/40-dfuse.rules -O 40-dfuse.rules
    sudo usermod -aG plugdev $USER
else
    echo "... no installation."
fi
echo " "


################################################################################################
# Add current user to plugdev group
################################################################################################
sudo usermod -aG plugdev $USER
echo " "

################################################################################################
# Install KIAUH
################################################################################################
TARGET_DIR="kiauh"
REPO_URL="https://github.com/dw-0/kiauh.git"

cd "$HOME"
if [[ -d "$TARGET_DIR/.git" ]]; then
    echo "✅ Repository '$TARGET_DIR' already exists."
else
    echo "ℹ️  Installing KIAUH ..."
    echo "⬇️  Cloning $REPO_URL ..."
    git clone "$REPO_URL"
    echo "✅ Clone completed."
fi
echo " "

################################################################################################
# Ende
################################################################################################
echo "ℹ️  $(basename "$0") completed."
exit 0