#!/bin/bash

################################################################################################
# File: plr.sh
# Author: Eryone
# Date: 20250812
# purpose: PLR - Power Loss Recovery Helper - Shell Script
# 
# From GitCode
#
#
# Input:
#   - Z height
#   - G-code file
# Output:
#   - plr.gcode file
#
# Script is called in
#   - x400.cfg file
#
################################################################################################

# 1) For Debug:
    echo ${1}           # the target Z layer height
    echo ${2}           # full patch to the original G-Code file to resume. /eg /home/mls/printer_data/gcodes/part.gcode)

# 2) Prepare files in tmp fodler
    #rm /tmp/plr.gcode
    #z_s=$(echo ${1})
    #z_p=${1} #$("${1}" | sed 's/\./\\./g')
    echo -n > /tmp/plr.gcode                        # clear the file. Using > truncates (or creates) the file to zero bytes. echo -n prints nothing (no newline), so you end up with an empty file.
    echo -n > /tmp/pose                             # clears the file

    echo "date0: $(date +"%Y-%m-%d %H:%M:%S")"      # print a timestamp to the consol/termins/bash
    #echo 'START_TEMPS' >> /tmp/plr.gcode

# 3) Re-insert temperature commands
    # The section below recovers: M104 / M109 (Hotend temp). M140 / M190 (Bed temp)
    cat "${2}" | sed '/G1 Z'${1}'/q' | sed -ne '/\(M104\|M140\|M109\|M190\)/p' >> /tmp/plr.gcode
        # cat "${2}"                                        # Manipulate file $2
        # sed '/G1 Z'${1}'/q' \                             # Read the content of the file up to the line matching: G1 Z<Z>. Then stop: q
        # sed -ne '/\(M104\|M140\|M109\|M190\)/p' \         # From the read part, keep only the commands: M104 M109 M140 M190
        # >> /tmp/plr.gcode                                 # Output to a file
    echo "date21: $(date +"%Y-%m-%d %H:%M:%S")"             # print a timestamp to the consol/termins/bash

# (deactevated by eryone in newer version)
    #cat /tmp/plrtmpA.$$ | sed -e '1,/ Z'${1}'[^0-9]*$/ d' | sed -e '/ Z/q' | tac | grep -m 1 ' E' | sed -ne 's/.* E\([^ ]*\)/G92 E\1/p' >> /tmp/plr.gcode
    #tac /tmp/plrtmpA.$$ | sed -e '/ Z'${1}'[^0-9]*$/q' | tac | tail -n+2 | sed -e '/ Z[0-9]/ q' | tac | sed -e '/ E[0-9]/ q' | sed -ne 's/.* E\([^ ]*\)/G92 E\1/p' >> /tmp/plr.gcode

# 4) Set extruder position (E axis) correctly. to ensure Klipper knows the current extrusion state.
    # Find the last extruder postition before the target Z.
    BG_EX=`tac "${2}" | sed -e '/G1 Z'${1}'[^0-9]*$/q' | tac | tail -n+2 | sed -e '/ Z[0-9]/ q' | tac | sed -e '/ E[0-9]/ q' | sed -ne 's/.* E\([^ ]*\)/G92 E\1/p'`
        # tac "${2}"                                # Reverses the file line order. We’ll use this trick to “walk backwards” from the end of the file.
        # sed -e '/G1 Z'${1}'[^0-9]*$/q'            # On the reversed stream, print lines until we hit a line that matches G1 Z<Ztarget> and then quit (q).
        #                                           # q - Because we’re on the reversed file, this effectively selects from the original end of file back up to (and including) the first line that sets Z=<target>.
        #                                           # The pattern [^0-9]*$ tries to ensure the value ends there (so Z12.4 doesn’t match Z12.40).
        # trac:                                     # 2nd time - Reverse that selection back to original order.
        # tail -n+2                                 # Drop the first line (the G1 Z<Ztarget> line itself). Now we have only the G-code after the target Z move.
        # sed -e '/ Z[0-9]/ q'                      # From those lines, keep printing until we encounter the next Z move (line containing Z followed by a digit), then quit.
        # trac                                      # 3rd time - Reverse the target-layer chunk. Now the end of the layer is first, and the beginning is last.
        # sed -e '/ E[0-9]/ q'                      # Walk this reversed chunk until the first line that contains an E value (extrusion), then quit.
        #                                           # Because we’re reversed, that “first” line is actually the last extrusion line in the layer when viewed in normal order.
        # sed -ne 's/.* E\([^ ]*\)/G92 E\1/p'       # On that single line, extract the E number and emit a line: G92 E<that_value>

    if [ "${BG_EX}" = "" ]; then     # if nothing found
        # s et the E axis to the first E value present in the resemued gcode.  This avoids extruding a huge blod on resume, and/or max extrusion errors.
        BG_EX=`tac "${2}" | sed -e '/G1 Z'${1}'[^0-9]*$/q' | tac | tail -n+2 | sed -ne '/ Z/,$ p' | sed -e '/ E[0-9]/ q' | sed -ne 's/.* E\([^ ]*\)/G92 E\1/p'`
    fi
    
    echo "date4: $(date +"%Y-%m-%d %H:%M:%S")"              # print a timestamp to the consol/termins/bash

