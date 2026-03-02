#!/usr/bin/env bash
set -euo pipefail

################################################################################################
# File: mcu_firmware_update_all.sh
# Author: Andreas
# Date: 20251125
# Purpose: Calls the muc_update.sh for each MCU.
#
################################################################################################
echo "This is $(basename "$0")"
echo " "


################################################################################################
# Variables
################################################################################################
#Resolve repo root (parent of this script), then cd into it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

MCU_BOOTLOADER_CONFIGS_DIR="$REPO_DIR/mcu-bootloader-configurations"
MCU_FIRMWARE_CONFIGS_DIR="$REPO_DIR/mcu-firmware-configurations"

SKIPR_MCU_KLIPPER_FIRMWARE_CONFIG_FILE="$MCU_FIRMWARE_CONFIGS_DIR/stm32f407_klipper_firmware.config"
TOOLHEA_MCU_KLIPPER_FIRMWARE_CONFIG_FILE="$MCU_FIRMWARE_CONFIGS_DIR/rp2040_klipper_firmware.config"
LINUX_MCU_KLIPPER_FIRMWARE_CONFIG_FILE="$MCU_FIRMWARE_CONFIGS_DIR/linux_mcu_klipper_firmware.config"

SKIPR_MCU_PORT="/dev/ttyACM0"

# UUIDs auf canuid.cfg auslesen
CONFIG_FILE="$HOME/printer_data/config/canuid.cfg"
SKIPR_MCU_UUID=$(grep -A1 "\[mcu\]" "$CONFIG_FILE" | grep "canbus_uuid" | cut -d':' -f2- | tr -d ' ')   || error_exit "❌  Failed grep 1."            # mcu_canbus_uuid
TOOLHEAD_MCU_UUID=$(grep -A1 "\[mcu EECAN\]" $CONFIG_FILE | grep "canbus_uuid" | cut -d':' -f2- | tr -d ' ')   || error_exit "❌  Failed grep 2."   # mcu_eecan_canbus_uuid
RPI_MCU_PORT=$(grep -A1 "\[mcu rpi\]" $CONFIG_FILE | grep "serial" | cut -d':' -f2- | tr -d ' ')   || error_exit "❌  Failed grep 3."               # mcu_rpi_serial


################################################################################################
# Checks
################################################################################################
# Ensure helper script exists
if [[ ! -x "$SCRIPT_DIR/mcu_firmware_update.sh" ]]; then
  echo "❌  Not executable or missing: $SCRIPT_DIR/mcu_firmware_update.sh"
  echo "    Try: chmod +x \"$SCRIPT_DIR/mcu_firmware_update.sh\""
  exit 1
fi
echo " "


################################################################################################
# Update the MCUs Katapult Bootlaoder
################################################################################################
# Not possible without physical hardware interaction (pressing buttons)
# - SKIPR board: BOOT & RESET button
# - toolhead: USB connection & BOOT button


################################################################################################
# Update the MCUs Klipper Firmware
################################################################################################
read -p "❓  Shall Klipper be updated on the MCUs? [y/N]" answer
answer=${answer:-N}     # default to "N" if empty
echo " "

if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Installing MCU updates ..."
    cd "$REPO_DIR/scripts"  || { echo "❌ Folder not found: $REPO_DIR"; exit 1; }
    echo " "

    echo "ℹ️  Calling mcu_update.sh for linux mcu..."
    "$SCRIPT_DIR/mcu_firmware_update.sh" -m linux -c "$LINUX_MCU_KLIPPER_FIRMWARE_CONFIG_FILE" || echo "❌  Faild: Starting mcu_update.sh for Linux MCU"
    echo " "

    echo "ℹ️  Calling mcu_update.sh for SKIPR mcu..."
    "$SCRIPT_DIR/mcu_firmware_update.sh" -m usb -c "$MCU_FIRMWARE_CONFIGS_DIR/stm32f407_klipper_firmware.config" -u "$SKIPR_MCU_UUID" -d "$SKIPR_MCU_PORT" || echo "❌  Faild: Starting mcu_update.sh for SKIPR MCU"
    echo " "

    echo "ℹ️  Calling mcu_update.sh for toolhead mcu..."
    "$SCRIPT_DIR/mcu_firmware_update.sh" -m can -c "$MCU_FIRMWARE_CONFIGS_DIR/rp2040_klipper_firmware.config" -u "$TOOLHEAD_MCU_UUID" || echo "❌  Faild: Starting mcu_update.sh for Toolhead MCU"
    echo " "

    #echo "ℹ️  Call mcu_update.sh for piezzo stm32g on toolehad"
    # --> stm32g update not possible.

else
    echo "ℹ️  Important: Klipper software and klipper formware on MCUs need to be matching versions."
    echo " "
fi

echo "✅  mcu_update_all.sh complete"
exit 0
