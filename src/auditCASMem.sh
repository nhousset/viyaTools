#!/bin/bash 

export CAS_DISK_CACHE_PATH="/opt/sastmp"
export LOG_FILE="/tmp/auditCASMem.csv";
export LOG_FILE_LIGHT="/tmp/auditCASMemLight.csv";
echo "nomServeur;UnixDate;FrenchDate;sasDate;NB_FILE_MAP;NB_SESSION_ACTIF_CACHE;NB_SESSION_LSOF_CACHE;TOTAL_MEMOIRE_PROCESS_CAS_ACTIF;TOTAL_MEMOIRE_PROCESS_CAS_LSOF;SIZE_IN_CACHE;memTotal;memUsed;memFree;memShared;memCache;memAvailable;SIZE_IN_CACHE_GO;DF_CACHE_SIZE;DF_CACHE_FREE;DF_CACHE_USED;SIZE_IN_CACHE_ALL;SIZE_IN_CACHE_ALL_DELETED;CPU;LOAD;SOMME_CAS_CPU;iostatUser;iostatSystem;iostatIowait;iostatIdle" | tee -a $LOG_FILE
echo "nomServeur;FrenchDate;NB_FILE_MAP;memUsed;memFree;memShared;memCache;memAvailable;DF_CACHE_SIZE;DF_CACHE_FREE;DF_CACHE_USED;SIZE_IN_CACHE_ALL;SIZE_IN_CACHE_ALL_DELETED" | tee -a $LOG_FILE_LIGHT
 
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
   
  DF_CACHE_SIZE=$(df -h | grep  $CAS_DISK_CACHE_PATH | awk '{print $2}' | sed s/"G"/""/g)
  DF_CACHE_FREE=$(df -h | grep  $CAS_DISK_CACHE_PATH | awk '{print $4}' | sed s/"G"/""/g)
  DF_CACHE_USED=$(df -h | grep  $CAS_DISK_CACHE_PATH | awk '{print $3}' | sed s/"G"/""/g)
  
  NB_FILE_MAP=$(lsof -s -u cas| grep $CAS_DISK_CACHE_PATH |wc -l) # actif
 # typeset -i SIZE_IN_CACHE=0
