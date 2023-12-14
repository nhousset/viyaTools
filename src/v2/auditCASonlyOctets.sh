#!/bin/bash 


# nomServeur;FrenchDate;USER;CHECK_LSOF;SIZE_IN_CACHE_ALL;SIZE_IN_CACHE_ALL_DELETED;DIFF_CAS_MAP;DF_CACHE_USED;LOAD;CPU;processPID;processCPU;processMEM;processRSS;processVSZ;nbPidCasSession;CASRunning;timeCASRunning;sasAdminConnected;sasAdminConnectedPAM




export USER=$1
export CAS_DISK_CACHE_PATH=$2


export processPID=$3
export processCPU=$4
export processMEM=$5
export processRSS=$6
export processVSZ=$7

export CHECK_LSOF=$8

export nbPidCasSession=$9
export LOG_PATH=${10}


dateForLog=`date +%d-%m-%y`
export LOG_FILE=$LOG_PATH"/"$dateForLog"-auditCAS.csv";



  UnixDate=$(date +%s)
  FrenchDate=$(date '+%F %T');  
  nomServeur=$(hostname);
  
  DF_CACHE_SIZE=$(df | grep  $CAS_DISK_CACHE_PATH | awk '{print $2}')
  DF_CACHE_FREE=$(df | grep  $CAS_DISK_CACHE_PATH | awk '{print $4}')
  DF_CACHE_USED=$(df | grep  $CAS_DISK_CACHE_PATH | awk '{print $3}')
  
  
 
 
  SIZE_IN_CACHE_ALL=0
  SIZE_IN_CACHE_ALL_DELETED=0
  DIFF_CAS_MAP=0
  if [ "$CHECK_LSOF" == "1" ]
  then
  
    typeset -i SIZE_IN_CACHE_ALL=0
    for CASMAP in $(lsof $CAS_DISK_CACHE_PATH | grep -v OFF | grep $USER| awk '{print $7}'  )
    do
		SIZE_IN_CACHE_ALL=SIZE_IN_CACHE_ALL+CASMAP
	done
	typeset -i SIZE_IN_CACHE_ALL_DELETED=0
	for CASMAP in $(lsof $CAS_DISK_CACHE_PATH | grep -v OFF | grep $USER | grep deleted | awk '{print $7}')
	do
		SIZE_IN_CACHE_ALL_DELETED=SIZE_IN_CACHE_ALL_DELETED+$CASMAP
	done
	typeset -i DIFF_CAS_MAP 
	DIFF_CAS_MAP=${SIZE_IN_CACHE_ALL}-${SIZE_IN_CACHE_ALL_DELETED}
  fi

  LOAD=$(cat /proc/loadavg | awk '{print $1}' |  sed s/"\."/","/g)
  CPU=$(sar 1 1 | grep Average| awk '{print $3}' |  sed s/"\."/","/g)
  
 echo $nomServeur";"$FrenchDate";"$USER";"$CHECK_LSOF";"$SIZE_IN_CACHE_ALL";"$SIZE_IN_CACHE_ALL_DELETED";"$DIFF_CAS_MAP";"$DF_CACHE_USED";"$LOAD";"$CPU";"$processPID";"$processCPU";"$processMEM";"$processRSS";"$processVSZ";"$nbPidCasSession";0;0;0;0"  | tee -a $LOG_FILE



 
