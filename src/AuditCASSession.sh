#!/bin/bash 

export CAS_DISK_CACHE_PATH="/sastmp"
export LOG_FILE="/tmp/auditCASSession.csv";
echo "nomServeur,UnixDate,FrenchDate,sasUser,processPID,processVSZ,processRSS,processUser,NB_FILE_MAP,SIZE_IN_CACHE,memTotal,memUsed,memFree,memShared,memCache,memAvailable,sasDate,processVSZGO,processRSSGO,SIZE_IN_CACHE_GO" | tee -a $LOG_FILE
while [ 1=1 ]
do
  UnixDate=$(date +%s)
  FrenchDate=$(date '+%F %T');  
  nomServeur=$(hostname);
  
  CASLogFile=$(ls -lrt /var/log/sas/viya/cas/server02/ | grep cas_ | tail -1 | awk '{print $9}' )
 
  sommeCpu=0
  nbSasProcess=0
  i=0
  for process in $(ps -aux | grep -v root | grep "cas session" |  grep -v grep | awk '{print $1";"$2";"$3";"$4";"$5";"$6";"$8";"$9}'   )
  do
  
   processUser=$(echo $process | cut -d ";" -f 1)
   processPID=$(echo $process | cut -d ";" -f 2)
   processCPU=$(echo $process | cut -d ";" -f 3)
   processMEM=$(echo $process | cut -d ";" -f 4)
   processVSZ=$(echo $process | cut -d ";" -f 5)
   processRSS=$(echo $process | cut -d ";" -f 6)
   processStart=$(echo $process | cut -d ";" -f 7)
  
   
   processVSZGO=$(echo $processVSZ | awk '{printf("%13.2f",$1/1024/1024)}')  
   processRSSGO=$(echo $processRSS  | awk '{printf("%13.2f",$1/1024/1024)}')  
   
   
   sasUser=$(grep "Launched session" /var/log/sas/viya/cas/server02/$CASLogFile |  grep "Process ID is $processPID" | tail -1 | awk '{print $5}'  )
   
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
   echo $nomServeur","$UnixDate","$FrenchDate","$sasUser","$processPID","$processVSZ","$processRSS","$processUser","$NB_FILE_MAP","$SIZE_IN_CACHE","$memTotal","$memUsed","$memFree","$memShared","$memCache","$memAvailable","$sasDate","$processVSZGO","$processRSSGO","$SIZE_IN_CACHE_GO | tee -a $LOG_FILE
   
  chmod 777 $LOG_FILE
	
  done
  sleep 10
  
 done
