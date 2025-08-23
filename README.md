Welcome, to my software pack for the Eryone Thinker x400

# Information about this project
This is an alternative Firmware for the Eryone Thinker x400. \
    https://github.com/rockybeachradio/x400-software-pack \
From me for me. But feel free to use it as well :-) \
 \
It is based on the original firmware from Eryone. \
 \
I started to dig into the firmawre and how Eryone seted up the printer software. \
During that process i started to scrut the configs to they make more sence for me. \
During that process I found some tings I did not like and oters I whish tehy were included. \
So I made the changes. And here is what I came up with. \
 \
Feel free to give me feedback and contribute ideas or code. \

> [!IMPORTANT]
> My printer will arrive end August 2025. So I was not able to test anything



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
- Eryone Ttolhead board: https://gitcode.com/xpp012/KlipperScreen/tree/master/docs
- Eryone pressure sensor:
    - code: https://gitee.com/everyone3d/stm32_pressure_sensor
    - binary: https://gitcode.com/xpp012/KlipperScreen/tree/master/docs/X400_firmware
- Eryone x400 3d printed Parts: https://github.com/Eryoneoffical/X400_printed_parts_cad_files
- Eryone farm3d:
    - https://gitcode.com/xpp012/KlipperScreen/tree/master/farm3d
    - https://github.com/Eryone/farm3d

All rellevant Eryone documents, files are part are collected from all soruces and part of this Repository.


#### Repo check for updates:
https://gitcode.com/xpp012/KlipperScreen/ - last ceck 20250821




# Development log:
#### To check why eryone has spezial versions and not using the original ones. (commands found in relink_conf.sh)
- [ ] cp /home/mks/KlipperScreen/moonraker/moonraker/components/machine.py /home/mks/moonraker/moonraker/components/       - Check what is different in the Eryone version
- [ ] cp /home/mks/KlipperScreen/config/timelapse.cfg  /home/mks/moonraker-timelapse/klipper_macro/                        - Check what is different in the Eryone version
~~- [ ] cp  /home/mks/KlipperScreen/klipper/ /home/mks/  -rf~~
- [ ] How is KlipperScreen calling eryone scripts? Where are the scripts used?
    - ln -s /home/mks/KlipperScreen/all /home/mks/mainsail/all


#### To check why these files are there in addition to original repo.
- [ ] Where are all the scripts in /eryone-scrits (all) used?
- [ ] Check Eryone /KlipperScreen
    - [ ] /KlipperScreen/Panels/ - Check what is different in the Eryone version
        - [ ] calibrate.py
        - [ ] change_name.py
        - [ ] chgfilament.py
    - [ ] /KlipperScreen/ks_includes/zh_TW/KlipperScreen2mo  - Check what is different in the Eryone version
    - [ ] /KlipperScreen/screen.py  - Check what is different in the Eryone version
- [ ] Check Eryone /klipper
    - /klipper/klippy/extras/
        - [ ] as5600.py
        - [ ] at24c_eeprom.py
        - [ ] gcode_shell_command.py
        - [ ] pressure_sensor.py
    - [ ] /klipper/lib/rp2040/
    - [ ] /klipper/lib/rp2040_flash/
    - [ ] /klipper/src/rp2040/rp2040_link,lds.S --> ??? new: rpxxxx.lds.s
    - [ ] klipper/src/pressure_sensor.c
- [ ] Check Eryone /moonraker/mooonrkaer/components/timelpase.py redirect to /moonrkaer-timelapse/components/timelpase.py
- [x] Check Eryone /moonraker-timelapse
    - MKS path hardwired & sudo makerspace added
    - timelapse.py: MKS path hardwired 

#### farm3d things
- Eryone farm3d
    - scripts/install_software.sh
        - [ ] Uses "pip3 install" commands. Code from eryone-scripts-all/install_lib.sh
    - eryone-farm3d/install.sh
        - [ ] uses pip3 install \
            Debian/Ubuntu-like system that implements PEP 668.  \
            It marks the system Python as “externally managed,” so "pip3 install" to the system site-packages is blocked to avoid breaking OS packages. \
        - [x] changes strings in farm3d.service which are not there --> fixed it in farm3d.service
    - run.sh
        - [ ] Uses /eryone-scripts-all/monitor.sh which is doing nothing
        - [ ] Uses fixed pathes "/home/mks/"  --> Extend install.sh to change it like in farm3d.service file
        - [ ] Uses: "echo makerbase | sudo -S service crowsnest restart"  --> the makerbase password fix coded does not make sens.
        - Calls mq.py
    - [ ] update.sh - executes git fetch. but there is no /.git/. Calls mq.py
    - [ ] mq.py - what is it doing?
    - [ ] klipper_config.cfg - not used. Why?
    - [ ] get-pip.py - not used. Why?

