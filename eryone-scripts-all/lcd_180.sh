#!/bin/bash

################################################################################################
# File: lcd_180.sh
# Author: Eryone
# Date: 20250711
# purpose: Rotate the LCD screen if in 10-evdec.conf defined to do.
#
# How to call: ???
# Called in ???
################################################################################################

#input= cat /usr/share/X11/xorg.conf.d/10-evdev.conf
#echo input

echo makerbase | sudo -S mount -o remount,ro /boot                              # mounting /boot as read-only

input=$(sed -n '/ Option/'p /usr/share/X11/xorg.conf.d/10-evdev.conf |wc -l)    # Counts how many lines in /usr/share/X11/xorg.conf.d/10-evdev.conf match the regex Option
echo $input

#if[ ! $# == 2 ]; then
if [ $input -eq 1 ] ; then                            # If the count equals 1
  xrandr -display :0.0 -q --verbose -o inverted       # use "xrandr" on X display "":0.0" to rotate the screen "inverted" (180°).
else
  echo ""normal
fi

#while [ 1 ]
#do
#    sleep 3
#    log_t=$(/home/mks/mainsail/all/check_version.sh)
#    echo $log_t
#done
#killall monitor.sh
#/home/mks/mainsail/all/monitor.sh &
#killall python3 mq.py
#cd /home/mks/KlipperScreen/mqtt
#chmod 777 *
#python3 mq.py &
#python3 /home/mks/mainsail/all/qr.py
#/home/mks/mainsail/all/reboot_check.sh
#echo makerbase | sudo -S service moonraker-obico stop

exit 0
