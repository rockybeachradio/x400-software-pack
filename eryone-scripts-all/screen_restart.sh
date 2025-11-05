#!/bin/bash

################################################################################################
# File: screen_restart.sh
# Author: Eryone
# Date: 20250711
# purpose: It starts the KlipperScreen service as root
#
# How to call: ???
# Called in ???
################################################################################################

echo makerbase | sudo -S service KlipperScreen restart      # start KlipperScreen as root
exit 0
