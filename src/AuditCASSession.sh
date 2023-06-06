#!/bin/bash 

CAS_DISK_CACHE_PATH=sastmp
while [ 1=1 ]
do
  UnixDate=$(date +%s)
  FrenchDate=$(date '+%F %T');  
  nomServeur=$(hostname);
  
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
   
   sasUser=$(grep "Launched session" /var/log/sas/viya/cas/default/$CASLogFile |  grep "Process ID is $processPID" | tail -1 | awk '{print $5}'  )
   
   
   memTotal=$(free | grep -v total | grep -v Swap | awk '{print $2}' )
   memUsed=$(free | grep -v total | grep -v Swap | awk '{print $3}' )
   memFree=$(free | grep -v total | grep -v Swap | awk '{print $4}' )
   memShared=$(free | grep -v total | grep -v Swap | awk '{print $5}' )
   memCache=$(free | grep -v total | grep -v Swap | awk '{print $6}' )
   memAvailable=$(free | grep -v total | grep -v Swap | awk '{print $7}' )
   
   NB_FILE_MAP=$(lsof -p $processPID | grep $CAS_DISK_CACHE_PATH |wc -l)
   echo $nomServeur";"$UnixDate";"$FrenchDate";"$sasUser";"$processPID";"$processVSZ";"$processRSS";"$processUser";"$NB_FILE_MAP";"$NB_FILE_MAP";"$memTotal";"$memUsed";"$memFree";"$memShared";"$memCache";"$memAvailable
   
  
  done
  echo ""
  sleep 30
  
 done
 
 

