#!/bin/sh +e

################################################################################################
# File: relinkl_conf.sh
# Author: Eryone
# Date: 20250814
# purpose: Copie new fiels and folders from an Eryone update to the appropriate locations and sets right
#
# More details:
#   printer.cfg cleanup
#   Copies folders and files from /KlipperScreen/config/ & /KlipperScreen/all/ & /KliperScreen/klipper/ & KliperScreen/farm3d/ & /KlipperSxcreen/moonraker/moonraker/components 
#   Sets chmod
#   starts and stops services
#
# This script will coninue running, even in error occure: "#!/bin/sh +e"
#
# How to call: ???
# Called in: git_pull.sh
################################################################################################

###########################################################################################
# Celanup: printer.cfg
###########################################################################################
sed -i 's/ERYONE_THR/EECAN/g' /home/mks/printer_data/config/printer.cfg 
sed -i 's/runout1.cfg/runout.cfg/g' /home/mks/printer_data/config/printer.cfg

sed -i 's/runout_p.cfg/runout.cfg/g' /home/mks/printer_data/config/printer.cfg
sed -i 's/EECAN_p.cfg/EECAN.cfg/g' /home/mks/printer_data/config/printer.cfg
sed -i 's/x400_p.cfg/x400.cfg/g' /home/mks/printer_data/config/printer.cfg

sed -i 's/ERYONE_THR/EECAN/g' /home/mks/printer_data/config/canuid.cfg 
sed -i 's/hold_current: 0.5/hold_current: 0.6/g' /home/mks/printer_data/config/printer.cfg 
echo makerbase | sudo -S sed -i 's/txqueuelen 128/txqueuelen 1024/g' /etc/network/interfaces.d/can0

sed   -i '/^.*x400.cfg.*$/,/^.*SAVE_CONFIG.*$/{/^.*x400.cfg.*$/!{/^.*SAVE_CONFIG.*$/!d}}'  /home/mks/printer_data/config/printer.cfg 
sed   -i '/^.*x400_p.cfg.*$/,/^.*SAVE_CONFIG.*$/{/^.*x400_p.cfg.*$/!{/^.*SAVE_CONFIG.*$/!d}}'  /home/mks/printer_data/config/printer.cfg 
#sed  -i '9i [include x400.cfg]' /home/mks/printer_data/config/printer.cfg 

sed -i 's/#\[include KAMP_Settings.cfg\]/[include KAMP_Settings.cfg]/g' /home/mks/printer_data/config/printer.cfg
sed -i 's/ERYONE_EBB36.cfg/ERYONE_36.cfg/g' /home/mks/printer_data/config/printer.cfg


