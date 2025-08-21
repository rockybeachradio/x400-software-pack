#!/bin/bash

################################################################################################
# File: reboot_check.sh
# Author: Eryone
# Date: 20250711
# purpose: In varbiables.cfg set the entry needrebboot to 0
#
# This is not doiung anyting !!
#
# How to call: ???
# Called in ???
################################################################################################

variable_str=$(cat /home/mks/printer_data/config/variable.cfg)      # reads the whole file
echo $variable_str

ver_string="needreboot = 1"     # defines the variable

if [[ $variable_str =~ $ver_string ]]   # If file countains "needreboot = 1"
then
    echo "clear the flag of reboot"
   # sed -i 's/needreboot = 1/needreboot = 0/g' /home/mks/printer_data/config/variable.cfg
   # curl -X POST http://127.0.0.1/printer/gcode/script?script=SAVE_VARIABLE%20VARIABLE=needreboot%20VALUE=0
else
    echo "no need to reboot"
fi
