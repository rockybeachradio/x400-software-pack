#!/bin/bash
set -euo pipefail

################################################################################################
# File: backup.sh
# Author: Andreas
# Date: 20250819
# Purpose: Backup of the configuration files
#
################################################################################################

################################################################################################
# Variables
################################################################################################
d=$(date +%Y-%m-%d_%H_%M)
local_backup_folder="$HOME""/x400-software-pack/backups"
smb_backup_folder="/mnt/smbsahre"
backup_file="backup_${d}.zip"


################################################################################################
# Backup
################################################################################################

rm -f "$local_backup_folder/$backup_file"   # Deleat a backup file which may exists.

# Local backup
zip -r "$local_backup_folder""/""$backup_file" \
  "$HOME/printer_data" \
  "$HOME/mainsail-config/client.cfg" \
  "$HOME/moonraker-timelapse/klipper_macro/timelapse.cfg" \
  "$HOME/Klipper-Adaptive-Meshing-Purging/Configuration" \
  "/etc/network/interfaces.d/can0"

# copy backup file to smbshare
if mountpoint -q "$smb_backup_folder"; then
  mkdir -p "$smb_backup_folder"
  cp -f "$local_backup_folder""/""$backup_file" "$smb_backup_folder""/"
else
  echo "!  $smb_backup_folder is not mounted. Could not copy backup to smb share." >&2
fi

find "$local_backup_folder" -type f -mtime +180 -delete     # Deleat backups which are older than xxx days.
