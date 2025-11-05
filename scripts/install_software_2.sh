#!/usr/bin/env bash
set -euo pipefail

################################################################################################
# File: install_software_2.sh
# Author: Andreas
# Date: 20251013
# Purpose: Installs software that is needed by x400-software-pack
# Called by: install.sh, update.sh
#
################################################################################################
echo "This is $(basename "$0")"
echo " "

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

# MCU Update
    MCU_FIRMWARE_CONFIGS_DIR="$REPO_DIR/mcu-firmware-configurations"
    LINUX_MCU_KLIPPER_FIRMWARE_CONFIG_FILE="$MCU_FIRMWARE_CONFIGS_DIR/linux_mcu_klipper_firmware.config"

################################################################################################
# Include helper scripts
################################################################################################
source "$SCRIPT_DIR/read_write_config_files.sh"      # Include shell script with the read and write function for configuratin files.



################################################################################################
# Pre check
################################################################################################
# none


################################################################################################
# Install printer software
################################################################################################
echo "ℹ️  Install Printer software ..."
echo " "

###################################################
TARGET_DIR="katapult"
REPO_URL="https://github.com/Arksine/katapult.git"

cd "$HOME"
if [[ -d "$TARGET_DIR/.git" ]]; then
    echo "✅ Repository '$TARGET_DIR' already exists."
else
    echo "ℹ️  Installing Katapult ..."
    echo "⬇️  Cloning $REPO_URL ..."
    git clone "$REPO_URL"
    echo "✅ Clone completed."
fi
echo " "

###################################################
TARGET_DIR="Klipper-Adaptive-Meshing-Purging"
REPO_URL="https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging.git"

cd "$HOME"
if [[ -d "$TARGET_DIR/.git" ]]; then
    echo "✅ Repository '$TARGET_DIR' already exists."
else
    echo "ℹ️ Installing KAMP ..."
    echo "⬇️  Cloning $REPO_URL ..."
    git clone "$REPO_URL"
    echo "✅ Clone completed."
fi
echo " "

###################################################
TARGET_DIR="moonraker-timelapse"
REPO_URL="https://github.com/mainsail-crew/moonraker-timelapse.git"

cd "$HOME"
if [[ -d "$TARGET_DIR/.git" ]]; then
    echo "✅ Repository '$TARGET_DIR' already exists."
else
    echo "ℹ️  Installing moonraker-timelapse ..."
    echo "⬇️  Cloning $REPO_URL ..."
    git clone "$REPO_URL"
    echo "✅ Clone completed."
    cd "$HOME""/moonraker-timelapse"
    make install
    echo "✅ Installation completed."
fi
echo " "

###################################################
TARGET_DIR="sonar"
REPO_URL="https://github.com/mainsail-crew/sonar.git"

cd "$HOME"
if [[ -d "$TARGET_DIR/.git" ]]; then
    echo "✅ Repository '$TARGET_DIR' already exists."
else
    echo "ℹ️  Installing sonar ..."
    echo "⬇️  Cloning $REPO_URL ..."
    git clone "$REPO_URL"
    echo "✅ Clone completed."
    cd "$HOME""/sonar"
    make config
    sudo make install
    echo "✅ Installation completed."
fi
echo " "

###################################################
# Klipper-backup tool
# https://klipperbackup.xyz
# --> USE KIAUH to install

read -p "❓Install Klipper-backup tool? [y/N]: " answer
answer=${answer:-N}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then

TARGET_DIR="klipper-backup"
REPO_URL="get.klipperbackup.xyz"

klipperbackup_dir="$HOME/$TARGET_DIR"
klipperbackup_file="$klipperbackup_dir/.env"

echo "ℹ️  Installing Klipper-backup tool ..."

# Installation gem klipperbackup.xyz
curl -fsSL $REPO_URL | bash
$klipperbackup_dir/install.sh

# Add settings from /configurations/klipper-backup.conf to klipper-backup/.env
read -p "❓ GitHub user name: " github_username
read -p "❓ GitHub repo name (eg. x400-backup): " github_repository
read -p "❓ GitHub repo ssh token (eg. ssh-ed25519... / github_pat_ed25519...): " github_token

