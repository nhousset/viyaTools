#!/bin/bash 

CAS_DISK_CACHE_PATH=sastmp
echo "UNIXTIMESTAMP;DATE;SAS_USER;PID;VSZ;RSS;UNIX_USER;NB_FILE_IN_CACHE" 
while [ 1=1 ]
do
  UnixDate=$(date +%s)
  FrenchDate=$(date '+%F %T');  
      
  CASLogFile=$(ls -lrt /var/log/sas/viya/cas/default/ | grep cas_ | tail -1 | awk '{print $9}' )
 
  sommeCpu=0
  nbSasProcess=0
  i=0
  for process in $(ps -aux | grep -v root | grep "cas session" | awk '{print $1";"$2";"$3";"$4";"$5";"$6";"$8";"$9}'  |  grep -v grep )
  do
  
   processUser=$(echo $process | cut -d ";" -f 1)
   processPID=$(echo $process | cut -d ";" -f 2)
   processCPU=$(echo $process | cut -d ";" -f 3)
   processMEM=$(echo $process | cut -d ";" -f 4)
   processVSZ=$(echo $process | cut -d ";" -f 5)
   processRSS=$(echo $process | cut -d ";" -f 6)
   processStart=$(echo $process | cut -d ";" -f 7)
   
   sasUser=$(grep "Launched session worker. Process ID is $processPID" /var/log/sas/viya/cas/default/$CASLogFile | tail -1 | awk '{print $5}'  )
   
   NB_FILE_MAP=$(lsof -p $processPID | grep $CAS_DISK_CACHE_PATH |wc -l)
   echo $UnixDate";"$FrenchDate";"$sasUser";"$processPID";"$processVSZ";"$processRSS";"$processUser";"$NB_FILE_MAP
   
  
  done
  echo ""
  sleep 30
  
 done
 
 

