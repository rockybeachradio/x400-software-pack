#!/bin/bash
echo ${2}       # ???

################################################################################################
# File: plr.sh
# Author: Eryone
# Date: 20250806
# purpose: PLR - Power Loss Recovery Shell Script
# 
# Called in the x400.cfg file
################################################################################################

# 1) Cleanup
    SD_PATH=~/printer_data/gcodes                                   # set path where the new plr.gcode will be saved
    rm ${SD_PATH}/plr.gcode                                         # deletes any previous version of plr.code file

#SD_PATH=~octoprint/.octoprint/uploads

# 2) Copy original G-code into temp file
    cat ${2} > /tmp/plrtmpA.$$                                      # ${2} is the original G-code filename. $$ makes the temp filename unique (uses the current process ID)

# 3) Preserve G-code thumbnail and header
    cat /tmp/plrtmpA.$$ | sed -n '/HEADER_BLOCK_START/,/THUMBNAIL_BLOCK_END/{p}' > ${SD_PATH}/plr.gcode         #Extracts the thumbnail and metadata block from the original G-code. Ensures it shows up in UI (e.g. Fluidd, Mainsail)
    echo '' >> ${SD_PATH}/plr.gcode

# 4) Replace floating Z values that could cause parsing errors
    sed -i 's/Z\./Z0\./g' /tmp/plrtmpA.$$                           # Fixes Z. → Z0. (e.g., Z. is invalid in G-code parsers)
    #sed -i 's/z./z0./g' /tmp/plrtmpA.$$

# ???
    #cat /tmp/plrtmpA.$$ | sed -e '1,/Z'${1}'/ d' | sed -ne '/ Z/,$ p' | grep -m 1 ' Z' | sed -ne 's/.* Z\([^ ]*\)/SET_KINEMATIC_POSITION Z=\1/p' > ${SD_PATH}/plr.gcode
    #echo 'START_TEMPS' >> ${SD_PATH}/plr.gcode         # ???

# 5) Re-insert temperature commands
    # The section below recovers: M104 / M109 (Hotend temp). M140 / M190 (Bed temp). M106 (Fan)
    cat /tmp/plrtmpA.$$ | sed '/G1 Z'${1}'/q' | sed -ne '/\(M104\|M140\|M109\|M190\|M106\)/p' >> ${SD_PATH}/plr.gcode
    cat /tmp/plrtmpA.$$ | sed -ne '/;End of Gcode/,$ p' | tr '\n' ' ' | sed -ne 's/ ;[^ ]* //gp' | sed -ne 's/\\\\n/;/gp' | tr ';' '\n' | grep material_bed_temperature | sed -ne 's/.* = /M140 S/p' | head -1 >> ${SD_PATH}/plr.gcode
    cat /tmp/plrtmpA.$$ | sed -ne '/;End of Gcode/,$ p' | tr '\n' ' ' | sed -ne 's/ ;[^ ]* //gp' | sed -ne 's/\\\\n/;/gp' | tr ';' '\n' | grep material_print_temperature | sed -ne 's/.* = /M104 S/p' | head -1 >> ${SD_PATH}/plr.gcode
    cat /tmp/plrtmpA.$$ | sed -ne '/;End of Gcode/,$ p' | tr '\n' ' ' | sed -ne 's/ ;[^ ]* //gp' | sed -ne 's/\\\\n/;/gp' | tr ';' '\n' | grep material_bed_temperature | sed -ne 's/.* = /M190 S/p' | head -1 >> ${SD_PATH}/plr.gcode
    cat /tmp/plrtmpA.$$ | sed -ne '/;End of Gcode/,$ p' | tr '\n' ' ' | sed -ne 's/ ;[^ ]* //gp' | sed -ne 's/\\\\n/;/gp' | tr ';' '\n' | grep material_print_temperature | sed -ne 's/.* = /M109 S/p' | head -1 >> ${SD_PATH}/plr.gcode
    #cat /tmp/plrtmpA.$$ | sed -e '1,/ Z'${1}'[^0-9]*$/ d' | sed -e '/ Z/q' | tac | grep -m 1 ' E' | sed -ne 's/.* E\([^ ]*\)/G92 E\1/p' >> ${SD_PATH}/plr.gcode
    #tac /tmp/plrtmpA.$$ | sed -e '/ Z'${1}'[^0-9]*$/q' | tac | tail -n+2 | sed -e '/ Z[0-9]/ q' | tac | sed -e '/ E[0-9]/ q' | sed -ne 's/.* E\([^ ]*\)/G92 E\1/p' >> ${SD_PATH}/plr.gcode

