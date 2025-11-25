#!/usr/bin/bash
set -euo pipefail

################################################################################################
# File: copy_configs.sh
# Author: Andreas
# Date: 20250925
# Purpose: Copies all Confgiruations file to the locations so the printer software can use it
#          Installing Eryone farm3d.
# Called by: install.sh, update.sh
#
################################################################################################

################################################################################################
# commands used in this script
################################################################################################
#rm -rf /path/to/folder/*                       # Delete the folders content. r = recursive, f = force
#rm -rf /path/to/folder/{*,.*} 2>/dev/null      # for hidden files

#cp -r /source/fodler/* destination/folder/                         # copy content from one folder to another. r = recursive
#cp -r /source/folder/{*,.*} /destination/folder/ 2>/dev/null       # including hidden files

#cp /source/fodler/file /destination/folder/file            # replace a file with another

#mv /path/to/newfile /path/to/existingfile                  # moves a file

#ln -sfn /path/to/real-file /path/to/shortcut-symlinkl      # Create links. s = symlink, f = force, n = treat link as normal file if it exists

#sed -i 's/OLD/NEW/g' file1 file2 file3     # Replaces OLD with NEW in the file(s). i= edit the file (in.place), s = subtitute the string with a new one, g = global replaces all strings in the file
                                            # on Macos a backup suffix is requred. if non wanted: $ sed -i 's/OLD/NEW/g' filename
                                            # $ sed 's/foo/bar/g' myfile.txt shows only the resuts
################################################################################################
echo "This is $(basename "$0")"
echo " "

################################################################################################
# Variables
################################################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source_base=$REPO_DIR
config_source="$REPO_DIR""/configurations"

config_destination="$HOME""/printer_data/config"
INSTALL=false

github_username=""
github_repository=""
github_token=""


################################################################################################
# Include helper scripts
################################################################################################
source "$SCRIPT_DIR/read_write_config_files.sh"      # Include shell script with the read and write function for configuratin files.
source "$SCRIPT_DIR/git_initiate.sh"






################################################################################################
# === AUTO-MODE DETECTION ===
################################################################################################
# If one of these environment variables is set → we are running from Moonraker update_manager
if [[ -n "${MOONRAKER_UPDATE:-}" ]] || [[ -n "${AUTO_YES:-}" ]] || [[ "${1:-}" == "--auto" ]]; then
    AUTO_MODE=1
    echo "Running in AUTO mode (called from Moonraker update_manager)"
else
    AUTO_MODE=0
    echo "Running in INTERACTIVE mode"
fi


################################################################################################
# Get parameters
################################################################################################
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--install)
      INSTALL=true; shift ;;
    --auto)
      AUTO_MODE=1; shift ;;   # internal use by /x400-software-pack/update.py
    -h|--help)
      echo "Usage: $0 [-i|--install]"
      echo "i/install - Will override some files with customer settings. update preseveres them."
      exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Use --help for usage."
      exit 1 ;;
  esac
done
echo " "


# Parse parameters
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--install) INSTALL=true; shift ;;
        --auto)       AUTO_MODE=1; shift ;;   # internal use by update.py
        -h|--help)    echo "Usage: $0 [-i|--install]"; exit 0 ;;
        *)            echo "Unknown option: $1"; exit 1 ;;
    esac
done




################################################################################################
# Ask user dialog
################################################################################################
# Helper: Ask question only if not in auto mode
ask() {
    local prompt="$1"
    local default="$2"
    local answer

    if [[ $AUTO_MODE -eq 1 ]]; then
        echo "$prompt [auto: $default]"
        echo "$default"
        return
    fi

    read -p "$prompt [$default]: " answer
    answer=${answer:-$default}
    echo "$answer"
}

