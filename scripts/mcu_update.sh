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
################################################################################################
echo "ℹ️  This is $(basename "$0")"


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
klipper_folder="$HOME""/klipper"
BIN_FILE="$klipper_folder/out/klipper.bin"    # Where make command stores the bin file.

# is_katapult_bootloader()
  CAN_IF="${CAN_IF:-can0}"
  PY_BIN="${PY_BIN:-$HOME/klippy-env/bin/python}"
  KATAPULT_FLASHTOOL="${KATAPULT_FLASHTOOL:-$HOME/katapult/scripts/flashtool.py}"
  KATAPULT_FLASH_CAN="${KATAPULT_FLASH_CAN:-$HOME/katapult/scripts/flash_can.py}"


################################################################################################
# Get ARGUMENTS form shell call
################################################################################################
while getopts "m:c:d:u:h" opt; do
  case $opt in
    m) MODE="$OPTARG" ;;            # -m mode
    c) CONFIG_FILE="$OPTARG" ;;     # -c config_file
    u) UUID="$OPTARG";;             # -u uuid
    d) FLASH_DEVICE="$OPTARG" ;;    # -d flash_device (optional)
    h)                              # -h help
      echo "Usage: $0  -c <config_file>  -c <config_file>  -u <uuid> [-d <flash_device>]"
      echo "flashe_device is needed for USB flash mode only"
      echo "  -m   Modes: usb, can, linux, dfu (not supported yet)"
      echo "  -c   Path and filename of the make config file. Created via make menuconfig (eg. ~/printer_data/make_config_files/stm32407_firmware.config)"
      echo "  -u   UUID of the MCU (eg: 29u4962368)"
      echo "  -d   Flash device (e.g. ttyACM0, 2e8a:0003)"
      echo " "
      echo "Examples:"
      echo "./mcu_update.sh -m usb -c ~/x400-software-pack/mcu-firmware-configurations/stm32f407_klipper_firmware.config -u e718d4677a2f -d /dev/ttyN0"
      echo "./mcu_update.sh -m can -c ~/x400-software-pack/mcu-firmware-configurations/rp2040_klipper_firmware.config -u 972e3df7498c"
      echo "./mcu_update.sh -m linux -c ~/x400-software-pack/mcu-firmware-configurations/linux_mcu_klipper_firmware.config"
      echo "./mcu_update.sh -m dfu -c configuration_file.config - d 0x0800000"
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

if [[ "$MODE" = "usb" ]]; then
  if [[ -z "$CONFIG_FILE" || -z "$FLASH_DEVICE" || -z "$UUID" ]]; then
    echo "❌  Missing required arguments."
    exit 1
  else
    echo "ℹ️  Provided parameter:"
    echo "CONFIG_FILE: $CONFIG_FILE"
    echo "FLASH_DEVICE: $FLASH_DEVICE"
    echo "UUID: $UUID"
  fi
elif [[ "$MODE" = "can" ]]; then
  if [[ -z "$CONFIG_FILE" || -z "$UUID" ]]; then
    echo "❌  Missing required arguments."
    exit 1
  else
    echo "ℹ️  Provided parameter:"
    echo "CONFIG_FILE: $CONFIG_FILE"
    echo "UUID: $UUID"
  fi
elif [[ "$MODE" = "linux" ]]; then
  if [[ -z "$CONFIG_FILE" ]]; then
    echo "❌  Missing required arguments."
    exit 1
  esle
    echo "ℹ️  Provided parameter:"
    echo "CONFIG_FILE: $CONFIG_FILE"
  fi
elif [[ "$MODE" = "dfu" ]]; then
  echo "❌  DFU flash mode isnot supported yet"
  exit 1
  if [[ -z "$CONFIG_FILE" || -z "$FLASH_DEVICE" ]]; then
    echo "❌  Missing required arguments."
    exit 1
  else
    echo "ℹ️  Provided parameter:"
    echo "CONFIG_FILE: $CONFIG_FILE"
    echo "UUID: $FLASH_DEVICE"
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
  echo "ℹ️  Restart $SERVICE ..."
  sudo systemctl restart "$SERVICE" || echo "❌  Failed to restart $SERVICE."
  # Funktion restart_klipper - When called: Starts the Klipper Sevice.
  #curl -X POST "http://localhost:7125/api/klipper/start" || echo "❌  WARNING: Failed to start $SERVICE";
} 