#### known bugs
- [ ] /scripts/install_software.sh
    - see farm3d
- [ ] /scripts/copy_configs.sh
    - [ ] "KlipperBackup env.conf" not existing in /configurations/
    - [ ] "can0.conf" file not existing in /configurations/
    - [x] KlipperScreen panels copy not working



# Changelog
### Hardware mods
~~- [ ] Hardware connections used as intended by Makerspace MKS Skipr.~~
~~- [ ] DIAGS aktivated~~
- [ ] Poop bin
- [ ] Nozzle wiper
- [ ] Printer sealing
- [ ] Chamber (exhaust) fan: add bigger coal filter and HEPA filter
- [ ] Chamber (exhaust) fan: lid which closes and opens
- [ ] Chamber filtration unit: Coal Filter and HEPA filter (recirculation air)
- [ ] Filament storage and feed unit with electric dehumidifier
- [ ] RBG Status LED (Neopicel pin:PC5)
- [ ] As soon as I can get my hands on the Bondtech INDX I will update the x400 with it.

#### Changes compared to the original:
- [x] Newest software is used: Linux, Klipper, Moonraker, Mainsail, KlipperScreen, etc.
- [x] KlipperScreen is not used as "Eryone Update path".
- [x] Config Files structured & cleaned - Phase 1
- [x] Config Files are cleaned up - Phase 2
- [x] Using GitHub releas function to check for updates.
- [x] cfg files are in the right default locations
- [x] Added WebCam settings in moonraker.conf
- [x] Chamber heater programmed
- [x] Chamber heater PID calibration extended and activated
- [x] [gcode_macro PRINT_START]  SET_FAN_SPEED FAN=filter_fan SPEED=0.9  --> commented out
- [x] [tmc2209 stepper_z] diag_pin: PB15 --> commented out. No XDIAG jumper is set. Was declared twiche: PB15 is used by filament tangle sensor
- [x] [tmc2209 stepper_z] river_SGTHRS: 180 --> commented out. No sensorless homing is used in x400.

#### Changes in the macros:
- [x] [gcode_macro CANCEL_PRINT] TURN_OFF_HEATERS
- [x] [gcode_macro CANCEL_PRINT] _CLIENT_RETRACT LENGTH={retract} 
- [x] [gcode_macro CANCEL_PRINT] _TOOLHEAD_PARK_PAUSE_CANCEL 
- [x] [gcode_macro PAUSE] PAUSE_BASE instead of BASE_PAUSE renamed
- [x] Max 150°C on nozzle while probing
- [x] [gcode_macro PAUSE] - using the mainsail-crew version, instead of the eryone version
- [x] [gcode_macro RESUME] - using the mainsail-crew version, instead of the eryone version

#### Added Features
- [x] x400-software-pack installer
- [x] MCU Update function
- [x] Backup function: local backup folder
- [ ] Backup function: GitHub
- [x] x11cnv service
- [x] Host, SKIPR-MCU toolhead-board-MCU processor temepratures are shown in mainsail
- [ ] Temeprature monitoring (what to do when to hot)
- [x] MCU UUID update
~~- [ ] Nozzle wiping~~
- [ ] dynamic electronic bay fan control based on temperature
- [ ] Endstoop calibration [endstop_phase]
- [x] protection that chamber hfan is not extracting heat while chamber heater is heating the chamber up.
- [x] chamber fan only runs when temperature is above set chamber temperature.
- [x] chamber fan protects chamber from overheating
- [ ] Update functionaloy in Moonraker.conf [update_manager] add update for:
    - [ ] Klipper
    - [ ]Moonraker
    - [ ] KIAUH
    - [ ] G-Code Shell Command
    - [ ]Input Shaper
    - [ ]Obico for Klipper
    - [ ]Katapult
    - [ ] Mobileraker

#### Added Software
- [ ] sonar - Keep alife daemon \
        https://github.com/mainsail-crew/sonar