# Helper: yes/no question with default Y or N
ask_yn() {
    local prompt="$1"
    local default_answer="$2"  # true = Y, false = N

    echo "AUTO_MODE: $AUTO_MODE"
    echo "prompt: $prompt"
    echo "default_answer: $default_answer"

    if [[ $AUTO_MODE -eq 1 ]]; then
        if [[ $default_answer == true ]]; then
            echo "$prompt [auto: Y]"
            echo "Y"
        else
            echo "$prompt [auto: N]"
            echo "N"
        fi
        #return
    #fi
    else

    if [[ $default_answer == true ]]; then
        read -p "$prompt [Y/n]: " answer
        answer=${answer:-Y}
    else
        read -p "$prompt [y/N]: " answer
        answer=${answer:-N}
    fi

    fi
    echo "ask_yn() answer: $answer"
}


################################################################################################
# Dobule check that all the preparation is done.
################################################################################################
#read -p "❓ This script will evetnually override existing files and folders. Changes made in those files will be removed. Continue? [Y/n]: " answer
#answer=${answer:-Y}     # default to "N" if empty
answer=$(ask_yn "This script will eventually override existing files and folders. Continue?" true)

echo "double_check answer: $answer"

if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Okay, lets start ..."
else
    echo "See you later."
    exit 0;
fi
echo " "


################################################################################################
# Configuration files - Copy files to /printer_data/config/
################################################################################################
# printer_data - config
echo "ℹ️  Preparing configuration folder ..."
rm -rf "$config_destination""/*"  || echo "❌  Faild deleating folder content of ""$config_destination"

echo "Copy configurations ..."
files=(
    printer.cfg
    motor_driver_v1_2.cfg
    EECAN.cfg
    calibration.cfg
    filament_mgmt.cfg
    KAMP_Settings.cfg
    x400.cfg
    printjob_mgmt.cfg
    nozzle_cleaning.cfg
    eryone_stuff.cfg
    chamber_temp_mgmt.cfg
    Andreas_extensions.cfg
    variables.cfg
    plr.cfg
    crowsnest.conf
    KlipperScreen.conf
    mobileraker.conf
    moonraker.conf
    moonraker-obico.cfg
    electronics_bay.cfg
    macros_printer.cfg
    macros_debugging.cfg
    light_management.cfg
    marlin_compatibility.cfg
    )

# Copy to printer_data/config/
for f in "${files[@]}"; do
    cp "$config_source""/""$f" "$config_destination/"  || echo "❌  Faild copying ""$f"
done
echo " "


################################################################################################
# Mainsail Theme - Additional Menu entries
################################################################################################
echo "ℹ️  Prepare Mainsail - Additional Menu entries ..."
cp "$config_source/dot_theme/"* "$config_destination/.theme/" || echo "❌  Faild: Copying Mainsail Theme folder."
#cp -a "$config_source/dot_theme"/{.*,*} "$config_destination/.theme"/ 2>/dev/null && echo "Copied Mainsail Theme folder" || echo "❌ Failed: Copying Mainsail Theme folder"
echo " "


################################################################################################
# Configuration files - Copy fiels to spezial destinations
################################################################################################
#echo "ℹ️  Copy config files to spezial folders ..."
#cp "$config_source""/mainsail-client.cfg" "$HOME""/mainsail-config/client.cfg"  || echo "❌  Faild copying mainsail-client.cfg"            # The newest version of the client.cfg file created by Mainsail-crew shall be used. Not the orlder eryone version.
#cp "$config_source""/timelapse.cfg" "$HOME""/moonraker-timelapse/klipper_macro/timelapse.cfg"   || echo "❌  Faild copying timelapse.cfg"   # The newest version of the timelapse.cfg file created by Mainsail-crew shall be used. Not the orlder eryone version.


################################################################################################
# Configuration files - Copy only during installation
################################################################################################
echo "ℹ️  Copy config files with device specific setting (canuid.cfg, etc.) ..."
if [[ $INSTALL == "true" ]]; then
    echo "...INSTALL is true. Copy/override config files which were customised by users ..."
    #cp "$config_source""/klipper-backup env.conf" "$HOME/klipper-backup/.env"   || echo "❌  Faild copying KlipperBackup env.cfg"  # --> Initial copy in install_software.sh. And here in "Klipper-Backup"
    cp "$config_source""/canuid.cfg" "$config_destination/"   || echo "❌  Faild copying canuid.cfg"
