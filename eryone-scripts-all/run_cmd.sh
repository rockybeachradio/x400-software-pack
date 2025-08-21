#!/bin/bash

################################################################################################
# File: run_cmd.sh
# Author: Eryone
# Date: 20250711
# purpose: Run as root wrapper - Executes any given command in bash with sudo.
#
# How to call: ???
# Called in ???
################################################################################################

#sleep 5

name=$1                                         # Stores the first argument in the varibale name.
echo makerbase | sudo -S $1 $2 $3 $4 $5 $6      # runs the vontent of the vairable in the command.
