#!/bin/bash
set -euo pipefail

################################################################################################
# File: read_write_uuid_file.sh
# Author: Andreas
# Date: 20250925
# Purpose:  Read the UUIDs from teh canuid.cfg
#           Ask if io? Change tehm.
#           Writes UUIDs to the canuid.cfg
################################################################################################
echo "This is $(basename "$0")"

################################################################################################
# Variable declaration
################################################################################################
CONFIG_FILE="$HOME/printer_data/config/canuid.cfg"


################################################################################################
# Checks
################################################################################################
# Check if the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: $CONFIG_FILE not found!"
  exit 1
fi


################################################################################################
# Read uuids
################################################################################################
# Extract canbus_uuid and serial values
mcu_canbus_uuid=$(grep -A1 "\[mcu\]" "$CONFIG_FILE" | grep "canbus_uuid" | cut -d':' -f2- | tr -d ' ')
mcu_eecan_canbus_uuid=$(grep -A1 "\[mcu EECAN\]" "$CONFIG_FILE" | grep "canbus_uuid" | cut -d':' -f2- | tr -d ' ')
mcu_rpi_serial=$(grep -A1 "\[mcu rpi\]" "$CONFIG_FILE" | grep "serial" | cut -d':' -f2- | tr -d ' ')

# Check if values were extracted successfully
if [ -z "$mcu_canbus_uuid" ]; then
  echo "Error: Failed to extract mcu_canbus_uuid one or more values from $CONFIG_FILE"
  exit 1
elif [ -z "$mcu_eecan_canbus_uuid" ]; then
  echo "Error: Failed to extract mcu_eecan_canbus_uuid one or more values from $CONFIG_FILE"
  exit 1
elif [ -z "$mcu_rpi_serial" ]; then
  echo "Error: Failed to extract mcu_rpi_serial one or more values from $CONFIG_FILE"
  exit 1
fi



################################################################################################
# Show current UUIDs and ask vor new one
################################################################################################
read -p "Is the mcu_canbus_uuid $mcu_canbus_uuid correct? If yes hit enter, if not, enter the new one: " answer
answer=${answer:-Y}
# If user pressed Enter (empty input), confirm the value
if [ -z "$answer" ] || [[ "$answer" =~ ^[Yy](es)?$ ]]; then   # If answer: Y, y or yes
  echo "okay. keeping uuid."
else
  # Trim whitespace from the new value and update mcu_canbus_uuid
  mcu_canbus_uuid=$(echo "$answer" | tr -d '[:space:]')
  read -p "New value for mcu_canbus_uuid = $mcu_canbus_uuid Is the value correct [y/N]?" answer
  answer=${answer:-N}     # default to "N" if empty
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    # Write the new value back to the file
    sed -i "/\[mcu\]/,/^\[/ s/canbus_uuid:.*/canbus_uuid:$mcu_canbus_uuid/" "$CONFIG_FILE"   || echo "❌  Writing failed"
  
     # Check if sed command was successful
    if [ $? -eq 0 ]; then
      echo -e "\nSuccessfully updated $CONFIG_FILE"
    else
      echo -e "\nError: Failed to update $CONFIG_FILE"
    fi
  fi
fi

read -p "Is the mcu_eecan_canbus_uuid $mcu_eecan_canbus_uuid correct? If yes hit enter, if not, enter the new one: " answer
answer=${answer:-Y}
# If user pressed Enter (empty input), confirm the value
if [ -z "$answer" ] || [[ "$answer" =~ ^[Yy](es)?$ ]]; then   # If answer: Y, y or yes
  echo "okay. keeping uuid."
else
  # Trim whitespace from the new value and update mcu_canbus_uuid
  mcu_eecan_canbus_uuid=$(echo "$answer" | tr -d '[:space:]')
  read -p "New value for mcu_eecan_canbus_uuid = $mcu_eecan_canbus_uuid Is the value correct [y/N]?" answer
  answer=${answer:-N}     # default to "N" if empty
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    # Write the new value back to the file
    sed -i "/\[mcu EECAN\]/,/^\[/ s/canbus_uuid:.*/canbus_uuid:$mcu_eecan_canbus_uuid/" "$CONFIG_FILE"   || echo "❌  Writing failed"
  
     # Check if sed command was successful
    if [ $? -eq 0 ]; then
      echo -e "\nSuccessfully updated $CONFIG_FILE"
    else
      echo -e "\nError: Failed to update $CONFIG_FILE"
    fi
  fi
fi

read -p "Is the mcu_rpi_serial $mcu_rpi_serial correct? If yes hit enter, if not, enter the new one: " answer
answer=${answer:-Y}
# If user pressed Enter (empty input), confirm the value
if [ -z "$answer" ] || [[ "$answer" =~ ^[Yy](es)?$ ]]; then   # If answer: Y, y or yes
  echo "okay. keeping uuid."
else
  # Trim whitespace from the new value and update mcu_canbus_uuid
  mcu_rpi_serial=$(echo "$answer" | tr -d '[:space:]')
  read -p "New value for mcu_rpi_serial = $mcu_rpi_serial Is the value correct [y/N]?" answer
  answer=${answer:-N}     # default to "N" if empty
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    # Write the new value back to the file
    sed -i "/\[mcu rpi\]/,/^\[/ s/serial:.*/serial:$mcu_rpi_serial/" "$CONFIG_FILE"   || echo "❌  Writing failed"
  
     # Check if sed command was successful
    if [ $? -eq 0 ]; then
      echo -e "\nSuccessfully updated $CONFIG_FILE"
    else
      echo -e "\nError: Failed to update $CONFIG_FILE"
    fi
  fi
fi


################################################################################################
# Check if sed commands were successful
################################################################################################
exit 0