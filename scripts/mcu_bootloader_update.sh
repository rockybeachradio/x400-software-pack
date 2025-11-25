#!/usr/bin/env bash

################################################################################################
# File: mcu_bootlaoder_update.sh
# Author: Andreas
# Date: 20251125
# Purpose: Create the bootlaoder image (katapult) and flash the controller based on a given configuraion file.
#
# How to create the CONFIG_File:
#   Run "make menuconfig and make the changes you want. Example for smt32:
#   $ cd /katapult/
#   $ make menuconfig KCONFIG_CONFIG=stm32f407_katapult_bootloader.config
#   This saves the configuration in the stm32f407_katapult_bootloader.config file
#   
#   When executing "$ make menuconfig" the configuration is stored in the ".config" file.
#   Rename the file for later use.
#
# The localhost IP 127.0.0.1 needs to be added as trusted device to the moonraker.conf to make the $ curl bash command work.
################################################################################################
echo "ℹ️  This is $(basename "$0")"
echo " "

################################################################################################
# Error handling
################################################################################################
set -euo pipefail                                   # Definiert Abbruchkriterien für Skript:
                                                    # set -e - Wenn ein Befehl fehlschlägt.
                                                    # set -u - Wenn eine nicht gesetzte Variable verwendet wird.
                                                    # set -o pipefail - Bei Befehlen mit Pipe (|) wir der erste Fehler im Pipeline-Verlauf erkannt.
error_exit() { echo "! ERROR: $1" >&2; exit 1; }    # Funktion error_exit: Shows an error message and EXIT the script. error_exit is called whenever an error in the script occures


################################################################################################
# Script exit routines
################################################################################################
trap restart_klipper EXIT            # TRAP takes care that whenever the Script is EXITed, the function restart_klipper is executed. Also when exiting due to an error.


################################################################################################
# Varibale declaration
################################################################################################
SERVICE="klipper.service"                       # Name of the Service which will be stopped / started
bootloader_folder="$HOME""/katapult"
bootloader_bin_file="$bootloader_folder""/out/katapult.bin"  # Where make command stores the bin file.


################################################################################################
# Get ARGUMENTS form shell call
################################################################################################
while getopts "m:c:d:u:h" opt; do
  case $opt in
    m) MODE="$OPTARG" ;;            # -m mode
    c) CONFIG_FILE="$OPTARG" ;;     # -c config_file
    d) FLASH_DEVICE="$OPTARG" ;;    # -d flash_device (optional)
    h)                              # -h help
      echo "Usage: $0  -c <config_file>  -c <config_file>  -u <uuid> [-d <flash_device>]"
      echo "flashe_device is needed for USB flash mode only"
      echo "  -m   Modes: skipr_mcu, eryone_toolhead_1"
      echo "  -c   Path and filename of the make config file. Created via make menuconfig (eg. ~/printer_data/mcu-firmware-configurations/stm32407_firmware.config)"
      echo "  -d   Flash device (idVendor:idProduct = 2e8a:0003) can be found with: $ sudo mesg -Hw"
      echo " "
      echo "Examples:"
      echo "./mcu_update.sh -m usb -c ~/x400-software-pack/mcu-bootloader-configurations/stm32f407_katapult_bootloader.config"
      echo "./mcu_update.sh -m can -c ~/x400-software-pack/mcu-bootloader-configurationsrp2040_katapult_Bootloader_usb.config -d 2e8a:0003"
      exit 0       # Exit the Script, when -h was called
      ;;
    \?)
      echo "❌  Unknown option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "❌  Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done


################################################################################################
# Parameter check - complete?
################################################################################################
echo "ℹ️  Checking if all required options are provided"
if [[ -z "$MODE" ]]; then
  echo "❌  Missing required arguments -m MODE."
  exit 1
else
  echo "mode: $MODE"
fi

if [[ "$MODE" = "skipr_mcu" ]]; then
  if [[ -z "$CONFIG_FILE"]]; then
    echo "❌  Missing required arguments."
    exit 1
  else
    echo "ℹ️  Provided parameter:"
    echo "CONFIG_FILE: $CONFIG_FILE"
  fi
elif [[ "$MODE" = "eryone_toolhead_1" ]]; then
  if [[ -z "$CONFIG_FILE" || -z "$FLASH_DEVICE" ]]; then
    echo "❌  Missing required arguments."
    exit 1
  else
    echo "ℹ️  Provided parameters:"
    echo "CONFIG_FILE: $CONFIG_FILE"
    echo "FLASH_DEVICE: $FLASH_DEVICE"
  fi
else
  echo "❌  No correct mode handed over."
  exit 1
fi

echo "ℹ️  Starting the update routine ... "


################################################################################################
# Functions
################################################################################################
start_klipper() {
  echo "ℹ️  Starting $SERVICE ..."
  sudo systemctl start "$SERVICE" || echo "❌  Failed to start $SERVICE."
} 

stop_klipper() {
  echo "ℹ️  Stopping $SERVICE ..."
  sudo systemctl stop "$SERVICE" || error_exit "❌  Failed to stop $SERVICE."
} 

restart_klipper() {
  echo "Execution script exit routine: restart_klipper"
  echo "ℹ️  Restart $SERVICE ..."
  sudo systemctl restart "$SERVICE" || echo "❌  Failed to restart $SERVICE."
  # Funktion restart_klipper - When called: Starts the Klipper Sevice.
  #curl -X POST "http://localhost:7125/api/klipper/start" || echo "❌  WARNING: Failed to start $SERVICE";
} 



