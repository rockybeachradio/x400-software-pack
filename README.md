Welcome, to my software pack for the Eryone Thinker x400

# Information about this project
This is an alternative Firmware for the Eryone Thinker x400 \
    https://github.com/rockybeachradio/x400-software-pack \
 \
 This uses a RaspberryPi 5 instead using the MKS SKIPR SoC. \
 The cfg files may be compatible for the SKIPR SoC. But is untested.\
 \
It is based on https://github.com/rockybeachradio/x400-software-pack_mks-soc \
For information what was changed comapred to the original Eryone Firmware, may be found there. \
 \


# Known bugs
- [ ] at24c_eeprom: Error during Klipper start.


# Backlog:

## To check Eryone Stuff:
- [ ] at24c_eeprom by Eryone
- [ ] farm3d by Eryone
- [ ] Scripts by Eryone
- [ ] KlipperScreen panels by Eryone

## ToDo
- [ ] Remove "duplicate_pin_override" in chamber_temp_mgmt.cfg --> Software solution, or another temperature sensor


## Check why eryone has spezial versions and is not using the original ones. (commands found in relink_conf.sh)
- [ ] cp /home/mks/KlipperScreen/moonraker/moonraker/components/machine.py /home/mks/moonraker/moonraker/components/       - Check what is different in the Eryone version
- [ ] cp /home/mks/KlipperScreen/config/timelapse.cfg  /home/mks/moonraker-timelapse/klipper_macro/                        - Check what is different in the Eryone version
~~- [ ] cp  /home/mks/KlipperScreen/klipper/ /home/mks/  -rf~~
- [ ] How is KlipperScreen calling eryone scripts? Where are the scripts used?
    - ln -s /home/mks/KlipperScreen/all /home/mks/mainsail/all

## Check why these files are in the eryone repo compared to the original repos.
- [ ] Eryone Scripts /all/ --> Where are they used?
- [ ] Eryone /KlipperScreen/ --> Check
    - /KlipperScreen/Panels/ - What are they doing?
        - [ ] calibrate.py
        - [ ] change_name.py
        - [ ] chgfilament.py
    - [ ] /KlipperScreen/ks_includes/zh_TW/KlipperScreen2mo  - Check what is different in the Eryone version
    - [ ] /KlipperScreen/screen.py  - Check what is different in the Eryone version
- Eryone /klipper/ --> Check
    - /klipper/klippy/extras/
        - [ ] as5600.py
        - [x] at24c_eeprom.py
        - [x] gcode_shell_command.py
        - [ ] pressure_sensor.py
    - [ ] /klipper/lib/rp2040/
    - [ ] /klipper/lib/rp2040_flash/
    - [ ] /klipper/src/rp2040/rp2040_link,lds.S --> ??? new: rpxxxx.lds.s
    - [ ] /klipper/src/pressure_sensor.c --> deleated on 20250825 (by eryone)
- [ ] Eryone /moonraker/mooonrkaer/components/timelpase.py redirect to /moonrkaer-timelapse/components/timelpase.py --> Why?
- [x] Eryone /moonraker-timelapse/ --> What was changed by eryone?
    - MKS path hardwired & sudo makerspace added
    - timelapse.py: MKS path hardwired 

## Eryone farm3d
- /scripts/install_software.sh
    - [ ] "pip3 install" commands used. Code is from /eryone-scripts-all/install_lib.sh. Not working on Debuan systems. See next install.sh topic.
- install.sh
    - [ ] "pip3 install" command used. \
        Debian/Ubuntu-like system that implements PEP 668. Which marks the system Python as “externally managed,” so "pip3 install" to the system site-packages is blocked to avoid breaking OS packages.
    - [x] --> changed strings in farm3d.service that the replacement works
    - [x] --> Added farm3d.service installation
