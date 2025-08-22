#!/bin/sh +e

################################################################################################
# File: recovery.sh
# Author: Eryone / commented by Andreas
# Date: 20250711
# purpose: Downloads the newest version of the Eryone Sfotware from GitHuband calls relink_conf.sh
#
# How to call: ???
# Called in ???
################################################################################################

cd  /home/mks/KlipperScreen
rm -f .git/index                    # Deletes Git’s index (the staging area) file. This is a last-resort fix for a corrupted index. It throws away whatever was staged. You almost never need this unless you saw errors like “index file corrupt.”
git reset                           # Recreates the index from the current commit (HEAD) and unstages everything. Your working tree files are left as they are.
git reset --hard origin/master      # Moves your current branch to exactly origin/master, overwriting tracked changes in the working tree and index to match the remote.

chmod 777 /home/mks/KlipperScreen/* -Rf
chmod 777 /home/mks/KlipperScreen/all/relink_conf.sh

/home/mks/KlipperScreen/all/relink_conf.sh
#$HOME/KlipperScreen/all/install_lib.sh

curl -X POST http://127.0.0.1/printer/gcode/script?script=SAVE_VARIABLE%20VARIABLE=needreboot%20VALUE=1
sync
exit 0