# Write to klipper-backup/.env      # Writes in the .env file which is created during the klipper-backup/install.sh. Will later be replaced by the x400-software-pack version.
write_var_to_file "$klipperbackup_file" github_username
write_var_to_file "$klipperbackup_file" github_repository
write_var_to_file "$klipperbackup_file" github_token

else
    echo "... no installation."
fi
echo " "

################################################################################################
# Install x11vnc
# x11vnc: VNC server for sharing the desktop remotely (requires an X server).
################################################################################################
read -p "❓Install x11cnv? [y/N]: " answer
answer=${answer:-N}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "ℹ️  Installing x11vnc ..."
    cd "$HOME"
    sudo apt install x11vnc || echo "❌  Installation failed."

    echo "ℹ️  Set password for remote access ..."
    sudo x11vnc -storepasswd /etc/x11vnc.pass || echo "❌  Setting password failed."

    #sudo cp "$config_source""/x11cnv.service" "/lib/systemd/system/" || echo "! Copying service failed."

    sudo systemctl enable x11vnc.service || echo "❌  Enabling service failed."
    sudo systemctl start x11vnc.service || echo "❌  Starting service failed."

else
    echo "... no installation."
fi
echo " "


################################################################################################
# Rotate Display
################################################################################################
# source: https://klipperscreen.readthedocs.io/en/latest/Troubleshooting/Rotation/
#         https://klipperscreen.readthedocs.io/en/latest/Troubleshooting/Touch_issues/?h=cali#touch-rotation-and-matrix
#         https://klipperscreen.readthedocs.io/en/latest/Troubleshooting/Touch_issues/?h=cali#save-touch-calibration

################################################################################################
read -p "❓ Rotate Display (Raspberry 5)? [Y/n]: " answer
answer=${answer:-Y}     # default to "Y" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "ℹ️  Display invertion for RPI5  ..."

    ### NOT working:
    #sudo nano /boot/firmware/config.txt    --> dtoverlay=vc4-kms-v3d,rotate=180
    #sudo nano /boot/firmware/config.txt    --> display_rotate=180
    #sudo nano /boot/firmware/config.txt    --> display_rotate=2
    #sudo nano /boot/firmware/cmdline.txt  --> video=HDMI-1:800x480@60,rotate=180
    #$ sudo nano /boot/firmware/config.txt --> video=HDMI-A-1:800x480M@60,rotate=180

    ### X11 only
    #$ DISPLAY=:0 xrandr --output HDMI-1 --rotate inverted
    #$ DISPLAY=:0 xrandr

    CMDLINE_FILE="/boot/firmware/cmdline.txt"
    ROTATION_PARAM="video=HDMI-A-1:800x480@60D,rotate=180"

    CURRENT_FILE_CONTENT=$(cat "$CMDLINE_FILE")

    # Check if any video= for HDMI-A-1 or HDMI-1 already exists
        #if echo "$CURRENT_FILE_CONTENT" | grep -qE "video=HDMI-(A-1|1):[^ ]*rotate=" || \
        #echo "$CURRENT_FILE_CONTENT" | grep -qE "video=HDMI-(A-1|1):"; then
    if echo "$CURRENT_FILE_CONTENT" | grep -qE 'video=(HDMI-A-1|HDMI-1):'; then
        # Check if the exact rotation param already exists
        if echo "$CURRENT_FILE_CONTENT" | grep -qF "$ROTATION_PARAM"; then
            echo "ℹ️ Rotation parameter already present. Nothing to do."
        else
            echo "❌ A 'video=' parameter for HDMI-A-1 or HDMI-1 already exists:"
            echo "   $(echo "$CURRENT_FILE_CONTENT" | grep -oE 'video=HDMI-(A-1|1):[^ ]*')"
            echo "ℹ️ No changes made. Edit cmdline.txt manually if needed."
        fi
    else
        # If no HDMI parameter exists
        NEW_CMDLINE=$(echo "$CURRENT_FILE_CONTENT" | sed -E 's/([^\s]+)\s*$/\1 '"$ROTATION_PARAM"'/')
        echo "$NEW_CMDLINE" > "$CMDLINE_FILE"

        echo "ℹ️ Added rotation parameter to cmdline.txt."
        echo "Reboot is required that the change take effect"
    fi