- [x] update.sh: Executes git fetch. but there is no /.git/config. Calls mq.py --> only works when orioginaly cloned from github.com/eryone/farm3d repo. --> use x400-software-pack/scripts/update.sh instead
- run.sh
    - Calls: ./mq.py
    - Calls: /eryone-scripts-all/monitor.sh which is doing nothing
    - [x] Uses hardcoded paths (/home/mks/") and "~"    --> changed to $HOME
    - [x] Uses "echo makerbase | sudo -S service crowsnest restart"  --> removed "echo makerbase" part
 - mq.py - is the MQTT Handler which takes care of the communication between klipper and farm3d server
    - Loads: ./klipper_config.cfg
 - klipper_config.cfg   --> Loaded in mq.py
 - farm3d.service   --> calls run.sh
 - get-pip.py - Standard python installer for pip   --> Not used

## Research on the following tools, if they should be part of x400-software-pack:
- [ ] SimplyPrint: https://simplyprint.io
- [ ] PrettyGCode: https://github.com/Kragrathea/pgcode


## Hardware modifications
- [x] Second temperature sensor for chamber exhaust fan / chamber heater
- [ ] Poop bin (my be combined with Nozzle Cleaning Station)
- [ ] Nozzle Cleaning Station (left side)
    - [x] Constructed
    - [ ] Adapted to actual printer size
    - [ ] Printed and Tested
- [ ] Printer sealing
- [x] Chamber fan (exhaust) v1: lid which closes and opens --> Integrated in Chamber exhaust system
- [ ] Chamber fan (exhaust) v2: lid which closes and opens (optimized mounting)) --> Integrated in Chamber exhaust system
- [ ] Chamber Filtration System (exhaust fan) : lid, bigger coal filter and HEPA filter, pre filter
    - [x] Constructed
    - [ ] Adapted to actual printer size
    - [ ] Printed and Tested
- [ ] Electronic bay fan filter
    - [x] Constructed
    - [ ] Adapted to actual printer size
    - [ ] Printed and Tested
- [ ] Chamber filtration unit: Coal Filter and HEPA filter (recirculation air)
    - [ ] Constructed
    - [ ] Adapted to actual printer size
    - [ ] Printed and Tested
- [ ] Auxilliary part cooling fan (G-Code M106, M107)
- [ ] Filament storage unit. With feeder and electric dehumidifier
        - Automatic filament loader (Feeder)
        - electric dehumidifier
        - for <amount> spools
- [ ] RBG Status LED for printer status indication (Neopicel pin:PC5)
- [ ] Nozzle camera (for Obico)
    https://www.obico.io/blog/nozzle-camera-stealthburner/
    https://www.bondtech.se/product/stealthburner-camera-kit
- [ ] As soon as I can get my hands on the Bondtech INDX I will upgrade the x400 with it.
    https://www.bondtech.se/indx-by-bondtech/


## Added Features
- Backup script function
    - [x] Backup as zip to local backup folder
    - [ ] Upload zip to SMB
    - [x] Backup to GitHub
    - [ ] GitHub: Initial setup local fodler (/printer_backup/files/) in install_software.sh
        --> git_initiate.sh: Test "Git commands" section. 
- [ ] Temeprature monitoring (what to do when to hot)
- [ ] Endstoop calibration [endstop_phase]
- Update functionality with moonraker. Add in Moonraker.conf [update_manager]:
    - [ ] G-Code Shell Command
    - [ ] Input Shaper

## Added Software
- [ ] Mobileraker - Mobile App support \
        https://github.com/Clon1998/mobileraker
        https://github.com/Clon1998/mobileraker_companion
    - [x] installation
    - [ ] setup
    - [ ] in backup included (backup script & klipper-backup)
- [ ] Obico support for local AI server \
    https://www.obico.io/docs/user-guides/klipper-setup/
    https://www.obico.io/docs/server-guides/
    - [x] installation
    - [ ] setup
    - [ ] in backup included (backup script & klipper-backup)



# How Tos
## Before installing
- Install RaspberryPi (Connect all USB and HDMI cables to the RPI)
- Install 2 additional Thermostate sensors (Second chamber temp sensor, Environment sensor)
- Setup teh RapsberryPi with the RaspberryPi os (Trixy) inclunding X11 Desktop.

#### optional:
- Add RGB light and connect it to NeoPixel port.


## How to Install?
> [!NOTE]
> Read all the documentation: Eryone, Klipper, Mainsail, Moonraker, etc.
> [!CAUTION]
> Be aware that every modification on the devide and software may void the garanty and may damage the devide.


### First boot
1) Start the RPI and printer. \
   The IP-Adress of the printer will be shown in its display.

2) Connect to the printer as <YOUR_USER> via SSH.
    ```bash
    ssh <YOUR_USER>@<PRINTER_IP>
    ```

### Install the software
1) Clone the repo to the local machine
    ```bash
    cd ~/
    git clone https://github.com/rockybeachradio/x400-software-pack.git
    ```

2) Install software part 1
    ```bash
    ~/x400-software-pack/scripts/install.sh
    ```
    If asked:
    - iperf3 launch at start: no


2) Install components via KIAUH
If asked select: 3) Yes, use v6 and remember choice

