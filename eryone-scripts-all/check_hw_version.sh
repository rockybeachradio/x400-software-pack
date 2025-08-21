#!/bin/bash

################################################################################################
# File: check_hw_version.sh
# Author: Eryone
# Date: 20250711
# purpose: Checks which hardware the x400 has. Based on the result it changes the printer.cfg to laod the rifght version v1_x.cfg file.
# 
# How to call: ???
#
# Called in ???
################################################################################################

local_version=$(cat /home/mks/printer_data/config/printer.cfg )
#echo $local_version

ver_string="v1_"
#to see if it contain the 'v1_' else timeout
if [[ $local_version =~ $ver_string ]]          # Check if the printer.cfg file countauns "v1_".
then
    echo "Has hardware version"
else
    echo "No hardware version"    
    sed -i '2a\[include v1_1.cfg]' /home/mks/printer_data/config/printer.cfg
fi
