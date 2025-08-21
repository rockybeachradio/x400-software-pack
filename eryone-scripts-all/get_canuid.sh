#!/bin/sh

################################################################################################
# File: check_version.sh
# Author: Eryone
# Date: 20250711
# purpose: Gets the CAN UUIds and writs them into the canuuid.cfg.
# 
#  !!! BUT with fixed LINES !!! not good!
#
# How to call: ???
#
# Called in ???
################################################################################################

#sleep 5

#echo makerbase | sudo -S cp /media/usb1/hostname /etc/
#taskset -c 3 /home/pi/oprint/bin/python2 /home/pi/oprint/bin/octoprint serve --host=127.0.0.1 --port=5000
#/home/mks/klippy-env/bin/python  /home/mks/klipper/scripts/canbus_query.py can0  | sed 's/^.*Found canbus_uuid=/canbus_uuid:/g' | sed 's/,.*$//g'  | sed 's/Total.*$//g'  > /home/mks/printer_data/config/canuid.cfg
#sed  -i '1i [mcu]' /home/mks/printer_data/config/canuid.cfg
#sed  -i '3i [mcu EECAN]' /home/mks/printer_data/config/canuid.cfg

#echo makerbase | sudo -S cp /home/mks/klipper/out/klipper.uf2 /media/usb1/
#python3 /home/mks/CanBoot/scripts/flash_can.py -d  /dev/serial/by-id/$(ls /dev/serial/by-id/)  -f /home/mks/klipper/out/klipper.bin
#sleep 2
#sudo -S rm /media/usb1/klipper.uf2

$HOME/klippy-env/bin/python  $HOME/klipper/scripts/canbus_query.py can0  | sed 's/^.*Found canbus_uuid=/canbus_uuid:/g' | sed 's/,.*$//g'  | sed 's/Total.*$//g'  > $HOME/printer_data/config/canuid.cfg
sed  -i '1i [mcu]' $HOME/printer_data/config/canuid.cfg
sed  -i '3i [mcu EECAN]' $HOME/printer_data/config/canuid.cfg

cat  $HOME/printer_data/config/canuid.cfg

sync

