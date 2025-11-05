#!/bin/bash
set -euo pipefail

################################################################################################
# File: backup.sh
# Author: Andreas
# Date: 20250819
# Purpose: Backup of the configuration files
#
# The GitHub repo used to push the backups (defined in the vairbale: local_backup_folder_files) mus be prepared.
# Initiate the folder as a local git repo, synced to the GitHub repo ith git clone.
# The GitHub repo should be a private repo.
# If git asks request a username and passwort, the password is a personal access token which needs to be generated in the GitHub Website.
# GutHub: Logo --> Settings --> Developer settings --> Personal access tokens --> Fine-grade tokens
#
################################################################################################
echo "This is $(basename "$0")"

################################################################################################
# Variables
################################################################################################

# folder and files
local_backup_folder="$HOME/printer_backup"                  # select the path wisely. Backups may contain confidential informations like credentials.
local_backup_folder_files="$local_backup_folder/files"      # When changing the content of local_backup_folder_files, also change the pathin copy_configs.sh and install_software.sh !
local_backup_folder_zip="$local_backup_folder/zip"

##############################################################
# Files and folders to backup
#   path needs to start from root. The files and fodlers are separated by line. Examples for file and fodler:
#   filder: $HOME/printer_data/config/
#   file: $HOME/mainsail-config/client.cfg
TO_BACKUP=(
  $HOME/printer_data/config/
  $HOME/printer_data/database/
  $HOME/mainsail-config/client.cfg
  $HOME/moonraker-timelapse/klipper_macro/timelapse.cfg
  $HOME/Klipper-Adaptive-Meshing-Purging/Configuration
  $HOME/klipper-backup/.env
  /etc/network/interfaces.d/can0
  )

##############################################################
# smb
smb_upload=false                            # Shall the zip file be uploaded to a SMB share?
smb_backup_folder="/mnt/smbsahre"           # select the share wisely. Backups may contain confidential informations like credentials.
smb_deleat_files_after=180                  # Files older than x day will be deleated on smb share

#GitHub
github_upload=true                          # Shall the files be uploaded to GitHub repo?
git_script=git_push.sh

##############################################################
d=$(date +%Y-%m-%d_%H_%M)         # Get the date
backup_file="backup_${d}.zip"     # Generate the zip file name


################################################################################################
# Backup routine
################################################################################################
echo The files will be backed up to "$local_backup_folder" as individual files and zip
echo And copied to "$smb_backup_folder". Files older than 180 day will be deleated
echo and uploaded to GitHub.
echo The files backed up may contain confidential informations like credentials. So be carefull where you store the backups.

##############################################################
echo "ℹ️  Copy files to backup folder ..."
# rm -rf "$local_backup_folder_files""/*"  || echo "❌  Failed deleating the folder content of ""$local_backup_folder_files"    # Deleats all fiels in the folder
find "$local_backup_folder_files" -mindepth 1 ! -name "$git_script" -exec rm -rf {} +   || echo "❌  Failed deleating the folder content of ""$local_backup_folder_files"
  # Will niot deleat the excluded file.
  # >-mindepth 1< - prevents deleting the directory itself. >! -name 'git_push.sh'< - exclude that file. >-exec rm -rf {} +< delete everything else.

# Copy files/folders to destionation fodler
for f in "${TO_BACKUP[@]}"; do
    cp "$f" "$local_backup_folder_files/"  || echo "❌  Faild copying ""$f"
done


##############################################################
echo "ℹ️  Creating zip file and copy to backup folder ..."
rm -f "$local_backup_folder_files/$backup_file"  || echo "no backup file to deleat"   # Deleat a backup file which may exists.

zip -r "$local_backup_folder_files/$backup_file" "${TO_BACKUP[@]}"    # "${TO_BACKUP[@]}" - Expands to each path in the array as a separate argument (important, otherwise spaces in filenames break).

#zip -r "$local_backup_folder_files""/""$backup_file" \
#  "$HOME/printer_data/config" \
#  "$HOME/mainsail-config/client.cfg" \
#  "$HOME/moonraker-timelapse/klipper_macro/timelapse.cfg" \
#  "$HOME/Klipper-Adaptive-Meshing-Purging/Configuration" \
#  "$HOME/klipper-backup/.env" \
#  "/etc/network/interfaces.d/can0"


##############################################################
if smb_upload=true; then
  echo "ℹ️  Copy zip file to smb share ..."
  if mountpoint -q "$smb_backup_folder"; then
    mkdir -p "$smb_backup_folder"
    cp -f "$local_backup_folder_files""/""$backup_file" "$smb_backup_folder""/"
  else
    echo "!  $smb_backup_folder is not mounted. Could not copy backup to smb share." >&2
  fi

  find "$local_backup_folder_files" -type f -mtime +"$smb_deleat_files_after" -delete     # Deleat backups which are older than xxx days.
fi

##############################################################
if github_upload=true; then
  echo "ℹ️  "Upload files to GitHub ...
  echo "Calling the GitHub uploader"

  cd $local_backup_folder_files  || { echo "❌  Could not go to directory: $local_backup_folder_files"; exit 1; }
  "./$git_script" -m "backup_${d}""   || echo "❌   git_push.sh could not be called"    #git_push.sh options: -b main -t "${d}" -T "backup as of ${d}"
fi

##############################################################
echo "ℹ️  $(basename "$0")completed."#
exit 0