#  SIZE_IN_CACHE=`expr $NB_FILE_MAP*8*1024*1024`
  #SIZE_IN_CACHE_GO=$(echo $SIZE_IN_CACHE | awk '{printf("%13.2f",$1/1024/1024/1024)}')  
   
  NB_SESSION_ACTIF_CACHE=$(lsof -s -u cas | grep $CAS_DISK_CACHE_PATH | awk '{print $2}' | uniq | wc -l) 
 typeset -i TOTAL_MEMOIRE_PROCESS_CAS=0
 for pid in $(lsof -s -u cas | grep $CAS_DISK_CACHE_PATH | awk '{print $2}' | uniq )
    do
        # memoire utilise par le process
        let -i MEM_PID=0
        MEM_PID=$(top -p $pid -bn 1| grep $pid |  awk '{print $6}')
        if [ $(echo $MEM_PID | grep -c "g" ) -gt 0 ]
        then
           MEM_PID=$(echo $MEM_PID | sed s/"g"/""/g)
           MEM_PID=$(echo $MEM_PID*1024*1024 | bc -l )
        fi 
        MEM_PID=$(echo $MEM_PID | awk '{printf("%13.0f",$1)}')
        TOTAL_MEMOIRE_PROCESS_CAS=TOTAL_MEMOIRE_PROCESS_CAS+MEM_PID

      

    done 
	
	typeset -i SIZE_IN_CACHE_ALL=0
	for CASMAP in $(lsof $CAS_DISK_CACHE_PATH | grep -v OFF | awk '{print $7}')
    do
		SIZE_IN_CACHE_ALL=SIZE_IN_CACHE_ALL+CASMAP
	done
	SIZE_IN_CACHE_GO=$(echo $SIZE_IN_CACHE_ALL | awk '{printf("%13.2f",$1/1024/1024/1024)}')  
	SIZE_IN_CACHE=$SIZE_IN_CACHE_ALL
	
	typeset -i SIZE_IN_CACHE_ALL_DELETED=0
	for CASMAP in $(lsof $CAS_DISK_CACHE_PATH | grep -v OFF | grep deleted | awk '{print $7}')
    do

		SIZE_IN_CACHE_ALL_DELETED=SIZE_IN_CACHE_ALL_DELETED+CASMAP
	done
	
	
	
	NB_FILE_MAP_ALL_DELETED=$(lsof $CAS_DISK_CACHE_PATH | grep deleted | wc -l) # actif
	#typeset -i SIZE_IN_CACHE_ALL_DELETED=0
    #SIZE_IN_CACHE_ALL_DELETED=`expr $NB_FILE_MAP_ALL_DELETED*8*1024*1024`
 	
 NB_SESSION_LSOF_CACHE=$(lsof $CAS_DISK_CACHE_PATH | awk '{print $2}' | uniq | wc -l) 
 typeset -i TOTAL_MEMOIRE_PROCESS_CAS_LSOF=0
 for pid in $(lsof $CAS_DISK_CACHE_PATH | awk '{print $2}' | grep -v PID | uniq )
    do
        # memoire utilise par le process
        let -i MEM_PID=0
        MEM_PID=$(top -p $pid -bn 1| grep $pid |  awk '{print $6}')
        if [ $(echo $MEM_PID | grep -c "g" ) -gt 0 ]
        then
           MEM_PID=$(echo $MEM_PID | sed s/"g"/""/g)
           MEM_PID=$(echo $MEM_PID*1024*1024 | bc -l )
        fi 
        MEM_PID=$(echo $MEM_PID | awk '{printf("%13.0f",$1)}')
        TOTAL_MEMOIRE_PROCESS_CAS_LSOF=TOTAL_MEMOIRE_PROCESS_CAS_LSOF+MEM_PID

      

    done 

	
	typeset -i SOMME_CAS_CPU=0
	for CAS_CPU in $(ps aux | grep "bin/cas" | grep -v grep | sort -nrk 3,3 | awk '{print $3}')
	do
	 CAS_CPU=$(echo $CAS_CPU | awk '{printf("%13.0f",$1)}')
	SOMME_CAS_CPU=$(echo $SOMME_CAS_CPU+$CAS_CPU| bc -l )
		
	done

	iostatUser=$( iostat | head -4 | tail -1 |  awk '{print $1}');
	iostatSystem=$( iostat | head -4 | tail -1 |  awk '{print $3}');
	iostatIowait=$( iostat | head -4 | tail -1 |  awk '{print $4}');
	iostatIdle=$( iostat | head -4 | tail -1 |  awk '{print $6}');
	

	
	CPU=$(sar 1 1 | grep Average| awk '{print $3}')

	LOAD=$(cat /proc/loadavg| awk '{print $1}')

	

  
	CASLogFile=$(ls -lrt /var/log/sas/viya/cas/server02/ | grep cas_ | tail -1 | awk '{print $9}' )
	echo "" > /tmp/auditCASMemSession.tmp
    typeset -i NB_CAS_SESSION=0
	for process in $(ps -aux | grep -v root | grep "cas session"  |  grep -v grep  | awk '{print $2}' )
    do
		
		processPID=$(echo $process | cut -d ";" -f 2)
		sasUser=$(grep "Launched session" /var/log/sas/viya/cas/server02/$CASLogFile |  grep "Process ID is $processPID" | tail -1 | awk '{print $5}'  )
		echo $sasUser >> /tmp/auditCASMemSession.tmp
		NB_CAS_SESSION=`expr $NB_CAS_SESSION+1`
  
  done
 
 
  NB_CAS_SESSION_UNIQUE=$(cat /tmp/auditCASMemSession.tmp | uniq | wc -l)

  
  typeset -i sasDate=0
     
  sasDate=`expr $UnixDate-315360000`

  echo $nomServeur";"$UnixDate";"$FrenchDate";"$sasDate";"$NB_FILE_MAP";"$NB_SESSION_ACTIF_CACHE";"$NB_SESSION_LSOF_CACHE";"$TOTAL_MEMOIRE_PROCESS_CAS";"$TOTAL_MEMOIRE_PROCESS_CAS_LSOF";"$SIZE_IN_CACHE";"$memTotal";"$memUsed";"$memFree";"$memShared";"$memCache";"$memAvailable";"$SIZE_IN_CACHE_GO";"$DF_CACHE_SIZE";"$DF_CACHE_FREE";"$DF_CACHE_USED";"$SIZE_IN_CACHE_ALL";"$SIZE_IN_CACHE_ALL_DELETED";"$CPU";"$LOAD";"$SOMME_CAS_CPU";"$iostatUser";"$iostatSystem";"$iostatIowait";"$iostatIdle";"$NB_CAS_SESSION";"$NB_CAS_SESSION_UNIQUE  | tee -a $LOG_FILE
   
  chmod 777 $LOG_FILE
  
  SIZE_IN_CACHE_ALL_GO=$(echo $SIZE_IN_CACHE_ALL | awk '{printf("%13.2f",$1/1024/1024/1024)}')  
  SIZE_IN_CACHE_ALL_DELETED_GO=$(echo $SIZE_IN_CACHE_ALL_DELETED | awk '{printf("%13.2f",$1/1024/1024/1024)}')  
  echo $nomServeur";"$FrenchDate";"$NB_FILE_MAP";"$memUsed";"$memFree";"$memShared";"$memCache";"$memAvailable";"$DF_CACHE_SIZE";"$DF_CACHE_FREE";"$DF_CACHE_USED";"$SIZE_IN_CACHE_ALL_GO";"$SIZE_IN_CACHE_ALL_DELETED_GO | tee -a $LOG_FILE_LIGHT
  
  chmod 777 $LOG_FILE_LIGHT
  
  sleep 10
  
done
 