else
    echo "... no rotation."
fi
echo " "


################################################################################################
read -p "❓ Rotate display for Console (Armbian OS)? [y/N]: " answer
answer=${answer:-N}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "ℹ️  Display invertion for terminal  ..."
    # echo "extraargs=fbcon=rotate:2" | sudo tee -a /boot/armbianEnv.txt  || echo "❌  Faild: writing to armbianEnv.txt"
    # Write only if line not existing:
    grep -Fx "extraargs=fbcon=rotate:2" /boot/armbianEnv.txt || { echo "extraargs=fbcon=rotate:2" | sudo tee -a /boot/armbianEnv.txt || echo "❌ Failed: writing to armbianEnv.txt"; }
else
    echo "... no rotation."
fi
echo " "


################################################################################################
read -p "❓ Rotate display for X11 (KlipperScreen) (RPIos)? [y/N]: " answer
answer=${answer:-N}     # default to "Y" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "ℹ️  Display invertion for X11 (KlipperScreen) ..."
    DISPLAY=:0 xrandr || echo "❌  Faild: DISPLAY=:0 xrandr"
    echo " "

    echo "Invert display (rotate 180°) ..."
    sudo cp "$source_base""/display-orientation/90-monitor.conf" "/usr/share/X11/xorg.conf.d/90-monitor.conf" || echo "❌  Faild copying 90-monitor.conf"
    sudo service KlipperScreen restart  || echo "❌  Faild retarting KlipperScreen"
    echo "ℹ️  ... done"
    echo " "

else
    echo "... no installation."
    echo " "
fi
echo " "

################################################################################################
read -p "❓ Rotate Display for X11 (KlipperScreen) (Armbian OS)? [y/N]: " answer
answer=${answer:-N}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "ℹ️  Display invertion for X11 (KlipperScreen) ..."
    DISPLAY=:0 xrandr || echo "❌  Faild: DISPLAY=:0 xrandr"
    echo " "

    echo "Make X11 use the DRM/KMS -modesetting- driver ..."
    sudo apt purge xserver-xorg-video-fbdev -y || echo "❌  Faild: apt purge xserver-xorg-video-fbdev"      # Make X pick modesetting
    sudo apt purge xserver-xorg-video-vesa -y  || echo "❌  Faild: apt purge xserver-xorg-video-vesa"       # Make X pick modesetting

    sudo mkdir -p /usr/share/X11/xorg.conf.d  || echo "❌  Faild: mkdir /usr/share/X11/xorg.conf.d"
    sudo cp "$source_base""/display-orientation/20-modesetting.conf" "/usr/share/X11/xorg.conf.d/20-modesetting.conf" || echo "❌  Faild copying 20-modesetting.conf"
    sudo apt install -y libgl1-mesa-dri libglx-mesa0 libegl1 libgbm1 || echo "❌  Faild installing: libgl1-mesa-dri libglx-mesa0 libegl1 libgbm1 "       # Ensures that Mesa/GBM is installed
    echo " "

    echo "Invert display (rotate 180°) ..."
    sudo cp "$source_base""/display-orientation/90-monitor.conf" "/usr/share/X11/xorg.conf.d/90-monitor.conf" || echo "❌  Faild copying 90-monitor.conf"
    sudo service KlipperScreen restart  || echo "❌  Faild retarting KlipperScreen"
    echo "ℹ️  ... done"
    echo " "

else
    echo "... no installation."
    echo " "
fi
echo " "


################################################################################################
# Touch rotation
################################################################################################
read -p "❓ Touch invertion (RPIos)? [Y/n]: " answer
answer=${answer:-Y}     # default to "Y" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "ℹ️  Touch invertion ..."
    DISPLAY=:0 xrandr || echo "❌  Faild: DISPLAY=:0 xrandr"
    echo " "

    echo "ℹ️  Touch rotation by 180° ..."
    sudo cp "$source_base""/display-orientation/51-touchscreen.rules.conf" "/etc/udev/rules.d/51-touchscreen.rules" || echo "❌  Faild 51-touchscreen.rules"
    echo "ℹ️  ... done"
    echo " "

else
    echo "... no installation."
    echo " "
fi
echo " "


