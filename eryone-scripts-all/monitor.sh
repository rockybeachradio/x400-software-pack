#!/bin/bash

################################################################################################
# File: monitor.sh
# Author: Eryone
# Date: 20250711
# purpose: !!! it is doing nothing
#
# Hat coud di if there is no "exit 0" in the first line
#   It waits 5 seconds, sets 777 permissions on /home/mks/mainsail/all/*, then loops forever checking CPU idle every 3 seconds.
#   If idle stays below 25% for over 10 checks (~30s), it pauses the printer via a local HTTP call and logs CPU stats; otherwise it just keeps monitoring (printing “checking” about every two minutes).
#
# How to call: ???
# Called in ???
################################################################################################

exit 0

function log_cpu(){
    cpu_user=`top -b -n 1 | grep Cpu | awk '{print $2}' | cut -f 1 -d "%"`
    cpu_system=`top -b -n 1 | grep Cpu | awk '{print $4}' | cut -f 1 -d "%"`
    cpu_idle=`top -b -n 1 | grep Cpu | awk '{print $8}' | cut -f 1 -d "%"`
    cpu_iowait=`top -b -n 1 | grep Cpu | awk '{print $10}' | cut -f 1 -d "%"`
    echo  $(date +%T)"cpu_idle:"$cpu_idle" cpu_iowait:"$cpu_iowait "cpu_system:"$cpu_system "cpu_user:"$cpu_user "pause printer.."  >> ~/printer_data/logs/cpu.log
   
}

function ceil(){
  floor=`echo "scale=0;$1/1"|bc -l ` # 向下取整
  add=`awk -v num1=$floor -v num2=$1 'BEGIN{print(num1<num2)?"1":"0"}'`
  echo `expr $floor  + $add`
   
}

sleep 5
chmod 777 /home/mks/mainsail/all/*

declare -i nn
((nn=0))

declare -i cn
((cn=0))

while [ 1 ]
do
    ((nn=nn + 1))
    #echo $nn
    if [ $((nn%40)) -eq 38 ]
    then
      echo "checking "
      #log_t=$(/home/mks/mainsail/all/check_version.sh)
      #echo $log_t
    fi  
    sleep 3
    
    cpu_idle=`top -b -n 1 | grep Cpu | awk '{print $8}' | cut -f 1 -d "%"`
    #echo $(date +%T)cpu_idle:"$cpu_idle"
    #echo `ceil $cpu_idle` 
    cpu_int=$( echo `ceil $cpu_idle` )
    #echo $cpu_int
    
    if [ $((cpu_int)) -lt 25 ] 
    then
      echo "cpu high load "
      ((cn=cn + 1))
      if [ $((cn)) -gt 10 ]
      then
         echo "pause printer.."
         curl -d "" "http://127.0.0.1/printer/print/pause"
         log_cpu
         ((cn=0))
      fi

    else
       ((cn=0))
    fi
   # echo $cpu_int

done



