#!/usr/bin/env bash
set -euo pipefail

################################################################################################
# File: install_software.sh
# Author: Andreas
# Date: 20250822
# Purpose: Installs software that is needed by x400-software-pack
#
################################################################################################

################################################################################################
# Variables
################################################################################################
folder_of_script="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"


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

if id -nG "$USER" | grep -qw sudo; then
    echo "✅ Benutzer '$USER' ist in der sudo-Gruppe."
else
    echo "❌ Your user '$USER' is not part of the sudo group. Please add your user before executing this script."
    echo "$ su -"
    echo "$ /sbin/adduser '$USER' sudo"
    echo "$ exit"
    exit 1
fi


################################################################################################
# Update Linux
################################################################################################
echo "ℹ️  Updating Linux, components and software ..."
sudo apt update
sudo apt upgrade


################################################################################################
# Install Linux software
################################################################################################
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

################################################################################################
# Install fixes
################################################################################################

###################################################
echo "ℹ️  Install fix for DFU utility ..."
cd /etc/udev/rules.d
sudo wget https://raw.githubusercontent.com/wiieva/dfu-util/refs/heads/master/doc/40-dfuse.rules -O 40-dfuse.rules
sudo usermod -aG plugdev $USER

###################################################
echo "ℹ️  Install fix for Python 3 ..."
cd "$HOME"
sudo apt install python3-pip python3-serial


################################################################################################
# Install printer software
################################################################################################
echo "ℹ️  Install Printer software ..."

###################################################
#TARGET_DIR="kiauh"
#REPO_URL="https://github.com/dw-0/kiauh.git"
#
#cd "$HOME"
#if [[ -d "$TARGET_DIR/.git" ]]; then
#    echo "✅ Repository '$TARGET_DIR' already exists."
#else
#    echo "ℹ️  Installing KIAUH ..."
#    echo "⬇️  Cloning $REPO_URL ..."
#    git clone "$REPO_URL"
#    echo "✅ Clone completed."
#fi

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
fi

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
    make install 
fi

###################################################
# Klipper-backup tool
# https://klipperbackup.xyz
# --> USE KIAUH to install

# cd "$HOME"
# curl -fsSL get.klipperbackup.xyz | bash
# $HOME/klipper-backup/install.sh


################################################################################################
# Install x11vnc
################################################################################################
echo "ℹ️  Installing x11vnc ..."
cd "$HOME"
sudo apt install x11vnc || echo "❌  Installation failed."

echo "ℹ️  Set password for remote access ..."
sudo x11vnc -storepasswd /etc/x11vnc.pass || echo "❌  Setting password failed."

#sudo cp "$config_source""/x11cnv.service" "/lib/systemd/system/" || echo "! Copying service failed."

sudo systemctl enable x11vnc.service || echo "❌  Enabling service failed."
sudo systemctl start x11vnc.service || echo "❌  Starting service failed."


################################################################################################
# Install software needed for farm3d
# The actual famr3d software is installed/updated by /x400-software-pack/scripts/copy_configs.sh 
################################################################################################
echo "ℹ️  Installing needed tools for farm3d ..."
cd "$HOME"
# ???
#pip3 install opencv-python || echo "! Faild pip3 install opencv-python"
# ???
#pip3 install qrcode[pil] || echo "! Faild pip3 install qrcode"


################################################################################################
# Backup script
################################################################################################
echo "ℹ️  Installing needed tools for backup script.."

# Declare variables
local_backup_folder="$HOME/printer_backup"                  # select the path wisely. Backups may contain confidential informations like credentials.
local_backup_folder_files="$local_backup_folder/files"      # When changing the content of local_backup_folder_files, also change the pathin copy_configs.sh and install_software.sh !
local_backup_folder_zip="$local_backup_folder/zip"
github_user_name=""             # rockybeachradio
github_repo_name=""             # x400-backup
github_ssh_key_name=""          # --> x400-backup_ed25519
github_ssh_key_label=""         # --> rockybeachradio_x400-backup
github_encryption="ed25519"
github_ssh_host_name=""         # --> github.com_x400-backup