################################################################################################
# Prepare Updates
################################################################################################
#####################
echo "ℹ️  Checking files and devices, based on parameters handed over ..."     
[[ -f "$CONFIG_FILE" ]] || error_exit "❌  Config file not found: $CONFIG_FILE"                    # Check if the config_file exists and if it is a normal file. If so: True
                                                                                                   # The bash file test operator -F

if [[ MODE = "eryone_toolhead_1"]]; then
  [[ -n "$FLASH_DEVICE" ]] || error_exit "❌  No FLASH_DEVICE provided"                              # Check if a flash_devide is provided. If so: Tue.
                                                                                                   # The bash string test operator -n is used.
                                                                                                   # [] is a test command. [[ ]] is a extended test command.
                                                                                                   # || is like "else"
fi

#####################
echo "ℹ️  Going to bootloader folder ..."
cd $bootloader_folder  || error_exit "❌  Klipper folder not found." 

#####################
echo "ℹ️  Clean up old builds ..."
make clean KCONFIG_CONFIG="$CONFIG_FILE" || error_exit "❌  Failed to clean old build by $CONFIG_FILE."   # Deleates artefacts from previous builds
make clean || error_exit "❌  make clean failed"                                                          # deleats all artefacts

echo "ℹ️  Updating configuration (olddefconfig) ..."
make olddefconfig KCONFIG_CONFIG="$CONFIG_FILE" || error_exit "❌  Failed to update config."         # Updates the build configurations based on the config file.



################################################################################################
# Bootloader of controller on SKIPR board via USB
################################################################################################
if [[ "$MODE" = "skipr_mcu" ]]; then
  ################################################################
  # Compile bootloader
    echo "ℹ️  Building the bootloader..."
    cd "$bootloader_folder"   || error_exit "❌  booloader folder not found." 
    make clean || error_exit "❌  Failed: make clean"
    make -j"$(nproc)" KCONFIG_CONFIG="$CONFIG_FILE" || error_exit "❌  Failed: Building bootloader"

  ################################################################
  echo "Stopping Klipper.service"
  stop_klipper
  sleep 1

  ################################################################
  # Set controller into DFU mode
  echo "ℹ️  Set the Controller into DFU mode:"
  echo " Press and hold the boot 0 button (upper button)"
  echo " Press reset button (lower button)"
  echo " Release boot 0 button"
  echo " "
  echo "How to check if controller is in DFU Mode?"
  echo "Open asecond terminal window and run $ sudo dmesg -HW"
  echo "Set the controller into DFU mode as described above."
  echo "After setting the controlle into DFU mode something like -Product: STM32 BOOTLOADER- should appear"
  echo "Here the idCendor and idProduct is shown"
  echo "To close dmesg press Ctrl + C"
  echo " "

  ################################################################
  # flash bootloader
  read -p "❓ Is Controller in DFU mode & Are you ready to start the falshing process? [Y/n]: " answer
  answer=${answer:-Y}     # If emtpy it is default "N"
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "The flashing process takes a while. No progress may be shown for a long time."
    sudo dfu-util -R -a 0 -s 0x08000000:mass-erase:force -D $bootloader_bin_file || error_exit "❌  Failed: Flashing"
    echo " "
  else
      echo "Script will exit. Restart the script and try again."
      echo " "
      exit 0
  fi

  ################################################################
  echo "After pfalshing was successfull, press the reset button of the controller"
  echo " "
fi



################################################################################################
# Bootloader of controller on eryone_toolhead_1 via USB
################################################################################################
if [[ "$MODE" = "eryone_toolhead_1" ]]; then
  ################################################################
  # Compile bootloader
  echo "ℹ️  Building the bootloader..."
  cd "$bootloader_folder"   || error_exit "❌  booloader folder not found." 
  make clean || error_exit "❌  Failed: make clean"
  make -j"$(nproc)" KCONFIG_CONFIG="$CONFIG_FILE" || error_exit "❌  Failed: Building bootloader"
  echo " " 

  ################################################################
  echo "Stopping Klipper.service"
  stop_klipper
  sleep 1

  ################################################################
  # Prepare toolhead board for flashing
  echo "Disconnect Can-Bus cable while the pritner is turned off and disconnected from power."
  echo "Connect USB-Cable to the SoC board (SKIPR-board / RaspberryPi)"
  echo "To start the RP2040 in Flash mode press and hold the BOOT button of the toolhead-board (next to the USB-C port)"
  echo "Connect the USB cable to the Toolhead Board."
  echo "Release the BOOT button"
  echo "RP2040 will connect as a USB drive: RPI-RP2"
  echo " "
  echo "To check if the RP2040 is connected as RPI-RP2:"
  echo "Open asecond terminal window and run $ sudo dmesg -HW"
  echo "Something like -Product: RP2 Boot- shall appear"
  echo "To close dmesg press Ctrl + C"
  echo " "

  ################################################################
  # flash bootloader
  read -p "❓ Is toolhead board ready & Are you ready to start the falshing process? [Y/n]: " answer
  answer=${answer:-Y}     # If emtpy it is default "N"
  if [[ "$answer" =~ ^[Yy]$ ]]; then
      make flash FLASH_DEVICE=$FLASH_DEVICE
      echo " "
  else
      echo "Script will exit. Restart the script and try again."
      echo " "
      exit 0
  fi

  ################################################################
  echo "After flashing was successfull: "
  echo "Turn off the printer and disconnect it from the power."
  echo "Unplug the USB cable"
  echo "Plug in the CAN Bus cable"
  echo "Start the printer"
  echo " "
fi



################################################################################################
# Klipper Service restart
################################################################################################
# When exiting the Script, TRAP is trickered. Which starts the Klipper Service. See above. So no extra Klipper Start is needed.

################################################################################################
# Done
################################################################################################
echo "✅  Done :-)"
exit 0