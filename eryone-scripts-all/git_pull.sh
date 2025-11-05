#!/bin/sh +e

################################################################################################
# File: git_pull.sh
# Author: Eryone / commented by Andreas
# Date: 20250806
# purpose: Pullls new version from git and calls: relink_conf.sh
# 
# Called in the x400_shell_commands_macros.cfg file
################################################################################################

cd  /home/mks/KlipperScreen
rm -f .git/index                        # Deletes Git’s index (the staging area) file. This is a last-resort fix for a corrupted index. It throws away whatever was staged. You almost never need this unless you saw errors like “index file corrupt.”
git reset                               # Unstages everything (index = HEAD), leaves working files untouched. Often redundant here.
git fetch --all &&  git reset --hard origin/master && git pull
# git fetch --all                       # Fetches updates from all remotes (not just origin). Most projects only need git fetch origin.
# git reset --hard origin/master        # Make your current branch and files exactly match origin/master. Local uncommitted changes to tracked files are lost.
# git pull                              #Equivalent to git fetch + git merge (or rebase if configured).
#                                       # Right after a --hard reset to origin/master, this usually does nothing (you’re already at the same commit). It only makes sense if the remote advanced in the tiny window after the previous fetch.

sync
chmod 777 /home/mks/KlipperScreen/* -Rf
chmod 777 /home/mks/KlipperScreen/all/relink_conf.sh
sync
/home/mks/KlipperScreen/all/relink_conf.sh
sync
#/home/mks/KlipperScreen/all/install_lib.sh
sync

exit 0
