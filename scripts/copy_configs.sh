#!/usr/bin/bash
set -euo pipefail

################################################################################################
# File: copy_configs.sh
# Author: Andreas
# Date: 20250822
# Purpose: Copies all Confgiruations file to the locations so the printer software can use it   &   Installing Eryone farm3d.
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


################################################################################################
# Include helper scripts
################################################################################################
source read_write_config_files.sh      # Include shell script with the read and write function for configuratin files.


################################################################################################
# Variables
################################################################################################
source_base="$HOME""/x400-software-pack"
config_source="$HOME""/x400-software-pack/configurations"
config_destination="$HOME""/printer_data/config"
INSTALL=false

github_username=""
github_repository=""
github_token=""


################################################################################################
# Get parameters
################################################################################################
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--behavior)
      INSTALL=true; shift ;;
    -h|--help)
      echo "Usage: $0 -i"
      echo "i = install - Will override some files with customer settings. update not."
      exit 2 ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Use --help for usage."; exit 2 ;;
  esac
done


################################################################################################
# Dobule check that all the preparation is done.
################################################################################################
read -p "❓ This script will evetnually override existing files and fodlers. Contiue? [Y/n]: " answer
answer=${answer:-N}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Okay, letzt start ..."
else
    echo "See you later."
    exit 0;
fi


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
    eryone_stuff.cfg
    chamber_temp_mgmt.cfg
    Andreas_extensions.cfg
    variable.cfg
    plr.sh
    crowsnest.conf
    KlipperScreen.conf
    moonraker.conf
    moonraker-obico.cfg
    )


# Copy to printer_data/config/
for f in "${files[@]}"; do
    cp "$config_source""/""$f" "$config_destination/"  || echo "❌  Faild copying ""$f"
done


################################################################################################
# Configuration files - Copy fiels to spezial destinations
################################################################################################
echo "ℹ️  Copy config files to spezial folders ..."
cp "$config_source""/mainsail-client.cfg" "$HOME""/mainsail-config/client.cfg"  || echo "❌  Faild copying mainsail-client.cfg"
cp "$config_source""/timelapse.cfg" "$HOME""/moonraker-timelapse/klipper_macro/timelapse.cfg"   || echo "❌  Faild copying timelapse.cfg"


################################################################################################
# Configuration files - Copy only during installation
################################################################################################
if $INSTALL=true; then
    echo "ℹ️  Copy/override config files which were customised by users ..."
    #cp "$config_source""/klipper-backup env.conf" "$HOME/klipper-backup/.env"   || echo "❌  Faild copying KlipperBackup env.cfg"  # --> Initial copy in install_software.sh. And here in "Klipper-Backup"
    cp "$config_source""/canuid.cfg" "$config_destination/"   || echo "❌  Faild copying canuid.cfg"
fi


################################################################################################
# Configuration files - Create Symlinks
################################################################################################
echo "ℹ️  Creating Symlinks ..."
ln -sfn "$HOME""/mainsail-config/mainsail.cfg"                      "$config_destination""/mainsail.cfg"  || echo "❌  Faild setting symlink to mainsail.cfg"
ln -sfn "$HOME""/moonraker-timelapse/klipper_macro/timelapse.cfg"   "$config_destination""/timelapse.cfg" || echo "❌  Faild setting symlink to timelapse.cfg"
ln -sfn "$HOME""/Klipper-Adaptive-Meshing-Purging/Configuration/"   "$config_destination""/KAMP" || echo "❌  Faild setting symlink to KAMP configuration folder"


################################################################################################
# KlipperScreen panels  - Copy
################################################################################################
echo "ℹ️  Add KlipperScreen panels ..."
cp "$source_base""/eryone-KlipperScreen-panels/"* "$HOME""/KlipperScreen/panels/" || echo "❌  Faild copying Klipper-panels."


################################################################################################
# Network interce  - Copy
################################################################################################
echo "ℹ️  Add Network interfaces ..."
sudo cp "$config_source""/can0.conf" "/etc/network/interfaces.d/can0" || echo "❌  Faild copying network interface can0."


################################################################################################
# Firnware config - Copy
################################################################################################
echo "ℹ️  Copy Klipper firmware configurations ..."
cp "$source_base""/firmware-configurations/stm32f407_firmware.config" "$HOME""/klipper/" || echo "❌  Faild copying stm32f407_firmare.config."
cp "$source_base""/firmware-configurations/rp2040_firmware.config" "$HOME""/klipper/" || echo "❌  Faild copying rp2040_firmware.config."

echo "ℹ️  Copy Katapult bootloader configuratons ..."
cp "$source_base""/firmware-configurations/stm32f407_katapult.config" "$HOME""/katapult/" || echo "❌ Faild copying stm32f407_katapult.config."
cp "$source_base""/firmware-configurations/rp2040n_katapult_usb.config" "$HOME""/katapult/" || echo "❌  Faild copying rp32040_katapult.config."

#echo "Copy sensor firmware configuration ..."
## sensor with stm32 chip on RP2040 board
#cp "$source_base""/firmware-configurations/sensor_on_rp2040_firmware.config" "$HOME""/klipper/" || echo "❌  Faild copying sensor_on_rp2040_firmware.config."
#cp "$source_base""/firmware-configurations/sensor_on_rp2040_katapult.config" "$HOME""/katapult/" || echo "❌  Faild copying sensor_on_rp2040_katapult.config."


################################################################################################
# x11vnc - Copy
################################################################################################
echo "ℹ️  Copy x11cnv.service ..."
sudo cp "$config_source""/x11cnv.service" "/lib/systemd/system/" || echo "❌  Copying service failed."


################################################################################################
# backup script  - helper
################################################################################################
echo "ℹ️  Copy Backup script - helper ..."
cp "$source_base""/scripts/git_push.sh" "$HOME/printer_backup/files/" || echo "❌  Faild copying git_push.sh to backup folder."


################################################################################################
# Klipper-Backup  - Create symlinks, to allow Klipper-Backup to backup files outside of the user`s folder
################################################################################################
TARGET_DIR="klipper-backup"
REPO_URL="get.klipperbackup.xyz"

klipperbackup_dir="$HOME/$TARGET_DIR"
klipperbackup_file="$klipperbackup_dir/.env"

echo "ℹ️  Copy Klipper-Backup ..."
mkdir -p "$HOME/printer_data/symlinks_for_backup/"   || echo "❌  creating the /printer_data/symlink symlinks_for_backup/"
sudo ln -sfn "/etc/hostname"                     "$HOME/printer_data/symlinks_for_backup/hostname"      || echo "❌  Faild setting symlink /printer_data/symlinks_for_backup/hostname"
sudo ln -sfn "/etc/network/interfaces.d/can0"    "$HOME/printer_data/symlinks_for_backup/can0"          || echo "❌  Faild setting symlink /printer_data/symlinks_for_backup/can0"

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


################################################################################################
# farm3d - Copy and call .install
# source: eryone-scripts-all/install_lib.sh
################################################################################################
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


################################################################################################
# Eryone script - Copy
################################################################################################
#echo "ℹ️  Create symling to Eryone scripts ..."
#ln -sfn "$source_base""/eryone-scripts-all/"   "$HOME""/mainsail/all/" || echo "! Faild setting symlink to eryone-all script in mainsail folder"


################################################################################################
# Board PINS - CHange configuration
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
# Ende
################################################################################################
echo "ℹ️  copy_configs.sh completed."
exit 0;
