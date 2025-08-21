#!/bin/sh +e

################################################################################################
# File: new_git.sh
# Author: Eryone
# Date: 20250711
# purpose: Downlads the new Eryone x400 firmware from the repository and starts relink_conf.sh
#
# How to call: ???
# Called in ???
################################################################################################

rm /home/mks/KlipperScreen/ -rf
git clone https://gitcode.com/xpp012/KlipperScreen.git /home/mks/KlipperScreen
sync
chmod 777 /home/mks/KlipperScreen/* -Rf
chmod 777 /home/mks/KlipperScreen/all/relink_conf.sh
sync
/home/mks/KlipperScreen/all/relink_conf.sh
sync

exit 0
