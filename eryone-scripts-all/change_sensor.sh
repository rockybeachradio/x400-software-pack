#!/bin/bash

################################################################################################
# File: change_sensor.sh
# Author: Eryone
# Date: 20250711
# purpose: Clean up the printer.cfg file --> Replaces "xxx_p.cfg" filenames with the version without "_p".
# 
# How to call: ???
#
# Called in ???
################################################################################################

#sleep 5

name=$1
sed -i 's/runout.cfg/runout_p.cfg/g' /home/mks/printer_data/config/printer.cfg
sed -i 's/x400.cfg/x400_p.cfg/g' /home/mks/printer_data/config/printer.cfg
sed -i 's/EECAN.cfg/EECAN_p.cfg/g' /home/mks/printer_data/config/printer.cfg
sed -i 's/z_offset/z_offset = -0.12 #/g' /home/mks/printer_data/config/printer.cfg

sed -i 's/x401.cfg/x400_p.cfg/g' /home/mks/printer_data/config/printer.cfg
sed -i 's/EECAN01.cfg/EECAN_p.cfg/g' /home/mks/printer_data/config/printer.cfg
sed -i 's/runout2.cfg/runout_p.cfg/g' /home/mks/printer_data/config/printer.cfg

#echo makerbase | sudo -S sed -i '1c '${name}'' /etc/hostname
#echo makerbase | sudo -S sed -i '1c '${name}'' /etc/hostname
#echo makerbase | sudo -S cp /media/usb1/hostname /etc/
#taskset -c 3 /home/pi/oprint/bin/python2 /home/pi/oprint/bin/octoprint serve --host=127.0.0.1 --port=5000
#/home/mks/klippy-env/bin/python  /home/mks/klipper/scripts/canbus_query.py can0  | sed 's/^.*Found canbus_uuid=/canbus_uuid:/g' | sed 's/,.*$//g'  | sed 's/Total.*$//g'  > /home/mks/printer_data/config/canuid.cfg
#sed  -i '1i [mcu]' /home/mks/printer_data/config/canuid.cfg
#sed  -i '3i [mcu EECAN]' /home/mks/printer_data/config/canuid.cfg

#echo makerbase | sudo -S cp /home/mks/klipper/out/klipper.uf2 /media/usb1/
#python3 /home/mks/CanBoot/scripts/flash_can.py -d  /dev/serial/by-id/$(ls /dev/serial/by-id/)  -f /home/mks/klipper/out/klipper.bin
#echo changed name successfully

sync

