#!/usr/bin/env bash
set -euo pipefail

################################################################################################
# File: update.sh
# Author: Eryone / Andreas
# Date: 20250602 / 20250824
# Purpose: update farm3d
#
# not called
################################################################################################
echo "This is /farm3d/update.sh"

echo "Use the /x400-software-pack/scripts/updater.sh"
exit 0


cd $HOME/farm3d
git fetch --all &&  git reset --hard && git pull
chmod 777 *
killall python3 mq.py