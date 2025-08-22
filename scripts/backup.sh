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
local_backup_folder="$HOME/printer_backup"    # select the path wisely. Backups may contain confidential informations like credentials.
smb_backup_folder="/mnt/smbsahre"             # select the share wisely. Backups may contain confidential informations like credentials.
backup_file="backup_${d}.zip"


################################################################################################
# Backup
################################################################################################
echo The files will be backed up to "$local_backup_folder" and copied to "$smb_backup_folder".
echop The files you backup may contain confidential infromations like credentials. So be carefull where you store the backups.

rm -f "$local_backup_folder/$backup_file"   # Deleat a backup file which may exists.

# Local backup
zip -r "$local_backup_folder""/""$backup_file" \
  "$HOME/printer_data" \
  "$HOME/mainsail-config/client.cfg" \
  "$HOME/moonraker-timelapse/klipper_macro/timelapse.cfg" \
  "$HOME/Klipper-Adaptive-Meshing-Purging/Configuration" \
  "$HOME/KlipperBackup/.env" \
  "/etc/network/interfaces.d/can0"
  # ??? Eryone famr3D config file 

# copy backup file to smbshare
if mountpoint -q "$smb_backup_folder"; then
  mkdir -p "$smb_backup_folder"
  cp -f "$local_backup_folder""/""$backup_file" "$smb_backup_folder""/"
else
  echo "!  $smb_backup_folder is not mounted. Could not copy backup to smb share." >&2
fi

find "$local_backup_folder" -type f -mtime +180 -delete     # Deleat backups which are older than xxx days.
