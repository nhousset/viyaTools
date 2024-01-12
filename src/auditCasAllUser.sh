#!/bin/bash

export SLEEP_TIME=$1
export LOG_PATH=$2
export CAS_SERVER=$3

if [ "$SLEEP_TIME" == "" ]
then
export SLEEP_TIME=30
fi


if [ "$LOG_PATH" == "" ]
then
export LOG_PATH="/tmp"
fi

if [ "$CAS_DISK_CACHE_PATH" == "" ]
then
export CAS_DISK_CACHE_PATH="/opt/sastmp/"
fi


export SAS_CLI_DEFAULT_CAS_SERVER=cas-shared-$CAS_SERVER


# /opt/sas/viya/home/bin/sas-admin profile set-endpoint http://xxxxxxxxxxxxxxxxxxxxxxxxxx
# /opt/sas/viya/home/bin/sas-admin auth login --user xxxxxxxxxx

CASRunning=$(/usr/bin/time -ao /tmp/showinfo.time -f "%E" /opt/sas/viya/home/bin/sas-admin cas servers show-info | grep -i state)
if [ "$CASRunning" == "" ]
then
echo "Please connect";
exit
fi

while [ 1=1 ]
do

	UnixDate=$(date +%s)
	FrenchDate=$(date '+%F %T');
	nomServeur=$(hostname);
	
	dateForLog=`date +%d-%m-%y`
	export LOG_FILE=$LOG_PATH"/"$dateForLog"-auditCAS.csv";
	if [ ! -e $LOG_FILE ]
	then
		echo $LOG_FILE" creation";
		echo "nomServeur;FrenchDate;processUser;CASSessionID;NB_FILE_CACHE;SIZE_IN_CACHE;$DF_CACHE_USED;LOAD;CPU;processPID;processCPU;processMEM;processRSS;ProcessVSZ;nbPidCasSession;CASRunning;timeCASRunning;sasAdminConnected;sasAdminConnectedPAM"  > $LOG_FILE
	fi
 
	typeset -i somme_VSZ=0
	typeset -i somme_RSS=0
	typeset -i NB_FILE_CACHE_ALL=0
	typeset -i SIZE_IN_CACHE_ALL=0

	nbPidCasSession=$(ps -aux | grep -v root | grep "cas session" |  grep -v grep |wc -l)

  	# DF du CACHE
  	#DF_CACHE_USED=$(df | grep  $CAS_DISK_CACHE_PATH | awk '{print $3}')

  	# CHARGE et CPU du worker

  	LOAD=$(cat /proc/loadavg | awk '{print $1}' |  sed s/"\."/","/g)
  	CPU=$(sar 1 1 | grep Average| awk '{print $3}' |  sed s/"\."/","/g)

  	# On parcours l'ensemble des process CAS
  	for process in $(ps -aux | grep -v root | grep "cas session" | awk '{print $1";"$2";"$3";"$4";"$5";"$6";"$8";"$9";"$13}'  |  grep -v grep )
  	do
	
  		processUser=$(echo $process | cut -d ";" -f 1)
  		processPID=$(echo $process | cut -d ";" -f 2)
  		processCPU=$(echo $process | cut -d ";" -f 3 |  sed s/"\."/","/g)
  		processMEM=$(echo $process | cut -d ";" -f 4 |  sed s/"\."/","/g)
  		processVSZ=$(echo $process | cut -d ";" -f 5 |  sed s/"\."/","/g)
		processRSS=$(echo $process | cut -d ";" -f 6 |  sed s/"\."/","/g)
  		CASSessionID=$(echo $process | cut -d ";" -f 9)

  		somme_VSZ=somme_VSZ+$processVSZ
  		somme_RSS=somme_RSS+$processRSS

  		NB_FILE_CACHE=$(ls -lrt /proc/${processPID}/fd | grep casmap | wc -l)
  		NB_FILE_CACHE_ALL=NB_FILE_CACHE_ALL+$NB_FILE_CACHE

  		typeset -i SIZE_IN_CACHE=0
  		SIZE_IN_CACHE=`expr $NB_FILE_CACHE*128*1024*1024`


  		LOAD=$(cat /proc/loadavg | awk '{print $1}' |  sed s/"\."/","/g)
  		CPU=$(sar 1 1 | grep Average| awk '{print $3}' |  sed s/"\."/","/g)

  		CASLogFile=$(ls -lrt /var/log/sas/viya/cas/${CAS_SERVER}/ | grep cas_ | tail -1 | awk '{print $9}' )
  		sasUser=$(grep "Launched session" /var/log/sas/viya/cas/${CAS_SERVER}/$CASLogFile |  grep "Process ID is $processPID" | tail -1 | awk '{print $5}'  )
  		echo $nomServeur";"$FrenchDate";"$sasUser";"$CASSessionID";"$processPID";"$NB_FILE_CACHE";"$SIZE_IN_CACHE";"$LOAD";"$CPU";"$processPID";"$processCPU";"$processMEM";"$processRSS";"$processVSZ";"$nbPidCasSession";0;0;0;0"  | tee -a $LOG_FILE

  	done

  	SIZE_IN_CACHE_ALL=SIZE_IN_CACHE_ALL+`expr $NB_FILE_CACHE_ALL*128*1024*1024`

  	# check via sas-admin du temps de reponse de CAS
  	CASRunning=$(/usr/bin/time -ao /tmp/showinfo.time -f "%E" /opt/sas/viya/home/bin/sas-admin cas servers show-info | grep State  | awk '{print $2}')
  	if [ "$CASRunning" == "running" ]
  	then
  		CASRunning=1
  	else
  		CASRunning=0
  	fi
  	timeCASRunning=$(tail -1 /tmp/showinfo.time |  cut -d ":" -f 2 |  sed s/"\."/","/g)

  	# Nombre d'utilisateur connecté
  	sasAdminConnected=$(/opt/sas/viya/home/bin/sas-admin cas sessions list --superuser --all | grep "Connected" | wc -l)

  	# Nombre d'utilisateur connecté via PAM
  	sasAdminConnectedPAM=$(/opt/sas/viya/home/bin/sas-admin cas sessions list --superuser --all | grep "Connected" | grep "PAM" | wc -l)

   	echo $nomServeur";"$FrenchDate";ALL;ALL;"$NB_FILE_CACHE_ALL";"$SIZE_IN_CACHE_ALL";"$DF_CACHE_USED";"$LOAD";"$CPU";0;0;0;"$somme_RSS";"$somme_VSZ";"$nbPidCasSession";"$CASRunning";"$timeCASRunning";"$sasAdminConnected";"$sasAdminConnectedPAM | tee -a $LOG_FILE

  	chmod 777 $LOG_FILE
done