else 
    echo "... It is not an installation. When updating no copy/override of customized config files like canuid.cfg."
fi
echo " "


################################################################################################
# Update UUIDs in canuid.cfg
################################################################################################
echo "ℹ️  Update UUIDs in canuid.cfg ..."
if [[ $INSTALL == "true" ]]; then
  echo "...INSTALL is true. Adapt UUIDs ..."
  "$SCRIPT_DIR/read_write_uuid_file.sh"    || echo "❌  Failed calling: read_write_uuid_file.sh"
else 
    echo "... It is not an installation. When updating no copy/override of customized config files like canuid.cfg."
fi

echo "ℹ️  To change the UUIDs later via: $SCRIPT_DIR/read_write_uuid_file.sh"
echo " "


################################################################################################
# Configuration files - Create Symlinks
################################################################################################
echo "ℹ️  Creating Symlinks ..."
ln -sfn "$HOME""/mainsail-config/mainsail.cfg"                      "$config_destination""/mainsail.cfg"  || echo "❌  Faild setting symlink to mainsail.cfg"
ln -sfn "$HOME""/moonraker-timelapse/klipper_macro/timelapse.cfg"   "$config_destination""/timelapse.cfg" || echo "❌  Faild setting symlink to timelapse.cfg"
ln -sfn "$HOME""/Klipper-Adaptive-Meshing-Purging/Configuration/"   "$config_destination""/KAMP" || echo "❌  Faild setting symlink to KAMP configuration folder"
echo " "


################################################################################################
# printer scripts
################################################################################################
echo "ℹ️  Copy printer scripts (eg. bed_object.sh, cv.py, plr.sh)..."
mkdir -p "$HOME/printer_data/scripts/"   || echo "ℹ️  Folder /scripts/ in /printer_data/ exists"
cp "$REPO_DIR/printer-scripts/"* "$HOME/printer_data/scripts/"   || echo "❌  Copy printer scripts failed"
echo " "


################################################################################################
# Klipper Extensions
################################################################################################
echo "ℹ️  Add Klipper extensions (eg. at24c_eeprrom.py)..."
cp "$source_base""/klipper-klippy-extras/"* "$HOME""/klipper/klippy/extras/" || echo "❌  Faild copying Klipper extensions."
echo " "


################################################################################################
# KlipperScreen panels
################################################################################################
#read -p "❓Install KlipperScreen panels? [y/N]: " answer
#answer=${answer:-N}     # default to "N" if empty
answer=$(ask_yn "Install KlipperScreen panels?" false)
if [[ "$answer" =~ ^[Yy]$ ]]; then
  echo "ℹ️  Add KlipperScreen panels ..."
  cp "$source_base""/eryone-KlipperScreen-panels/"* "$HOME""/KlipperScreen/panels/" || echo "❌  Faild copying Klipper-panels."
else
  echo "... no installation."
fi
echo " "


################################################################################################
# CAN Bus Configuration
################################################################################################
if [[ $INSTALL == "true" ]]; then
  answer="Y"
else
  #read -p "❓Setup CAN-Bus [y/N]: " answer
  #answer=${answer:-N}     # default to "N" if empty
  answer=$(ask_yn "Setup CAN-Bus? [y/N]" false)
fi

