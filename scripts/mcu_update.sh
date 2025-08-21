#!/usr/bin/env bash

################################################################################################
# File: mcu_update.sh
# Author: Andreas
# Date: 20250813
# Purpose: Create the image and flash the MCU based on a given configuraion file.
#
# How to create the CONFIG_File:
#   Run "make menuconfig and make the changes you want. Example for smt32:
#   $ cd /Klipper/
#   $ make menuconfig KCONFIG_CONFIG=stm32f407_firmware.config
#   This saves the configuration in the stm32f407_firmware.config file
#   
#   When executing "$ make menuconfig" the configuration is stored in the ".config" file.
#   Rename the file for later use.
#
# The localhost IP 127.0.0.1 needs to be added as trusted device to the moonraker.conf to make the $ curl bash command work.
#
# How to call the script:
#   ./mcu_update.sh -c [CONFIG_FILE] -d [FLASH_DEVICE] -u [UUID]
#   eg: ./mcu_update.sh -c stm32_flash.config -d ttyN0 -u 29u4962368
#
################################################################################################


################################################################################################
# Error handling
set -euo pipefail                                   # Definiert Abbruchkriterien für Skript:
                                                    # set -e - Wenn ein Befehl fehlschlägt.
                                                    # set -u - Wenn eine nicht gesetzte Variable verwendet wird.
                                                    # set -o pipefail - Bei Befehlen mit Pipe (|) wir der erste Fehler im Pipeline-Verlauf erkannt.
error_exit() { echo "! ERROR: $1" >&2; exit 1; }    # Funktion error_exit: Shows an error message and EXIT the script. error_exit is called whenever an error in the script occures


################################################################################################
# Script exit routines
#restart_klipper() { sudo systemctl start "$SERVICE" || echo "! WARNING: Failed to start $SERVICE"; }                                # Funktion restart_klipper - When called: Starts the Klipper Sevice.
restart_klipper() { curl -X POST "http://localhost:7125/api/klipper/start" || echo "! WARNING: Failed to start $SERVICE"; }          # Funktion restart_klipper - When called: Starts the Klipper Sevice.
trap restart_klipper EXIT                                                                                                            # TRAP takes care that whenever the Script is EXITed, the function restart_klipper is executed. Also when exiting due to an error.


################################################################################################
# Varibale declaration
SERVICE="klipper.service"                       # Name of the Service which will be stopped / started
klipper_folder="$HOME""/klipper"
BIN_FILE="$klipper_folder""/out/klipper.bin"      # Where make command stores the bin file.

linux_mcu_firmware_kconfig_file="$klipper_folder"".config"

board_mcu_firmware_kconfig_file="$klipper_folder"".config"
board_mcu_flash_devide_port="2e8a:0003"                  # copy from ???
board_mcu_uuid="2332322322312"                           # copy from /printer_data/config/uuid.cfg

toolhead_mcu_firmware_kconfig_file="$klipper_folder"".config"
toolhead_mcu_uuid="98629928762"                           # copy from /printer_data/config/uuid.cfg


################################################################################################
# Get ARGUMENTS form shell call
while getopts "x:h" opt; do
  case $opt in
    x) which_mcu="$OPTARG" ;;         # -x which MCU to update
    h)                                # -h help

      echo "Only for internal use"
      echo "flashe_device is needed for USB flash mode only"
      echo "-x which MCU to update"
      exit 0       # Exit the Script, when -h was called
      ;;
    \?)
      echo "! Unknown option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "! Option -$OPTARG requires an argument." >&2

      exit 1
      ;;
  esac
done


################################################################################################
# Check if required options are provided
if [[ -z "$which_mcu" ]]; then
  echo "! Missing required arguments -x which MCU to update."
  exit 1
fi

echo "Starting the update routine ... "


################################################################################################
# Update routines
################################################################################################
echo "Stopping $SERVICE ..."                                                                                
 #sudo systemctl stop "$SERVICE" || error_exit "! Failed to stop $SERVICE."
curl -X POST "http://localhost:7125/api/klipper/stop" || error_exit "! Failed to stop $SERVICE."

echo "Checking parameter handed over ..."     
[[ -f "$CONFIG_FILE" ]] || error_exit "! Config file not found: $CONFIG_FILE"                      # Check if the config_file exists and if it is a normal file. If so: True
                                                                                                   # The bash file test operator -F
