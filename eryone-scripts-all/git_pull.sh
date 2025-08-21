#!/bin/sh +e

################################################################################################
# File: git_pull.sh
# Author: Eryone
# Date: 20250806
# purpose: Pullls new version from git and calls: relink_conf.sh
# 
# Called in the x400_shell_commands_macros.cfg file
################################################################################################

cd  /home/mks/KlipperScreen
rm -f .git/index
git reset
git fetch --all &&  git reset --hard origin/master && git pull
sync
chmod 777 /home/mks/KlipperScreen/* -Rf
chmod 777 /home/mks/KlipperScreen/all/relink_conf.sh
sync
/home/mks/KlipperScreen/all/relink_conf.sh
sync
#/home/mks/KlipperScreen/all/install_lib.sh
sync

exit 0