# 5) setup resume commands. Insert gcode commands into the plr.gcode file.
    echo 'G92 E0' >> /tmp/plr.gcode                         # reset extruder
    echo 'M83' >> /tmp/plr.gcode                            # relative extrusion
    echo 'G90' >> /tmp/plr.gcode                            # absolute XY/Z

    echo ${BG_EX} >> /tmp/plr.gcode                         # G92 E<last_value>

    echo 'SET_KINEMATIC_POSITION Z='$1 >> /tmp/plr.gcode    # tell firmware we're at Z=<target>
    echo 'G91' >> /tmp/plr.gcode                            # relative
    echo 'G1 Z4' >> /tmp/plr.gcode                          # lift Z
    echo 'G90' >> /tmp/plr.gcode                            # absolute
    echo 'G4 P1000' >> /tmp/plr.gcode                       # 1s dwell
    echo 'G28 X Y' >> /tmp/plr.gcode                        # home XY (not Z!)
    echo 'G4 P1000' >> /tmp/plr.gcode                       # s.o.
    echo 'G91' >> /tmp/plr.gcode                            # s.o.
    echo 'G1 Z-4.03' >> /tmp/plr.gcode                      # lower back (slightly overcompensated)
    echo 'G90' >> /tmp/plr.gcode                            # s.o.
    echo 'M83' >> /tmp/plr.gcode                            # s.o.
    echo 'G92 E0' >> /tmp/plr.gcode                         # s.o
   
    echo 'G1 X395 Y50 E3.7 F12000' >> /tmp/plr.gcode        # Linear move to X=395, Y=50 while extruding 3.7 mm of filament. F12000 = 12000 mm/min ≈ 200 mm/s feed rate.
    echo 'G1 X395 Y130 E3.7 ' >> /tmp/plr.gcode             # Linear move to X=395, Y=130 (same X, higher Y), again extruding 3.7 mm. No F given → reuses the previous feed rate (still 12000 mm/min).
    echo 'G1 X395 Y50 E3.7 ' >> /tmp/plr.gcode
    echo 'G1 X395 Y130 E3.7 ' >> /tmp/plr.gcode
    echo 'G1 X395 Y50 E3.7 ' >> /tmp/plr.gcode      
    echo 'G1 X395 Y130 E3.7 ' >> /tmp/plr.gcode 
    echo 'G1 X395 Y50 E3.7 ' >> /tmp/plr.gcode      
    echo 'G1 X395 Y130 E3.7 ' >> /tmp/plr.gcode 
    echo 'G1 X395 Y50 E3.7 ' >> /tmp/plr.gcode      
    echo 'G1 X395 Y130 E3.7 ' >> /tmp/plr.gcode 
    echo 'G1 X395 Y50 E3.7 ' >> /tmp/plr.gcode      
    echo 'G1 X395 Y130 E3.7 ' >> /tmp/plr.gcode 

    #echo 'G1 E2' >> /tmp/plr.gcode                          # prime a bit      # (deleated by eryone in newer version 20250814)
    #echo 'G1 X350 Y350 F6000' >> /tmp/plr.gcode             # park             # (deleated by eryone in newer version 20250814)
   
    echo 'G92 E0' >> /tmp/plr.gcode                         # s.o
    echo 'M106 S250' >> /tmp/plr.gcode                      # fan on
    echo 'SET_KINEMATIC_POSITION Z='$1 >> /tmp/plr.gcode    # reaffirm Z
    
    echo "date5: $(date +"%Y-%m-%d %H:%M:%S")"              # print a timestamp to the consol/termins/bash
    #cat "${2}" | sed -e '1,/G1 Z'${1}'/d' | sed -ne '/ Z/,$ p' >> /tmp/plr.gcode         # (deactevated by eryone in newer version)

# 6) ???
    #tac /tmp/plrtmpA.$$ | sed -e '/ Z'${1}'[^0-9]*$/q' | tac | tail -n+2 | sed -ne '/ Z/,$ p' >> /tmp/plr.gcode          # (deactevated by eryone in newer version)

# 7) Compute the resume byte offset inside the original file
    z_p=$(echo ${1} | sed 's/\./\\./g')             # escape dot for regex
    position=$(grep -b "G1 Z${z_p}" "${2}" | cut -d':' -f1 | tr '\n' ' ' | cut -d ' ' -f1)      # grep -b returns byte offsets of matches.
    echo ${position} > /tmp/pose                    # It takes the first match’s offset and writes it to /tmp/pose.
    echo $(grep -b "G1 Z${z_p}" ${2})               # Also logs the match and base filename

# 8) ???
    filename=$(basename "${2}")                     # Get filename out fo the variable which contains path and filename. basename strips the directory part and returns just the last path component (the file name). The quotes around "${2}" keep spaces intact.
    echo ${filename}                                # print the <filename> to the terminal/console/bash

    echo "date6: $(date +"%Y-%m-%d %H:%M:%S")"      # print a timestamp to the consol/termins/bash

# 9) ???
    sync            # Flushes all pending writes from memory buffers to disk (or flash storage). Ensures that any files you've just written or modified are physically stored, not just sitting in RAM.
    #sleep 10       #  pauses the script for 10 seconds
    #curl -X POST http://127.0.0.1/printer/gcode/script?script=SDCARD_PRINT_FILE%20FILENAME=${filename}%20P=${position}     # tell Moonraker/Klipper to start printing $filename from byte position $position (note: P= is not in upstream Klipper; it’s a vendor/fork extension).