# 6) Set extruder position (E axis) correctly. to ensure Klipper knows the current extrusion state.
    BG_EX=`tac /tmp/plrtmpA.$$ | sed -e '/G1 Z'${1}'[^0-9]*$/q' | tac | tail -n+2 | sed -e '/ Z[0-9]/ q' | tac | sed -e '/ E[0-9]/ q' | sed -ne 's/.* E\([^ ]*\)/G92 E\1/p'`      # Uses a combination of tac (reverse) and grep to find the last known E value before the power loss

    # If we failed to match an extrusion command (allowing us to correctly set the E axis) prior to the matched layer height, then simply set the E axis to the first E value present in the resemued gcode.  This avoids extruding a huge blod on resume, and/or max extrusion errors.
    if [ "${BG_EX}" = "" ]; then
    BG_EX=`tac /tmp/plrtmpA.$$ | sed -e '/G1 Z'${1}'[^0-9]*$/q' | tac | tail -n+2 | sed -ne '/ Z/,$ p' | sed -e '/ E[0-9]/ q' | sed -ne 's/.* E\([^ ]*\)/G92 E\1/p'`
    fi
    echo 'G92 E0' >> ${SD_PATH}/plr.gcode
    echo 'M83' >> ${SD_PATH}/plr.gcode
    echo 'G90' >> ${SD_PATH}/plr.gcode

    echo ${BG_EX} >> ${SD_PATH}/plr.gcode

# 7) Insert resume commands
    # This block prepares the printer to resume safely. This avoids crashing into the part and ensures nozzle is primed before resuming.
    echo 'SET_KINEMATIC_POSITION Z='$1 >> ${SD_PATH}/plr.gcode
    echo 'G91' >> ${SD_PATH}/plr.gcode
    echo 'G1 Z4' >> ${SD_PATH}/plr.gcode
    echo 'G90' >> ${SD_PATH}/plr.gcode
    echo 'G28 X Y' >> ${SD_PATH}/plr.gcode
    echo 'G91' >> ${SD_PATH}/plr.gcode
    echo 'G1 Z-4.08' >> ${SD_PATH}/plr.gcode
    echo 'G90' >> ${SD_PATH}/plr.gcode
    echo 'M83' >> ${SD_PATH}/plr.gcode
    echo 'G92 E0' >> ${SD_PATH}/plr.gcode
    echo 'G1 E2' >> ${SD_PATH}/plr.gcode
    echo 'G1 X350 Y350 F6000' >> ${SD_PATH}/plr.gcode
    echo 'G92 E0' >> ${SD_PATH}/plr.gcode
    echo 'SET_KINEMATIC_POSITION Z='$1 >> ${SD_PATH}/plr.gcode

cat /tmp/plrtmpA.$$ | sed -e '1,/G1 Z'${1}'/d' | sed -ne '/ Z/,$ p' >> ${SD_PATH}/plr.gcode


# 8) Append remaining print
    # This complicated pipeline:
    # - Skips all layers above the resume height
    # - Starts appending lines from just below the resume Z height
    # - Adds the remaining G-code to plr.gcode
    # So the new file resumes from approximately the last good layer.
    #tac /tmp/plrtmpA.$$ | sed -e '/ Z'${1}'[^0-9]*$/q' | tac | tail -n+2 | sed -ne '/ Z/,$ p' >> ${SD_PATH}/plr.gcode      # (deactevated by eryone in newer version)

# ???
    if [ $(stat -c %s ${SD_PATH}/plr.gcode) -gt 1024 ]; then
    echo ">lk"
    fi

# 9) Cleanup
    rm /tmp/plrtmpA.$$      # Removes the temporary file.

# ???
    sync
    curl -X POST http://127.0.0.1/printer/gcode/script?script=SDCARD_PRINT_FILE%20FILENAME=plr.gcode