if [[ "$answer" =~ ^[Yy]$ ]]; then

  echo "ℹ️  Setup CAN Bus ..."
  # Copy files
  sudo cp "$source_base""/can-bus-configurtation/10-can.link.conf" "/etc/systemd/network/10-can.link" || echo "❌  Faild copying 10-can.link"
  sudo cp "$source_base""/can-bus-configurtation/20-can0.network.conf" "/etc/systemd/network/20-can0.network" || echo "❌  Faild copying 0-can0.network"

  # Start commands
  sudo systemctl enable systemd-networkd || echo "❌  Faild: systemctl enable systemd-networkd"
  sudo systemctl start systemd-networkd || echo "❌  Faild: systemctl start systemd-networkd"
  sudo udevadm control --reload-rules && sudo udevadm trigger || echo "❌  Faild: udevadm control --reload-rules && sudo udevadm trigger"

  ##############################################################
  echo "ℹ️  Reducing systemd-networkd wait-online time for faster start ..."
  sudo mkdir -p /etc/systemd/system/systemd-networkd-wait-online.service.d || echo "❌  Faild: mkdir /etc/systemd/system/systemd-networkd-wait-online.service.d"
  sudo cp "$source_base""/can-bus-configurtation/systemd-networkd-wait-online-service_override.conf" "/etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf" || echo "❌  Faild copying systemd-networkd-wait-online-service_override.conf"
  sudo systemctl daemon-reload || echo "❌  Faild: systemctl daemon-reload"

else
  echo "... no"
fi
echo " "


################################################################################################
# x11vnc
################################################################################################
#read -p "Copy x11vnc.service? [y/N]: " answer
#answer=${answer:-N}     # default to "N" if empty
answer=$(ask_yn "Copy x11vnc.service?" false)
if [[ "$answer" =~ ^[Yy]$ ]]; then

  echo "ℹ️  Copy x11cnv.service ..."
  sudo cp "$source_base""/services/x11cnv.service" "/lib/systemd/system/" || echo "❌  Copying service failed."

else
    echo "... no copying."
fi
echo " "


################################################################################################
# backup script  - helper
################################################################################################
#read -p "Copy Backup Script - helper (git_push.sh)? [y/N]: " answer
#answer=${answer:-N}     # default to "N" if empty
answer=$(ask_yn "Copy Backup Script - helper (git_push.sh)?" false)
if [[ "$answer" =~ ^[Yy]$ ]]; then

  echo "ℹ️  Copy Backup script - helper ..."
  cp "$source_base""/scripts/git_push.sh" "$HOME/printer_backup/files/" || echo "❌  Faild copying git_push.sh to backup folder."

else
    echo "... no copying."
fi
echo " "


################################################################################################
# Klipper-Backup  - Create symlinks, to allow Klipper-Backup to backup files outside of the user`s folder
################################################################################################
#read -p "Copy Klipper-Backup files? [y/N]: " answer
#answer=${answer:-N}     # default to "N" if empty
answer=$(ask_yn "Copy Klipper-Backup files and create symlinks?" false)

if [[ "$answer" =~ ^[Yy]$ ]]; then
  TARGET_DIR="klipper-backup"
  REPO_URL="get.klipperbackup.xyz"

  klipperbackup_dir="$HOME/$TARGET_DIR"
  klipperbackup_file="$klipperbackup_dir/.env"

  echo "ℹ️  Copy Klipper-Backup ..."
  mkdir -p "$HOME/printer_data/symlinks_for_backup/"   || echo "❌  creating the /printer_data/symlink symlinks_for_backup/"

  # Set symlinks to backup files outside of $HOME directory.
  sudo ln -sfn "/etc/hostname"                     "$HOME/printer_data/symlinks_for_backup/hostname"      || echo "❌  Faild setting symlink /printer_data/symlinks_for_backup/hostname"
  sudo ln -sfn "/etc/network/interfaces.d/can0"    "$HOME/printer_data/symlinks_for_backup/can0"          || echo "❌  Faild setting symlink /printer_data/symlinks_for_backup/can0"

  if [ -d "$klipperbackup_dir" ]; then
    # Folder exists
    
    cd "$klipperbackup_dir"
      # Read from klipper-backup/.env
      read_var_from_file "$klipperbackup_file" github_username
      read_var_from_file "$klipperbackup_file" github_repository
      read_var_from_file "$klipperbackup_file" github_token

    cp "$config_source""/klipper-backup env.conf" "$klipperbackup_file"   || echo "❌  Faild copying KlipperBackup env.cfg"

    # Write to klipper-backup/.env
    write_var_to_file "$klipperbackup_file" github_username
    write_var_to_file "$klipperbackup_file" github_repository
    write_var_to_file "$klipperbackup_file" github_token

  else 
    echo "❌  Faild: folder does not exist. KlipperBackup env.cfg could not be copied and customized."
  fi