################################################################################################
# Install software needed for farm3d
# The actual famr3d software is installed/updated by /x400-software-pack/scripts/copy_configs.sh 
################################################################################################
read -p "❓Install Eryone farm3d - needed software? [y/N]: " answer
answer=${answer:-N}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "ℹ️  Installing needed tools for farm3d ..."
    
    cd "$HOME"

    # ???
    pip3 install opencv-python || echo "! Faild pip3 install opencv-python"
    # --> error during execution: externally-managed-environment

    # ???
    pip3 install qrcode[pil] || echo "! Faild pip3 install qrcode"
    # ??? --> error during execution: externally-managed-environment

else
    echo "... no installation."
fi
echo " "


################################################################################################
# Backup script
################################################################################################
read -p "❓Install Backup script? [y/N]: " answer
answer=${answer:-N}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then

    echo "ℹ️  Installing needed tools for backup script ..."

    # Declare variables
    TARGET_DIR="printer_backup"
    REPO_URL="x400-software-pack"                 #local script. No repo.

    local_backup_folder="$HOME/$TARGET_DIR"                     # Choose the path wisely. Backups may contain confidential informations like credentials.
    local_backup_folder_files="$local_backup_folder/files"      # When changing the content of local_backup_folder_files, also change the pathin copy_configs.sh and install_software.sh !
    local_backup_folder_zip="$local_backup_folder/zip"

    github_user_name=""             # rockybeachradio
    github_repo_name=""             # x400-backup
    github_ssh_key_name=""          # --> x400-backup_ed25519
    github_ssh_key_label=""         # --> rockybeachradio_x400-backup
    github_encryption="ed25519"     # --> Encryption type
    github_ssh_host_name=""         # --> github.com_x400-backup

    ##############################################################
    # Install software
    sudo apt-get install -y zip                || echo "❌  Installation of zip failed."
    sudo apt-get install -y openssh-client     || echo "❌  Installation of openssh-client failed."

    ##############################################################
    # Create folders
    rm -rf "$local_backup_folder"          || echo "ℹ️   could not deleat $local_backup_folder"

    mkdir -p "$local_backup_folder"        || echo "✅  backup folder already exists"
    mkdir -p "$local_backup_folder_files"  || echo "✅  files folder already exists"
    mkdir -p "$local_backup_folder_zip"    || echo "✅  zip folder already exists"

    ##############################################################
    # Ask if GitHub shall be set up.
    read -p "❓ Do you want to setup GitHub as backup destination? [Y/n]: " answer
    answer=${answer:-Y}     # default to "Y" if empty
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        initiate_github "$local_backup_folder_files"        || echo "❌ GitHub setup failed"      # in git_initiate.sh
        echo "Setting variable: github_repo_name=true in /x400-software-pack/scripts/backup.sh ..."
        if cd $folder_of_script; then
            sed -i 's/github_backup=false/github_backup=true/g' ./backup.sh   || echo "❌ Failed setting variable github_backup=false"    # Set the variable github_backup=true in /x400-software-pack/scripts/backup.sh
        else 
            echo "❌ Could not go to folder: $folder_of_script"
        fi
    else
        if cd $folder_of_script; then
            sed -i 's/github_backup=true/github_backup=false/g' ./backup.sh   || echo "❌ Failed setting variable github_backup=true"    # Set the variable github_backup=false in /x400-software-pack/scripts/backup.sh
        else 
            echo "❌ Could not go to folder: $folder_of_script"
        fi
    fi

else
    echo "... no installation."
fi
echo " "


################################################################################################
# Flash Linux MCU (rpi)
################################################################################################
read -p "❓ Install the Linux MCU? [Y/n]: " answer
answer=${answer:-Y}     # default to "Y" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "ℹ️  Calling mcu_update.sh for linux mcu..."
    "$SCRIPT_DIR/mcu_update.sh" -m linux -c "$LINUX_MCU_KLIPPER_FIRMWARE_CONFIG_FILE"
else
    echo "... no installation."
fi
echo " "

################################################################################################
# Helper Tools
################################################################################################
echo "ℹ️  Installing userful tools (iotop, etc.) ..."

sudo apt install -y iotop                       # iotop: Monitors disk I/O usage by processes (complements htop for system debugging).
sudo apt install -y can-utils                   # can-utils: Tools for Controller Area Network (CAN) interfaces.