################################################################
is_katapult_bootloader() {
  local uuid="$1"

  # Prefer Katapult's flashtool.py (status probe; returns 0 only if bootloader is active)
  if [[ -f "$KATAPULT_FLASHTOOL" ]]; then
    "$PY_BIN" "$KATAPULT_FLASHTOOL" -i "$CAN_IF" -s -u "$uuid" >/dev/null 2>&1 && return 0
  fi

  # Fallback: flash_can.py --query and grep for this UUID shown as bootloader/Katapult
  if [[ -f "$KATAPULT_FLASH_CAN" ]]; then
    "$PY_BIN" "$KATAPULT_FLASH_CAN" -i "$CAN_IF" -q 2>/dev/null \
      | grep -Eqi "($uuid).*(katapult|bootloader|canboot)" && return 0
  fi

  # Not detected as bootloader
  return 1
}


################################################################################################
# Prepare Updates
################################################################################################
#####################
echo "ℹ️  Checking files and devices, based on parameters handed over ..."     
[[ -f "$CONFIG_FILE" ]] || error_exit "❌  Config file not found: $CONFIG_FILE"                    # Check if the config_file exists and if it is a normal file. If so: True
                                                                                                   # The bash file test operator -F

if [[ MODE = "usb" || MODE = "dfu" ]]; then
  [[ -n "$FLASH_DEVICE" ]] || error_exit "❌  No FLASH_DEVICE provided"                              # Check if a flash_devide is provided. If so: Tue.
                                                                                                   # The bash string test operator -n is used.
                                                                                                   # [] is a test command. [[ ]] is a extended test command.
                                                                                                   # || is like "else"
fi

if [[ MODE = "usb" || MODE = "can" ]]; then
  [[ -n "$UUID" ]] || error_exit "❌  No UUID provided"                                              # Check if a UUID is provided. If so: Tue.
fi

#####################
echo "ℹ️  Going to klipper folder ..."
cd ~/klipper/  || error_exit "❌  Klipper folder not found." 

#####################
echo "ℹ️  Clean up old builds ..."
make clean KCONFIG_CONFIG="$CONFIG_FILE" || error_exit "❌  Failed to clean old build by $CONFIG_FILE."   # Deleates artefacts from previous builds
make clean || error_exit "❌  make clean failed"                                                          # deleats all artefacts

echo "ℹ️  Updating configuration (olddefconfig) ..."
make olddefconfig KCONFIG_CONFIG="$CONFIG_FILE" || error_exit "❌  Failed to update config."         # Updates the build configurations based on the config file.


################################################################################################
# Klipper compiling and flashing routines
################################################################################################
# Skipr MCU via USB
if [[ "$MODE" = "usb" ]]; then
  cd "$HOME/klipper"   || error_exit "❌  lipper folder not found." 

  #echo "ℹ️  Show printer Config:"
  #grep canbus_uuid "$HOME/printer_data/config/"* -n  || error_exit "❌  Failed: grep."   # --> !!! WIRD FEHLERMLEDUNG !!!
 
  echo "Stop Klipper.service"
  stop_klipper

  echo "ℹ️  Start Katapult bootloader on controller ..."
  if [ ! -e "$FLASH_DEVICE" ]; then
    echo "Kein FLASH_DEVICE=$FLASH_DEVICE gefunden"
    "$HOME/klippy-env/bin/python" "$HOME/katapult/scripts/flashtool.py" -i can0 -u "$UUID" -r  || echo "❌  Failed: Starting Katapult bootloader."  
  else 
    echo "FLASH_DEVICE=$FLASH_DEVICE gefunden"
  fi

  echo "ℹ️  Is Katapult & ttyACM0 port asvailable?"
  sudo dmesg | tail -n 10  || echo "❌  desmg command failed."

  #echo "ℹ️  Build firmware..."
  #make clean
  #make -j"$(nproc)" KCONFIG_CONFIG="$CONFIG_FILE" || error_exit "❌  Building firmware failed."
  ## nproc is a linux command line utility that prints the number of processing units (CPU cores)

  #echo "ℹ️  Flashing firmware to controller..."
  #make flash FLASH_DEVICE="$FLASH_DEVICE"  || error_exit "❌  Flashing failed."

  echo "ℹ️  Building and flashing firmware..."
  make clean
  make -j"$(nproc)" KCONFIG_CONFIG="$CONFIG_FILE" flash FLASH_DEVICE="$FLASH_DEVICE" || error_exit "❌  Failed: Building or flashing firmware"
  # nproc is a linux command line utility that prints the number of processing units (CPU cores)

  echo "Start Klipper.service"
  start_klipper

fi


