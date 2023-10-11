#!/bin/bash 

CAS_DISK_CACHE_PATH=cas_cache_disk
echo "nomServeur,UnixDate,FrenchDate,sasUser,processPID,processVSZ,processRSS,processUser,NB_FILE_MAP,SIZE_IN_CACHE,memTotal,memUsed,memFree,memShared,memCache,memAvailable,sasDate,processVSZGO,processRSSGO,SIZE_IN_CACHE_GO"
while [ 1=1 ]
do
  UnixDate=$(date +%s)
  FrenchDate=$(date '+%F %T');  
  nomServeur=$(hostname);

  memTotal=$(free | grep -v total | grep -v Swap | awk '{print $2}'| awk '{printf("%13.2f",$1/1024/1024)}' )
  memUsed=$(free | grep -v total | grep -v Swap | awk '{print $3}'| awk '{printf("%13.2f",$1/1024/1024)}' )
  memFree=$(free | grep -v total | grep -v Swap | awk '{print $4}' | awk '{printf("%13.2f",$1/1024/1024)}')
  memShared=$(free | grep -v total | grep -v Swap | awk '{print $5}'| awk '{printf("%13.2f",$1/1024/1024)}' )
  memCache=$(free | grep -v total | grep -v Swap | awk '{print $6}'| awk '{printf("%13.2f",$1/1024/1024)}' )
  memAvailable=$(free | grep -v total | grep -v Swap | awk '{print $7}' | awk '{printf("%13.2f",$1/1024/1024)}')
   
  NB_FILE_MAP=$(lsof -p $processPID | grep $CAS_DISK_CACHE_PATH |wc -l)
  typeset -i SIZE_IN_CACHE=0
  SIZE_IN_CACHE=`expr $NB_FILE_MAP*8*1024*1024`
  SIZE_IN_CACHE_GO=$(echo $SIZE_IN_CACHE | awk '{printf("%13.2f",$1/1024/1024/1024)}')  
    
  typeset -i sasDate=0
     
  sasDate=`expr $UnixDate-315360000`
  echo $nomServeur","$UnixDate","$FrenchDate","$sasUser","$processPID","$processVSZ","$processRSS","$processUser","$NB_FILE_MAP","$SIZE_IN_CACHE","$memTotal","$memUsed","$memFree","$memShared","$memCache","$memAvailable","$sasDate","$processVSZGO","$processRSSGO","$SIZE_IN_CACHE_GO
   
  
  
  sleep 10
done
 
 
