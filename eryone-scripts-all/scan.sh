#!/bin/bash

################################################################################################
# File: scan.sh
# Author: Eryone / Edit by Andreas
# Date: 20250711 / 20250806
# purpose: network scanner → builds a printers.txt list of Moonraker boxes (port 7125) with their hostname.
# 
# !!! Scans only a specific network. pretty useless !!!
#
# How to call: ???
# Called in the x400_shell_commands_macros.cfg file
################################################################################################

#sleep 5

nmap -p 7125 192.168.2.1/24 -oG /tmp/test.txt  

cat /tmp/test.txt | sed -n '/open/p' | sed 's/^.*Host: //g' | sed 's/ (.*$//g' > /tmp/ip.txt
#cat test.txt | sed -n '/open/p' | sed 's/^.*Host://g' | sed 's/(.*$//g' > ip.txt

##
nums=$(sed -n '$=' /tmp/ip.txt)
for ((i=1;i<=nums;i++))
do
#       echo $i
#       output=$(ls -l)
#       echo $output
        line=$i'p'
#       echo $line
        ip=$(sed -n $line /tmp/ip.txt)
        echo $ip
        url=$ip'/all/hostname'
        echo $url
        name+=`curl -s  $url`','$ip';' #| sed 's/;//g'  
#        echo $name
done

echo $name |sed 's/;/\n/g'  > /home/mks/mainsail/all/printers.txt

exit 0 # This will exit the script before it gets to my notes below.


################################################################################################
################################################################################################
# Improve verison by chatGPT
################################################################################################

#!/bin/bash
set -euo pipefail

SUBNET="${1:-192.168.2.0/24}"
OUT="/home/mks/mainsail/all/printers.txt"
TMP="$(mktemp)"

# Scan only hosts with port 7125 open; stream grepable output
# --open = only show hosts with at least one open port
nmap -p 7125 --open -oG - "$SUBNET" |
awk '
  /Ports: .*open/ {
    # nmap grepable format: Host: <ip> (<name>)  Status: Up ...
    for (i=1;i<=NF;i++) if ($i=="Host:") { ip=$(i+1); break }
    print ip
  }
' | while read -r ip; do
  # grab hostname with sane timeouts; fall back to ip if empty
  name="$(curl -m 2 -s "http://$ip/all/hostname" || true)"
  [ -n "$name" ] || name="unknown"
  echo "$name,$ip"
done | sort -u > "$TMP"

# atomic replace
mv "$TMP" "$OUT"
echo "Wrote $(wc -l < "$OUT") printers to $OUT"


################################################################################################
################################################################################################
# Further improved verison of the chatGPT version by chatGPT
################################################################################################
#!/bin/bash
set -euo pipefail

SUBNET="${1:-192.168.2.0/24}"
OUT="/home/mks/mainsail/all/printers.txt"
TMP="$(mktemp)"

# Fast scan (-T4), only hosts with the port open (--open), grepable output (-oG -)
nmap -T4 -p 7125 --open -oG - "$SUBNET" | awk '
  /Ports: .*open/ {
    # "Host: <ip> (<name>) ..." -> extract <ip>
    for (i=1;i<=NF;i++) if ($i=="Host:") { ip=$(i+1); gsub(/[()]/,"",ip); break }
    print ip
  }
' | while read -r ip; do
  # Short, non-retrying curl; fall back to "unknown" if empty
  name="$(curl -s --retry 0 --connect-timeout 2 -m 2 "http://$ip/all/hostname" || true)"
  [ -n "$name" ] || name="unknown"
  echo "$name,$ip"
done | sort -u > "$TMP"

mkdir -p "$(dirname "$OUT")"
mv "$TMP" "$OUT"
echo "Wrote $(wc -l < "$OUT") printers to $OUT"


################################################################################################
################################################################################################
# Run the script in bash:
# $ ./scan_printers.sh            # scans 192.168.2.0/24 by default
# $ ./scan_printers.sh 192.168.178.0/24

# Make the script executable
# chmod +x /home/mks/scripts/scan_printers.sh