else
    echo "... no copying."
fi
echo " "


################################################################################################
# farm3d - Copy and call .install
#     source: eryone-scripts-all/install_lib.sh
################################################################################################
#read -p "❓Install/Update Eryone farm3d - software? [y/N]: " answer
#answer=${answer:-N}     # default to "N" if empty
answer=$(ask_yn "Install/Update Eryone farm3d software?" false)
if [[ "$answer" =~ ^[Yy]$ ]]; then

  echo "ℹ️  Copy Eryone farm3d ..."
  if [[ -d "$HOME""/farm3d/" ]]; then
      rm -rf "$HOME/farm3d"
  fi
  cp -r "$source_base""/eryone-farm3d/" "$HOME""/farm3d/"  || echo "❌  Faild copying farm3d folder"
  #chmod 777 "$HOME""/farm3d" || echo "❌  Faild chmod on farm3d folder"    # Eryone original: 777
  chmod +x "$HOME""/farm3d" || echo "❌  Faild chmod on farm3d folder"
  if cd "$HOME""/farm3d/"; then
      echo "ℹ️  Starting Eryone farm3d installer ..."
      ./install.sh  || echo "❌  Faild starting the /farm3d/install.sh. Or the script aborted due to an error."      # Calling the farm3d installer
  else
      echo "❌  Faild going into ""$source_base""/farm3d folder"
  fi

  #pip3 install opencv-python || echo "! Faild pip3 install opencv-python"        # This is installed by /x400-software-pack/scripts/install_software.sh
  #pip3 install qrcode[pil] || echo "! Faild pip3 install qrcode"                 # This is installed by /x400-software-pack/scripts/install_software.sh
else
  echo "... no copying."
fi # Auskommentierung
echo " "


################################################################################################
# Eryone script - Copy
################################################################################################
#echo "ℹ️  Create symling to Eryone scripts ..."
#ln -sfn "$source_base""/eryone-scripts-all/"   "$HOME""/mainsail/all/" || echo "! Faild setting symlink to eryone-all script in mainsail folder"


################################################################################################
# Board PINS - Change configuration
# not needed when SKIPR connections changed.
################################################################################################
#echo "ℹ️  Replacing PIN declarations ..."
#read -p "❓ Set PINs on SKIPR Board to Eryone setup? [Y/n]: " answer
#answer=${answer:-N}     # default to "N" if empty
#if [[ "$answer" =~ ^[Yy]$ ]]; then
#    echo "Calling the pin replacement script ..."
#    change_pins_to_eryone_setup.sh || echo "! change_pins_to_eryone_setup.sh could not be found."       # Calls the shell script which is replacing the pins in the cfg files
#else
#    echo "You chose NO"
#    echo "Make sure you changed the hardware connections on the SKIRP board !!!"
#fi

################################################################################################
# restart klipper
################################################################################################
if [[ $INSTALL == "true" ]]; then
  answer="N"
else
  read -p "❓ Restart Klipper? [Y/n]: " answer
  answer=${answer:-Y}     # default to "N" if empty
fi

if [[ "$answer" =~ ^[Yy]$ ]]; then
  echo "Restsrting Klipper"
  sudo systemctl restart klipper
else
  echo "... no"
fi
echo " "


################################################################################################
# Ende
################################################################################################
echo "ℹ️  copy_configs.sh completed."
exit 0;