- [ ] Mobileraker - Mobile App support \
        https://github.com/Clon1998/mobileraker
- [ ] Obico support for local AI server \
        https://www.obico.io/docs/user-guides/klipper-setup/
- [x] KlipperBackup
    - Backup on Boot
    - Backup on file changes

#### What is kept:
- [x] farm3d by Eryone
- [x] Scripts by Eryone (for backward compatibility. in case famr3d needs them)
- [ ] KlipperScreen panels by Eryone preserved


# Before installing
#### Reconnect the following things on the Skipr Board
~~- driver: from E0 slot to Z4 slot~~
~~- Z4 stopper motor from E0 to Z4~~
~~- change Y- to ??? EXP1/2 ???~~
~~- change Z- to ??? EXP1/2???~~

#### optional:
~~- SET all DIAG pins~~
- Use a EMMC (remove SD-Card)
- Add RGB light and connect it to NeoPixel port.

# How Tos
## How to Install?
> [!NOTE]
> Read all the documentation for Klipper, Mainsail, Moonraker, XOur printer etc.
> [!CAUTION]
> Be aware that every modification on the devide and software may void the garanty and may damage your devide.

### Preparing the first boot
1) "Install" Armbian Linux for Skipr \
    https://github.com/redrathnure/armbian-mkspi/releases \
    Copy it via Etcher or RPi-Imager to a SD-Card or EMMC card.

2) Prepare Armbian for the first start  \
    On the BOOT partition you will find the "Armbian_first_run.txt.template" \
    Remove the template from the filename. \
    Open the file and change the settings: \
    - WiFi Settings
    - Language code: en
    - DHCP

3) Insert the SD-Card / EMMC into the Skipr voard and fire the printer up.

4) Connect to the printer via SSH.


### Preparing the System
1) Check if sudo is installed an your user is part of the sudo usergroup \
If not:
    ```bash
    su -
    apt-get install sudo
    /sbin/adduser <YOURUSER> sudo
    exit
    ```

2) Check if git is installed. If not install it \
    ```bash
    sudo apt install git
    ```

3) Update the Linux system
    ```bash
    sudo apt update
    sudo apt upgrade
    ```

### Install the software
1) Install KIAUH
    ```bash
    cd ~/
    git clone https://github.com/dw-0/kiauh.git
    ```

2) Install software using KIAUH
    ```bash
    cd ~/kiauh
    ./kiauh.sh
    ```

What to install: \
    - 1) Install
        - Klipper
        - Moonraker
        - Mainsail
        - Msinsail-config
        - KlipperScreen
        - Crowsnest
    - 4) Advances
        - Input Shaper Dependencies
    - E) Extension
        - G-Code Shell Command
        - Mobileraker
        - Klipper-Backup (optional: Backup on boot, Cron, Backup on file changes)
        - Obico for Klipper


3) Install and update x400-software-pack includingneeded software
    ```bash
    cd ~/x400-software-pack/scripts
    ./install.sh
    ```

    What the installer does:
    - sudo check
    - git check

    - Linux update
    - Armbian-config installation
    - fix DFU
    - fix for Python 3

    - Katapult
    - KAMP
    - moonraker-timelapse
    - sonar
    - x11vnc
    - farm3d prerequisits
    - install needed tools for backup script

    - Clean up

    - copy configurations
    - install famr3d

    - MCU Update \
    On the first run, do not use the integrated "Update MCU firmware" function. Select NO when asked. \
    MCUs need to be prepared befor MCU Update.


4) Make settings in linux \
    eg with
    ```bash
    cd ~/
    sudo armbian-config
    ```

5) Install/update Katapult on your boards (MCU, toolhead)

6) Install/update Firmware on your boards (MCU, toolehad)


### Needs to be dine maunal (for now)
1) Klipper Backup
Open the ~/KlipperBackup/.env file and copy in the backupPaths declaration from from ~/x400-software-pack/config/KlipperBackup env.cfg.


### Check setup 
1) Check all settings and printerbehaviour as descirped in Klipper, Mainsail, Moonraer documentation to avoid issues and damages.

### Settings in Mainsail
1) Add Camera


## How to get new verison of x400-software-pack
To check fopr updates, use git commands or the following script
```bash
cd ~/x400-software-pack
./update.sh
```

## How to install flash MCUs
```bash
cd ~/x400-software-pack/script/
./mcu-update.sh
```