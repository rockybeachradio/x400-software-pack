#!/usr/bin/env bash
set -euo pipefail

################################################################################################
# File: run.sh
# Author: Eryone / Andreas
# Date: 20250602 / 20250824
# Purpose: run farm3d
#
# Called in farm3d.service
################################################################################################
echo "This is /farm3d/run.sh"

killall monitor.sh                  # /eryone-scripts-all/monitor.sh is ment.
$HOME/mainsail/all/monitor.sh &     # monitor.sh is doing nothing !!!
                                    # In Eryone original: mainsail/all/ is a symlink to /all/
                                    # & - tells Bash to run it in the background instead of blocking the script.
killall python3 mq.py

#uptime | tee -a /home/mks/printer_data/logs/mq.log
sleep 3 

sudo -S service crowsnest restart

#chmod +x "$HOME""/farm3d" || echo "❌  Faild chmod on farm3d folder"

# Start mq.py
cd $HOME/farm3d/ 
python3 mq.py