In KIAUH: \
    1) Install \
        1.1) Klipper \
        1.2) Moonraker \
        1.3) Mainsail \
        1.5) Mainsail-Config \
        1.7) KlipperScreen
            --> X11 (nicht wayland) \
            --> NetworkManager: yes  # After installing, the system is going to reboot.  \
        1.8) Crowsnest \
    4) Advances \
        4.5)Input Shaper Dependencies \
            --> If asked: Install needed software: YES \
    E) Extension \
        E.1) G-Code Shell Command \
        E.3) Mobileraker   (optional) \
        E.4) Klipper-Backup  (optional: Backup on boot, Cron, Backup on file changes) \
        E.6) Obico for Klipper  (optional) \
Use the default settings during installatios \
If asked, install al example files / demo configs.

KIAUH can be launched any time with the command:
    ```bash
    ~/kiauh/kiauh.sh
    ```

4) Klipper Backup (if installed)
Open the ~/KlipperBackup/.env file and add your GitHub credentials.
    ```bash
    cd ~/klipper-backup/
    nano .env
    ```

5) Install software part 2
    ```bash
    ~/x400-software-pack/scripts/install_part2.sh
    ```

6) Reboot the system
    ```bash
    sudo reboot
    ```

### Installing Klipper firmware on the MCUs
1) Katpult: Install/update Katapult on your boards (MCU, toolhead)

2) Klipper Firmware: Install/update Firmware on your boards (MCU, toolehad)
mcu-update_all.sh can be used.

3) Install Linux MCU rpi
mcu-update_all.sh can be used.

3) Reboot
    ```bash
    sudo reboot
    ```

### Settings
1) Settings in Mainsaol
1.1) Camera - already set up
1.2) Display CANCEL_PRINT in Interface Settings - UI-Settings
1.3) Create Macro groups in Interface Settings - Macros
1.3.1) Printing: Load filament; Unload filament; print continue
1.3.2) System: Shutdown


### Useful links
1) Mainsail: http://<PRINTER_IP>:80
2) Moonraker: http://<PRINTER_IP>:7125

### Check setup 
1) Check all settings and printerbehaviour as descirped in Klipper, Mainsail, Moonraer documentation to avoid issues and damages.


## How to update x400-software-pack
```bash
~/x400-software-pack/scripts/update.sh
```

## How to flash the MCUs
```bash
~/x400-software-pack/scripts/mcu-update_all.sh
```

## How to reset x400-software-pack
x400-software-pack can be reinstalled.
```bash
~/x400-software-pack/scripts/install.sh
~/x400-software-pack/scripts/install_part2.sh
```

## How deleat local x400-software-pack repo copy
As it is a copy of a repo, just delet the local reopo folder.
```bash
rm -r ~/x400-software-pack"
```
Note: This will not uninstall software nor deleat any (config) files, folders, etc. which were created during installation.
This need to be done manually.



# Useful stuff for terminal (german keyboard layout)
```bash
~   alt + n
[   alt + 5
]   alt + 6
|   alt + 7
{   alt + 8
}   alt + 9
/   shift + 7
\   alt + shift + 7

close programs    ctrl + c
```


# Sources
#### Eryone Thinker x400 printer:
- https://eryone.com/
- https://eryone3d.com/products/thinker-x400/
- https://eryonewiki.com/
- https://www.facebook.com/groups/eryoneofficial/
- https://www.facebook.com/groups/thinkerx400/

#### Eryone Repositories:
- GitHub: https://github.com/Eryone/
- GitHub: https://github.com/Eryoneoffical/
- Gitee: https://gitee.com/everyone3d/
- GitCode: https://gitcode.com/xpp012/KlipperScreen/

#### Makerbase MKS:
- https://makerbase.com.cn/en/
- https://github.com/makerbase-mks/

#### Armbian for MKS boards (The Linux which is used):
- GitHub: https://github.com/redrathnure/armbian-mkspi

#### Informations:
- Eryone toolhead board: https://gitcode.com/xpp012/KlipperScreen/tree/master/docs
- Eryone pressure sensor:
    - code: https://gitee.com/everyone3d/stm32_pressure_sensor
    - binary: https://gitcode.com/xpp012/KlipperScreen/tree/master/docs/X400_firmware
- Eryone x400 3d printed Parts: https://github.com/Eryoneoffical/X400_printed_parts_cad_files
- Eryone farm3d:
    - https://github.com/Eryone/farm3d
    - https://gitcode.com/xpp012/KlipperScreen/tree/master/farm3d

All rellevant Eryone documents, files are part are collected from all soruces and part of this Repository.

## Repo checked for changes/updates:
https://gitcode.com/xpp012/KlipperScreen/ - last check 20251017 (a615b786)