###########################################################################################
# set folder rights
###########################################################################################
chmod 777 /home/mks/KlipperScreen/* -Rf
chmod 777 /home/mks/KlipperScreen/all/*
chmod 777 /home/mks/printer_data/config/*


###########################################################################################
# deleat old folders and files
###########################################################################################
rm /home/mks/klipper -rf
rm /home/mks/mainsail/all -rf
rm /home/mks/printer_data/config/runout.cfg
#rm /home/mks/printer_data/config/KlipperScreen.conf
rm /home/mks/printer_data/config/EECAN.cfg
rm /home/mks/printer_data/config/x400.cfg

#rm /home/mks/printer_data/config/EECAN_p.cfg
#rm /home/mks/printer_data/config/runout_p.cfg
#rm /home/mks/printer_data/config/x400_p.cfg
rm /home/mks/printer_data/config/mainsail.cfg

rm /home/mks/Bed_D* -rf
rm /home/mks/printer_data/config/crowsnest.conf
rm /home/mks/printer_data/config/chamber.cfg


###########################################################################################
# copy files & folders   and deleat
###########################################################################################
cp /home/mks/KlipperScreen/config/timelapse.cfg  /home/mks/moonraker-timelapse/klipper_macro
cp /home/mks/KlipperScreen/config/v1_1.cfg  /home/mks/printer_data/config/
cp /home/mks/KlipperScreen/config/v1_2.cfg  /home/mks/printer_data/config/
cp /home/mks/KlipperScreen/config/EECAN1.cfg /home/mks/printer_data/config/
#rm /home/mks/moonraker/moonraker/components/update_manager/update_manager.py

#ln -s /home/mks/KlipperScreen/moonraker/moonraker/components/update_manager/update_manager.py  /home/mks/moonraker/moonraker/components/update_manager/update_manager.py

cp  /home/mks/KlipperScreen/klipper/ /home/mks/  -rf
ln -s /home/mks/KlipperScreen/all /home/mks/mainsail/all

rm /home/mks/mainsail/all/hostname
echo makerbase | sudo -S ln -s /etc/hostname /home/mks/mainsail/all/hostname

cp /home/mks/KlipperScreen/config/runout.cfg  /home/mks/printer_data/config/runout.cfg
cp /home/mks/KlipperScreen/config/EECAN.cfg  /home/mks/printer_data/config/
#ln -s /home/mks/KlipperScreen/config/runout_p.cfg  /home/mks/printer_data/config/
#ln -s /home/mks/KlipperScreen/config/EECAN_p.cfg  /home/mks/printer_data/config/EECAN_p.cfg
#ln -s /home/mks/KlipperScreen/config/x400_p.cfg  /home/mks/printer_data/config/x400_p.cfg
#cp /home/mks/KlipperScreen/config/KlipperScreen.conf /home/mks/printer_data/config/
cp /home/mks/KlipperScreen/config/crowsnest.conf  /home/mks/printer_data/config/
cp /home/mks/KlipperScreen/config/plr.* /home/mks/printer_data/config/
cp /home/mks/KlipperScreen/config/x400.cfg  /home/mks/printer_data/config/
cp /home/mks/KlipperScreen/config/mainsail.cfg  /home/mks/printer_data/config/

#sed -i 's/z_offset/z_offset = -0.12 #/g' /home/mks/printer_data/config/printer.cfg

rm /home/mks/printer_data/config/moonraker.conf
cp  /home/mks/KlipperScreen/config/moonraker.conf  /home/mks/printer_data/config

cp  /home/mks/KlipperScreen/config/chamber.cfg  /home/mks/printer_data/config

rm  /home/mks/printer_data/logs -rf
ln -s /tmp /home/mks/printer_data/logs

echo makerbase | sudo -S cp /home/mks/KlipperScreen/all/rc.local /etc/rc.local


################################################################################################
#Sync & call HW check script
###########################################################################################
sync
/home/mks/KlipperScreen/all/check_hw_version.sh


###########################################################################################
# Set variables
###########################################################################################
curl -X POST http://127.0.0.1/printer/gcode/script?script=SAVE_VARIABLE%20VARIABLE=needreboot%20VALUE=1
#curl -X POST http://127.0.0.1/printer/gcode/script?script=SAVE_VARIABLE%20VARIABLE=use_ai%20VALUE=1
#curl -X POST http://127.0.0.1/machine/services/restart?service=cloud_mq.service


###########################################################################################
# Service handling 1
###########################################################################################
#echo makerbase | sudo -S service crowsnest restart
echo makerbase | sudo -S systemctl disable moonraker-obico.service


###########################################################################################
# farm3d isntallation
###########################################################################################
cp /home/mks/KlipperScreen/farm3d/  /home/mks/  -rf
chmod 777 /home/mks/farm3d/*
cd /home/mks/KlipperScreen/farm3d
chmod 777 *


################################################################################################
# Create backups
###########################################################################################
echo makerbase | sudo -S mv /usr/lib/armbian/armbian-apt-updates /usr/lib/armbian/armbian-apt-updates_bak
echo makerbase | sudo -S mv /usr/share/unattended-upgrades/unattended-upgrade-shutdown /usr/share/unattended-upgrades/unattended-upgrade-shutdown_bak
echo makerbase | sudo -S mv /etc/systemd/system/klipper-mcu.service /etc/systemd/system/klipper-mcu.serviceb
echo makerbase | sudo -S mv /etc/systemd/system/moonraker-obico.service /etc/systemd/system/moonraker-obico.serviceb


################################################################################################
# Copy moonraker Machine.py
###########################################################################################
cp /home/mks/KlipperScreen/moonraker/moonraker/components/machine.py /home/mks/moonraker/moonraker/components/


################################################################################################
# Service handling 2
###########################################################################################
sync
echo makerbase | sudo -S systemctl disable unattended-upgrades.service
echo makerbase | sudo -S systemctl restart KlipperScreen.service

echo makerbase | sudo -S cp /home/mks/farm3d/farm3d.service    /etc/systemd/system/
echo makerbase | sudo -S systemctl daemon-reload
echo makerbase | sudo -S systemctl enable farm3d.service
echo makerbase | sudo -S systemctl restart farm3d.service

echo makerbase | sudo -S systemctl disable klipper-mcu.service


################################################################################################
# Sync before exit
###########################################################################################
sync
#echo makerbase | sudo -S apt remove unattended-upgrades

exit 0
