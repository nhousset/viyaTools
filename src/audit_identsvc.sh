#!/bin/bash 

export LOG_FILE="/tmp/identsvcs.csv";
while [ 1=1 ]
do
 UnixDate=$(date +%s)
 FrenchDate=$(date '+%F %T');  
 pid=$(ps -u root -f | grep identsvcs | grep -v grep | awk '{print $2}' )
 startDate=$(ps -u root -f | grep identsvcs | grep -v grep | awk '{print $5}' )
 processStat=$(cat /proc/$pid/stat |  sed s/" "/";"/g)
 
 echo $UnixDate";"$FrenchDate";"$startDate";"$pid";"$processStat  | tee -a $LOG_FILE
 sleep 10

done
