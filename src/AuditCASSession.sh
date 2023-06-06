#!/bin/bash 

CAS_DISK_CACHE_PATH=cas_cache_disk
echo "nomServeur,UnixDate,FrenchDate,sasUser,processPID,processVSZ,processRSS,processUser,NB_FILE_MAP,SIZE_IN_CACHE,memTotal,memUsed,memFree,memShared,memCache,memAvailable,sasDate,processMEMGO,processVSZGO,processRSSGO,SIZE_IN_CACHE_GO"
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
   
   
   processMEMGO=$(echo $processMEM / 1024/ 1024 | bc -l )
   processVSZGO=$(echo $processVSZ / 1024/ 1024 | bc -l )
   processRSSGO=$(echo $processRSS  / 1024/ 1024 | bc -l )
   
   sasUser=$(grep "Launched session" /var/log/sas/viya/cas/default/$CASLogFile |  grep "Process ID is $processPID" | tail -1 | awk '{print $5}'  )
   
   
   memTotal=$(free | grep -v total | grep -v Swap | awk '{print $2}' )
   memUsed=$(free | grep -v total | grep -v Swap | awk '{print $3}' )
   memFree=$(free | grep -v total | grep -v Swap | awk '{print $4}' )
   memShared=$(free | grep -v total | grep -v Swap | awk '{print $5}' )
   memCache=$(free | grep -v total | grep -v Swap | awk '{print $6}' )
   memAvailable=$(free | grep -v total | grep -v Swap | awk '{print $7}' )
   
   NB_FILE_MAP=$(lsof -p $processPID | grep $CAS_DISK_CACHE_PATH |wc -l)
   typeset -i SIZE_IN_CACHE=0
   SIZE_IN_CACHE=`expr $NB_FILE_MAP*8*1024*1024`
   SIZE_IN_CACHE_GO=$(echo $SIZE_IN_CACHE  / 1024/ 1024 | bc -l )
    
   typeset -i sasDate=0
     
   sasDate=`expr $UnixDate-315360000`
   echo $nomServeur","$UnixDate","$FrenchDate","$sasUser","$processPID","$processVSZ","$processRSS","$processUser","$NB_FILE_MAP","$SIZE_IN_CACHE","$memTotal","$memUsed","$memFree","$memShared","$memCache","$memAvailable","$sasDate","$processMEMGO","$processVSZGO","$processRSSGO","$SIZE_IN_CACHE_GO
   
  
  done
  sleep 10
  
 done
 
 