echo "ℹ️  ... done"
echo " "

#######################################################
if [ "execute" = "no" ]; then # Auskommentierung

sudo apt install -y htop                        # htop: Interactive system-monitoring tool for CPU, memory, and process usage (more user-friendly than top).
sudo apt install -y iotop                       # iotop: Monitors disk I/O usage by processes (complements htop for system debugging).

sudo apt install bpytop -y                      # bpytop: system monitoring tool written in Python, similar to htop but with a more graphical interface.
pip3 install --upgrade psutil                   # psutil: A cross-platform Python library for retrieving system utilization metrics.

sudo apt install -y tcpdump                     # tcpdump: Network packet analyzer for capturing and analyzing network traffic.
sudo apt install -y iptraf                      # iptraf: Interactive network monitoring tool for bandwidth and traffic statistics.

sudo apt install -y speedtest-cli               # speedtest-cli: Command-line tool to test internet speed (useful for checking network).
sudo apt install -y wavemon                     # wavemon: Wireless network monitoring tool to check Wi-Fi signal strength and stats.

sudo apt install -y tldr                        # tldr: Simplified man pages with practical command examples.
sudo apt install -y ranger                      # ranger: Console-based file manager with a modern, vim-like interface.
sudo apt install -y mc                          # mc: Midnight Commander, a text-based file manager for navigating directories.

sudo apt install -y dcfldd                      # dcfldd: Enhanced version of dd for disk imaging and data recovery with forensic features.

sudo apt install -y fd-find                     # fd-find: Fast alternative to find for searching files (often aliased as fd).
sudo apt install -y silversearcher-ag           # silversearcher-ag: A fast code-searching tool (ag) for finding text in files, useful for developers.

sudo apt install -y hexedit                     # hexedit: Hexadecimal editor for viewing/editing binary files (e.g., firmware or EEPROM data).
sudo apt install -y ultitail                    # multitail: Monitor multiple log files simultaneously (e.g., klippy.log for Klipper debugging).

sudo apt install -y usbutils                    # usbutils: Tools like lsusb to list and debug USB devices (e.g. USB connections).

sudo apt install -y ncdu                        # ncdu: Disk usage analyzer for finding large files/directories (e.g., to manage SD card space).

sudo apt install -y can-utils                   # can-utils: Tools for Controller Area Network (CAN) interfaces.

sudo apt install -y lsof                        # lsof: Lists open files and their associated processes (useful for debugging resource usage).

sudo apt install -y minicom                     # minicom: Serial communication tool for interacting with devices like microcontrollers (e.g., STM32F407).
sudo apt install -y i2c-tools                   # i2c-tools: Utilities like i2cdetect for debugging I²C devices (e.g., AT24C32 EEPROM on PB10/PB11).

#sudo apt install -y git                         # git: Version control system for tracking code changes (e.g., managing Klipper source code).
#sudo apt install -y nano                        # nano: Simple command-line text editor for editing files like printer.cfg.

#sudo apt install -y terminator                  # terminator: Advanced terminal emulator with split panes (requires GUI).
#sudo apt install -y cutecom                     # cutecom: Graphical serial terminal for debugging serial connections (requires GUI).

#sudo apt install -y joystick                    # joystick: Tools for configuring and testing joysticks
#sudo apt install -y jstest-gtk                  # jstest-gtk: Graphical joystick testing tool (requires GUI).

fi # Auskommentierung


################################################################################################
# Update TL;DR chache
################################################################################################
if [ "execute" = "no" ]; then # Auskommentierung
tldr -u     # Update the local cache of TL;DR pages for the tldr command-line tool
fi # Auskommentierung

################################################################################################
# Cleaning up
################################################################################################
echo "ℹ️  Clean up ..."
cd "$HOME"
sudo apt autoremove -y modem* cups* pulse* avahi* triggerhappy*
echo " "


################################################################################################
# Ende
################################################################################################
echo " "
echo "Next steps:"
echo "call: ~/x400-software-pack/scripts/copy_configs.sh -i"
echo "Thats it. YOur printer is ready to print"

echo " "
echo "ℹ️  $(basename "$0") completed."

exit 0