##############################################################
##############################################################
# Function initiate_github
initiate_github() {
    echo "ℹ️  Initialize GitHub folder for backup ..."
    
    read -p "❓ GitHub user name: " github_user_name
    read -p "❓ GitHub user eMail: " github_user_email
    read -p "❓ GitHub repo name (eg. x400-backup): " github_repo_name

    # Define variables
    github_ssh_key_name="$github_repo_name""_""$github_encryption"
    github_ssh_key_label="key_for_""$github_user_name""_""$github_repo_name"
    github_ssh_host_name="github.com_$github_repo_name"

    # SSH dir + perms
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    ##############################################################
    # Generate SSH Key
    if [[ -f "$HOME/.ssh/$github_ssh_key_name" ]]; then
        echo "ℹ️  SSH key already exists, skipping generation."
    else
        ssh-keygen -t "$github_encryption" -C "$github_ssh_key_label" -f "$HOME/.ssh/$github_ssh_key_name"  -N ""       
            # Generate a dedicated SSH key and adds it tp ~/.sh/config
            # -t ed25519 --> modern, secure, short key
            # -C "..." --> A label (shows up in GitHub)
            # -f ~/.ssh/x400-backup_ed25519 --> Filename for the private key
            # -N --> Creates the SSH key with an empty passphrase (no password).
            # -a 100
            # This creates:
            #   ~/.ssh/x400_backup_ed25519 (private key — keep secret!)
            #   ~/.ssh/x400_backup_ed25519.pub (public key — safe to share)
    fi

    # Append host alias to SSH config (only once)
    if ! grep -q "^Host ""$github_ssh_host_name""$" "$HOME/.ssh/config" 2>/dev/null; then

cat >> $HOME/.ssh/config <<EOF
Host ${github_ssh_host_name}
    HostName github.com
    User git
    IdentityFile ~/.ssh/${github_ssh_key_name}
    IdentitiesOnly yes
EOF
        chmod 600 $HOME/.ssh/config
    fi

    echo
    echo "Prepare GitHub"
    echo "👉 Add this public key as a Deploy Key (with write access) to:"
    echo "   https://github.com/${github_user_name}/${github_repo_name}"
    echo "   Repo → Settings → Deploy keys → Add deploy key (Allow write access)"
    echo "------------------------------------------------------------"
    cat "$HOME/.ssh/$github_ssh_key_name.pub"
    echo "------------------------------------------------------------"
    read -p "Press ENTER after you have added the deploy key..." _
    echo

    #echo "-----------------------------------------------------------------"
    #echo "Option A: Deploy Key (per repo)"
    #echo "Go to your repo → Settings → Deploy keys → Add deploy key"
    #echo "Paste the contents of ~/.ssh/x400-backup_ed25519.pub"
    #echo "Give it a title (e.g., Backup Key)"
    #echo "Enable Allow write access"
    #echo "✅ Scope: only this repo → very safe for backups."
    #echo "-----------------------------------------------------------------"
    #echo "Option B: Account SSH Key"
    #echo "GitHub → Settings → SSH and GPG keys → New SSH key"
    #echo "Paste your .pub file"
    #echo "✅ Scope: your whole account (all repos you have rights to)."
    #echo "⚠️ Bigger blast radius if the private key leaks."
    #echo "-----------------------------------------------------------------"

    ##############################################################
    cd "$local_backup_folder_files"     || { echo "❌  Could not go to files folder: $local_backup_folder_files"; return 1; }

    # Add a .gitignore file to exclude folders/files
cat > .gitignore <<'EOF'
.DS_Store
__pycache__/
git_push.sh
EOF
    #  __pycache__/ is created by Python.

    ##############################################################
    cd "$local_backup_folder_files"     || { echo "❌  Could not go to files folder: $local_backup_folder_files"; return 1; }
    
    if [[ ! -d .git ]]; then    #Is repo not initialized
        git init -b main    || echo "❌  git init - failed"     # Initialize a repo in the empty folder and attach your (private) GitHub repo
    fi

    # Point origin to SSH using the host alias
    git remote remove origin 2>/dev/null || true
    git remote add origin "git@${github_ssh_host_name}:${github_user_name}/${github_repo_name}.git"    # use github.com-x400 (from your ~/.ssh/config). USERNAME/x400-backup.git is your repo path.

    # set identity for this repo (no --global needed)
    git config user.name  "${github_user_name}"
    git config user.email "${github_user_name}@users.noreply.github.com"        # users.noreply.github.com is GitHubs privacy eMsil domain. So the real eMail adress does not need to be in the code.

    echo "Initial add, git and push ..."
    git add -A                          || echo "❌  git add. - failed"
    git commit -m "Initial commit"      || echo "ℹ️  Nothing new to commit"
    git branch -M main      # ensure branch is 'main' (in case git init didn’t use -b main)

    ssh -o StrictHostKeyChecking=accept-new -T "git@${github_ssh_host_name}" || true        # accept GitHub host key the first time (non-interactive)

    git push -u origin main             || echo "❌  git push - failed"       # The -u sets origin/main as the default upstream, so future git push can be just git push

}   # End of initiate_github()
##############################################################
##############################################################

# Install software
sudo apt-get install -y zip                || echo "❌  Installation of zip failed."
sudo apt-get install -y openssh-client     || echo "❌  Installation of openssh-client failed."


##############################################################
# Create folders
rm -rf "$local_backup_folder"           || echo "ℹ️   could not deleat $local_backup_folder"

mkdir -p "$local_backup_folder"        || echo "✅  backup folder already exists"
mkdir -p "$local_backup_folder_files"  || echo "✅  files folder already exists"
mkdir -p "$local_backup_folder_zip"    || echo "✅  zip folder already exists"

##############################################################
# Ask if GitHub shall be set up.
read -p "❓ Do you want to setup GitHub as backup destination? [Y/n]: " answer
answer=${answer:-N}     # default to "N" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    initiate_github       || echo "❌ GitHub setup failed"
    echo "Setting variable github_backup=true in /x400-software-pack/scripts/backup.sh ..."
    if cd $folder_of_script; then
        sed -i 's/github_backup=false/github_backup=true/g' ./backup.sh   || echo "❌ Failed setting variable"    # Set the variable github_backup=true in /x400-software-pack/scripts/backup.sh
    else 
        echo "❌ Could not go to folder: $folder_of_script"
    fi
else
    if cd $folder_of_script; then
        sed -i 's/github_backup=true/github_backup=false/g' ./backup.sh   || echo "❌ Failed setting variable"    # Set the variable github_backup=false in /x400-software-pack/scripts/backup.sh
     else 
        echo "❌ Could not go to folder: $folder_of_script"
    fi
fi


################################################################################################
# Cleaning up
################################################################################################
echo "ℹ️  Clean up ..."
cd "$HOME"
sudo apt autoremove -y modem* cups* pulse* avahi* triggerhappy*


################################################################################################
# Ende
################################################################################################
echo "ℹ️  install_software.sh completed."
exit 0