################################################################
# toolhead board via CAN
if [[ "$MODE" = "can" ]]; then
  cd "$HOME/klipper"   || error_exit "❌  lipper folder not found." 
  
  #echo "ℹ️  Show printer Config:"
  #grep canbus_uuid ~/printer_data/config/* -n   # --> !!! WIRD FEHLERMLEDUNG !!!
  
  echo "ℹ️  Building firmware ..."
  make clean
  make  -j"$(nproc)" KCONFIG_CONFIG="$CONFIG_FILE" || error_exit "❌  Failed: Building firmware"

  echo "ℹ️  Check (before stop_klipper): Is there a device? If not, dont worry!"
  $HOME/klippy-env/bin/python $HOME/klipper/scripts/canbus_query.py can0

  echo "Stop Klipper.service"
  stop_klipper

  echo "ℹ️  Check (after stop_klipper): Is there a device? If not, dont worry!"
  $HOME/klippy-env/bin/python $HOME/klipper/scripts/canbus_query.py can0

  echo "ℹ️  Start Katapult bootloader on controller ..."
  if is_katapult_bootloader "$UUID"; then
    echo "UUID=$UUID is in bootloader mode"
  else 
    echo "UUID=$UUID is not in bootlaoder mode"
    echo "Start bootloader mode"
    "$HOME/klippy-env/bin/python3" "$HOME/katapult/scripts/flash_can.py" -i can0 -u "$UUID" -r || error_exit "❌  Failed: Starting Katapult bootloader"
  fi

  echo "ℹ️  Check: Is device with the UUID $UUID in Katapult/CanBoot bootloader modus?"
  $HOME/klippy-env/bin/python $HOME/klipper/scripts/canbus_query.py can0

  echo "ℹ️  Flashing firmware to controller..."
  "$HOME/klippy-env/bin/python3" "$HOME/katapult/scripts/flash_can.py" -i can0  -f "$BIN_FILE" -u "$UUID" || error_exit "❌  Failed: Flashing"

  #echo "ℹ️  Start Katapult bootloader on controller & Flashing to controller ..."
  #"$HOME/klippy-env/bin/python3" "$HOME/katapult/scripts/flash_can.py" -i can0 -u "$UUID" -f "$BIN_FILE" -u "$UUID" || error_exit "❌  Starting Katapult bootloader or flashing failed."

  echo "ℹ️  Check (after flashing)"
  $HOME/klippy-env/bin/python $HOME/klipper/scripts/canbus_query.py can0

  echo "Start Klipper.service"
  start_klipper
fi

################################################################
# Linux MCU
if [[ "$MODE" = "linux" ]]; then
  cd ~/klipper   || error_exit "❌  lipper folder not found." 

  echo "Stop Klipper.service"
  stop_klipper || echo "❌  Stopping stop_klipper failed."

  echo "ℹ️  Stopping klipper-mcu ...:"
  sudo systemctl stop klipper-mcu || echo "❌  Stopping linux_mcu failed."

  echo "ℹ️  Copy klipper-mcu.service ..."
  sudo cp ~/klipper/scripts/klipper-mcu.service /etc/systemd/system/ || error_exit "❌  Copying Klipper-mcu.service failed."

  echo "ℹ️  Enable klipper-mcu service ..."
  sudo systemctl enable klipper-mcu.service || error_exit "❌  Enabling Klipper-mcu.service failed."

  echo "ℹ️  Grant current user acces to tty"
  sudo usermod -a -G tty $USER || error_exit "❌  Granting access failed."

  echo "ℹ️  Compiling and flashing of the firmware ..."
  make clean
  make flash -j"$(nproc)" KCONFIG_CONFIG="$CONFIG_FILE" || error_exit "❌  Building firmware failed."

  echo "ℹ️  Starting klipper_mcu and klipper..."
  sudo systemctl start klipper-mcu klipper || error_exit "❌  Starting klipper-mcu failed."

  echo "Start Klipper.service"
  start_klipper

  echo "ℹ️  Please reboot the system"
fi

################################################################
# DFU Skipr MCU without bootloader
if [[ "$MODE" = "dfu" ]]; then
  cd ~/klipper   || error_exit "❌  lipper folder not found." 

  echo "ℹ️  Building firmware ..."
  make clean
  make  -j"$(nproc)" KCONFIG_CONFIG="$CONFIG_FILE" || error_exit "❌  Building firmware failed."

  echo "Stop Klipper.service"
  stop_klipper

  echo "ℹ️  Activate DFU mode ..."
  echo "ℹ️  ... MCU must be in DFU mode. Manual tricker via BOOT & RESET button. If not flashing will fail."

  echo "ℹ️  Flashing to controller ..."
  $ dfu-util -R -a 0 -s "$FLASH_DEVICE" -D "$BIN_FILE"
  #$ dfu-util -R -a 0 -s 0x08000000:mass-erase:force -D ~/klipper/out/klipper.bin

  echo "ℹ️  Reset Controller ..."
  echo "ℹ️  ... press the RESET button."

  echo "Start Klipper.service"
  start_klipper
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