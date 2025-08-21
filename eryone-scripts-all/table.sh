#!/bin/bash

################################################################################################
# File: table.sh
# Author: Eryone
# Date: 20250711
# purpose: Get the hostname for each IP adress in the ip.txt and saves it to the printer.txt file.
#
# How to call: ???
# Called in ???
################################################################################################

#output=`ls -l`
#echo $output
nums=$(sed -n '$=' /tmp/ip.txt)
for ((i=1;i<=nums;i++))
do
#	echo $i
#	output=$(ls -l)
#	echo $output
	line=$i'p'
#	echo $line
	ip=$(sed -n $line /tmp/ip.txt)
#        echo $ip
        url=$ip'/all/hostname'
#	echo $url
	name+=`curl -s  $url`','$ip';' #| sed 's/;//g'  
	echo $name
done

echo $name |sed 's/;/\n/g'  >$HOME/mainsail/all/printers.txt

