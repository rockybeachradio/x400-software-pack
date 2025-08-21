#!/bin/sh

################################################################################################
# File: flashn.sh
# Author: Eryone
# Date: 20250711
# purpose: Updates the firmware via USB1 device.
# 
# !!! not a stable version !!!
#   $(ls /dev/serial/by-id/) can expand to multiple entries → breaks the command. You should pick a specific symlink (or use -u <canbus_uuid> with -i can0).
#
# How to call: ???
# Called in ???
################################################################################################

df                                                                              # shows munted filesystems
echo makerbase | sudo -S cp /home/mks/klipper/out/klipper.uf2 /media/usb1/      # copies the klipper.uf2 firmware to the usb1 device.
#cd /home/mks/klipper/
#make flash FLASH_DEVICE=0483:df11
python3 /home/mks/CanBoot/scripts/flash_can.py -d  /dev/serial/by-id/$(ls /dev/serial/by-id/)  -f /home/mks/klipper/out/klipper.bin     # Uses CanBoot’s flash_can.py to flash klipper.bin to a board indicated by a /dev/serial/by-id symlink.
                                                                                                                                        # $(ls /dev/serial/by-id/) can expand to multiple entries → breaks the command. You should pick a specific symlink (or use -u <canbus_uuid> with -i can0).
sleep 2
sudo -S rm /media/usb1/klipper.uf2      # Removes the klipper.uf2 file from the usb1 device

sync