[[ -n "$FLASH_DEVICE" ]] || error_exit "! No FLASH_DEVICE provided"                                # Check if a flash_devide is provided. If so: Tue.
                                                                                                   # The bash string test operator -n is used.
                                                                                                   # [] is a test command. [[ ]] is a extended test command.
                                                                                                   # || is like "else"
[[ -n "$UUID" ]] || error_exit "! No UUID provided"                                                # Check if a UUID is provided. If so: Tue.

echo "Going to klipper folder ..."
cd $HOME/klipper/  || error_exit "! Klipper folder not found." 

echo "Cleaning build ..."
make clean KCONFIG_CONFIG="$CONFIG_FILE" || error_exit "! Failed to clean old build."              # Deleates artefacts from previous builds
make clean                                                                                         # deleats all artefacts

echo "Updating configuration (olddefconfig) ..."
make olddefconfig KCONFIG_CONFIG="$CONFIG_FILE" || error_exit "! Failed to update config."         # Updates the build configurations based on the config file.


################################################################
# Board MCU via USB

if which_mcu = "board_mcu"; then
    echo "Start Katapult bootloader on controller ..."
    $HOME/klippy-env/bin/python $HOME/katapult/scripts/flashtool.py -i can0 -u "$board_mcu_uuid" -r  || error_exit "! Starting bootloader failed."  

    echo "Build firmware & flashing to controller ..."
    make j"$(nproc)" flash FLASH_DEVICE="$board_mcu_flash_devide_port" KCONFIG_CONFIG="$board_mcu_firmware_kconfig_file" || error_exit "! Building fimrware or flashing failed.."

  ## Skipr MCU
  #echo "Build firmware and flashing to controller ..."
  #make  -j"$(nproc)" flash FLASH_DEVICE="$UUID" KCONFIG_CONFIG="$CONFIG_FILE" || error_exit "! Build or flash failed." 
fi


################################################################
# Toolhead board via CAN

if MODE = "toolhead_mcu"; then
  echo "Building firmware ..."
  make  -j"$(nproc)" KCONFIG_CONFIG="$toolhead_mcu_firmware_kconfig_file" || error_exit "! Building firmware failed."

  #echo "Rename firmware.bin file ..."
  #mv out/firmware.bin out/eecan_firmware.bin || error_exit "! Rename firmware file failed."

  echo "Start Katapult bootloader on controller & Flashing to controller ..."
  $HOME/klippy-env/bin/python3 $HOME/katapult/scripts/flash_can.py -i can0 -u "$toolhead_mcu_uuid" -f "$BIN_FILE" -u "$toolhead_mcu_uuid" || error_exit "! Starting Katapult bootloader or flashing failed."
fi


################################################################
# Linux MCU
if MODE = "linux_mcu"; then
  echo "Stopping linux_mcu ..:"
  sudo systemctl stop linux_mcu || error_exit "! Stopping failed."

  echo "C0py klipper-mcu.service ..."
  sudo cp ./scripts/klipper-mcu.service /etc/systemd/system/ || error_exit "! Copying failed."

  echo "Enable klipper-mcu service ..."
  sudo systemctl enable klipper-mcu.service || error_exit "! Enabling failed."

  echo "Grant user acces to tty"
  sudo usermod -a -G tty $USER || error_exit "! Granting access failed."

  echo "Building firmware ..."
  make  -j"$(nproc)" KCONFIG_CONFIG="$linux_mcu_firmware_kconfig_file" || error_exit "! Building firmware failed."

  echo "Starting klipper_mcu and klipper..."
  sudo systemctl start klipper-mcu klipper || error_exit "! Starting failed."

  echo "Please reboot the system"
fi

################################################################
# DFU Skipr MCU without bootloader
if MODE = "dfu"; then
  echo "Building firmware ..."
  make  -j"$(nproc)" KCONFIG_CONFIG="$CONFIG_FILE" || error_exit "! Building firmware failed."

  echo "Activate DFU mode ..."
  # activate dfu mode via BOOT & RESET buttonr

  echo "Flashing to controller ..."
  $ dfu-util -R -a 0 -s "$UUID" -D "$BIN_FILE"
  #$ dfu-util -R -a 0 -s 0x08000000:mass-erase:force -D $HOME/klipper/out/klipper.bin

  echo "Reset Controller ..."
  # Reset controller via RESET button
fi

################################################################################################
# Done
################################################################################################
echo "Done :-)"

# When exiting the Script, TRAP is trickered. Which starts the Klipper Service. Soee above. SO no extra Klipper Start is needed.
