#!/usr/bin/env bash
set -euo pipefail

################################################################################################
# File: git_initiate.sh
# Author: Andreas
# Date: 20250827
# Purpose: Initiate a local folder as repo, setup connection to GitHub using SSH to authentication, and initial upload local folder content to GitHub repo.
################################################################################################
#
# How to call initate_github()
#   $ initate_github <local_git_folder> (optional branch, eg. main)
#   $ initate_github "$HOME/printer_backup/files"
#       - When changing the content of local_backup_folder_files, also change the path in copy_configs.sh and install_software.sh !
#       - Choose the path wisely. Backups may contain confidential informations like credentials.
#
# How to use it
#   $ source ./git_initiate.sh   # or chmod +x and run the file
#   $ initiate_github "$HOME/printer_backup/files" main


# Function initiate_github
initiate_github() {
    echo "ℹ️  Initialize GitHub folder ..."

    ################################################################################################
    # Variable
    ################################################################################################
    ##############################################################
    # Get parameters handed over
    local local_backup_folder="$1"      # eg. =$HOME/printer_backup/files

    ##############################################################
    # Declare variables
    local branch="${2:-main}"
    local gh_ssh_host="github.com"
    local gh_ssh_user="git"
    local commit_msg="Initial commit"

    local github_user_name=""             # rockybeachradio
    local github_repo_name=""             # x400-backup
    local github_ssh_key_name=""          # --> x400-backup_ed25519
    local github_ssh_key_label=""         # --> rockybeachradio_x400-backup
    local github_encryption="ed25519"     # --> Encryption type
    local github_ssh_host_name=""         # --> github.com_x400-backup

    
    ##############################################################
    # Ask for user input
    read -p "❓ GitHub user name: " github_user_name
    # read -p "❓ GitHub user eMail: " github_user_email
    read -p "❓ GitHub repo name (eg. x400-backup): " github_repo_name

    # Generate variables based on input
    github_ssh_key_name="$github_repo_name""_""$github_encryption"
    github_ssh_key_label="key_for_""$github_user_name""_""$github_repo_name"
    github_ssh_host_name="$gh_ssh_host""_""$github_repo_name"


    ##############################################################
    # Validate input parameters
    if [ -z "$local_backup_folder" ]; then
        echo "❌  No local backup folder was handed over to the script."
        return 1
    fi
    if [ -z "$github_user_name" ]; then
        echo "❌  GitHub user name is required."
        return 1
    fi
    if [ -z "$github_repo_name" ]; then
        echo "❌  GitHub repo name is required."
        return 1
    fi


    ################################################################################################
    # SSH setup
    ################################################################################################
    ##############################################################
    # Generate the .ssh folder in the user`s home directory
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

    ##############################################################
    # Add host infos to SSH config file
    if ! grep -q "^Host ""$github_ssh_host_name""$" "$HOME/.ssh/config" 2>/dev/null; then
cat >> "$HOME/.ssh/config" <<EOF
Host ${github_ssh_host_name}
    HostName github.com
    User git
    IdentityFile ~/.ssh/${github_ssh_key_name}
    IdentitiesOnly yes
EOF
        chmod 600 "$HOME/.ssh/config"
    fi


#    # MacOS friendly SSH setup. Using KeyChain: ~/.ssh/config entry
#    if ! grep -q "^Host ${github_ssh_host_name}\$" "$HOME/.ssh/config" 2>/dev/null; then
#        {
#           echo "Host ${github_ssh_host_name}"
#           echo "  HostName ${gh_ssh_host}"
#           echo "  User ${gh_ssh_user}"
#           echo "  IdentityFile ~/.ssh/${github_ssh_key_name}"
#           echo "  IdentitiesOnly yes"
#           echo "  AddKeysToAgent yes"
#           echo "  UseKeychain yes"
#        } >> "$HOME/.ssh/config"
#        chmod 600 "$HOME/.ssh/config"
#    fi


    ##############################################################
    # Output for user
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

    # Pre-accept GitHub host key (non-interactive the first time)
    ssh -o StrictHostKeyChecking=accept-new -T "${gh_ssh_user}@${github_ssh_host_name}" || true     # Accept GitHub host key the first time (non-interactive)


    ################################################################################################
    # Git
    ################################################################################################
    cd "$local_backup_folder"

    # Add a .gitignore file to exclude folders/files
cat > "$local_backup_folder/.gitignore" <<'EOF'
.DS_Store
__pycache__/
git_push.sh
EOF
    #  __pycache__/ is created by Python.


    ################################################################################################
    # Git commands
    ################################################################################################
    # Initialize repo (new branch if supported)
    if git rev-parse --git-dir >/dev/null 2>&1; then
        echo "ℹ️  Git repo already initialized here."
    else
        if git init -b "$branch" >/dev/null 2>&1; then
            :
        else
            git init
            git checkout -b "$branch"   || echo "❌  git init - failed"     # Initialize a repo in the empty folder and attach your (private) GitHub repo
        fi
    fi

    # Point origin to SSH using the host alias
    git remote remove origin 2>/dev/null || true
    git remote add origin "git@${github_ssh_host_name}:${github_user_name}/${github_repo_name}.git"    # use github.com-x400 (from your ~/.ssh/config). USERNAME/x400-backup.git is your repo path.

    # set identity for this repo (no --global needed)
    git config user.name  "${github_user_name}"
    git config user.email "${github_user_name}@users.noreply.github.com"        # users.noreply.github.com is GitHubs privacy eMsil domain. So the real eMail adress does not need to be in the code.

    ###################################################
    echo "Initial add, git and push ..."
    git add -A                       || echo "❌  git add. - failed"
    git commit -m "$commit_msg"      || echo "ℹ️  Nothing new to commit"
    #git branch -M main      # ensure branch is 'main' (in case git init didn’t use -b main)

    # If remote is empty → normal push; if not → pull --rebase then push
    if git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
        # Remote has the branch (e.g., initialized with README)
        git pull --rebase origin "$branch" || true
    fi
    git push -u origin "$branch" || {     # The -u sets origin/main as the default upstream, so future git push can be just git push
        echo "⚠️  Push failed — attempting rebase from remote then push."
        git pull --rebase origin "$branch" || true  # bring remote main in, replay your commits on top
        git push -u origin "$branch"    
    }

    ################################################################################################
    echo "✅  Done. Remote: origin → git@${github_ssh_host_name}:${github_user_name}/${github_repo_name}.git"
}   # End of initiate_github()