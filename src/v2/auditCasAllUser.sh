#!/bin/bash 


# nomServeur;FrenchDate;USER;CHECK_LSOF;SIZE_IN_CACHE_ALL;SIZE_IN_CACHE_ALL_DELETED;DIFF_CAS_MAP;DF_CACHE_USED;LOAD;CPU;processPID;processCPU;processMEM;processRSS;processVSZ;nbPidCasSession;CASRunning;timeCASRunning;sasAdminConnected;sasAdminConnectedPAM






export SLEEP_TIME=$1
export CHECK_LSOF=$2
export LOG_PATH=$3
export CAS_DISK_CACHE_PATH=$4
export CAS_SERVER=$5

if [ "$SLEEP_TIME" == "" ]
then
	export SLEEP_TIME=30
fi

if [ "$CHECK_LSOF" == "" ]
then
	export CHECK_LSOF=0
fi

if [ "$LOG_PATH" == "" ]
then
	export LOG_PATH="/tmp"
fi

if [ "$CAS_DISK_CACHE_PATH" == "" ]
then
	export CAS_DISK_CACHE_PATH="/opt/sastmp/"
fi

if [ "$CAS_SERVER" == "" ]
then
	export CAS_SERVER="default"
fi


export SAS_CLI_DEFAULT_CAS_SERVER=cas-shared-$CAS_SERVER



# POC
# /opt/sas/viya/home/bin/sas-admin profile set-endpoint http://xxxxxxxxxxxxxxxxxxxxxxxxxx
# /opt/sas/viya/home/bin/sas-admin auth login --user xxxxxxxxxx 
CASRunning=$(/usr/bin/time -ao /tmp/showinfo.time -f "%E" /opt/sas/viya/home/bin/sas-admin cas servers show-info | grep State)
if [ "$CASRunning" == "" ]
then
	exit

fi

	



while [ 1=1 ]
do
	
	dateForLog=`date +%d-%m-%y`
	export LOG_FILE=$LOG_PATH"/"$dateForLog"-auditCAS.csv";
	if [ ! -e $LOG_FILE ]
	then
		echo $LOG_FILE" creation";
		echo "nomServeur;FrenchDate;USER;CHECK_LSOF;SIZE_IN_CACHE_ALL;SIZE_IN_CACHE_ALL_DELETED;DIFF_CAS_MAP;DF_CACHE_USED;LOAD;ALLCPU;pid;cpu;mem;rss;vsz;nbpidcassession;casrunning;timecasrunning;session;sessionpam"  > $LOG_FILE
	fi

	typeset -i somme_VSZ=0
	typeset -i somme_RSS=0
    nbPidCasSession=$(ps -aux | grep -v root | grep "cas session" |  grep -v grep |wc -l)
	
	for process in $(ps -aux | grep -v root | grep "cas session" |  grep -v grep | awk '{print $1";"$2";"$3";"$4";"$5";"$6";"$8";"$9}'   )
	do
	

		processUser=$(echo $process | cut -d ";" -f 1)
		processPID=$(echo $process | cut -d ";" -f 2)
		processCPU=$(echo $process | cut -d ";" -f 3 |  sed s/"\."/","/g)
		processMEM=$(echo $process | cut -d ";" -f 4 |  sed s/"\."/","/g)
		processVSZ=$(echo $process | cut -d ";" -f 5 |  sed s/"\."/","/g)
		processRSS=$(echo $process | cut -d ";" -f 6 |  sed s/"\."/","/g)
		
		somme_VSZ=somme_VSZ+$processVSZ
		somme_RSS=somme_RSS+$processRSS
		
		./auditCASonlyOctets.sh $processUser "$CAS_DISK_CACHE_PATH" $processPID $processCPU $processMEM $processRSS $processVSZ $CHECK_LSOF $nbPidCasSession "$LOG_PATH"
		
	done
	
	UnixDate=$(date +%s)
	FrenchDate=$(date '+%F %T');  
	nomServeur=$(hostname);

	
	# * DF du CACHE

	DF_CACHE_SIZE=$(df | grep  $CAS_DISK_CACHE_PATH | awk '{print $2}')
	DF_CACHE_FREE=$(df | grep  $CAS_DISK_CACHE_PATH | awk '{print $4}')
	DF_CACHE_USED=$(df | grep  $CAS_DISK_CACHE_PATH | awk '{print $3}')
	
	# CHARGE et CPU
	LOAD=$(cat /proc/loadavg | awk '{print $1}' |  sed s/"\."/","/g)
	CPU=$(sar 1 1 | grep Average| awk '{print $3}' |  sed s/"\."/","/g)
  
	CASRunning=$(/usr/bin/time -ao /tmp/showinfo.time -f "%E" /opt/sas/viya/home/bin/sas-admin cas servers show-info | grep State  | awk '{print $2}')	
	if [ "$CASRunning" == "running" ]
	then
		CASRunning=1
	else
		CASRunning=0
	fi
	timeCASRunning=$(tail -1 /tmp/showinfo.time |  cut -d ":" -f 2 |  sed s/"\."/","/g)

	sasAdminConnected=$(/opt/sas/viya/home/bin/sas-admin cas sessions list --superuser --all | grep "Connected" | wc -l)
	sasAdminConnectedPAM=$(/opt/sas/viya/home/bin/sas-admin cas sessions list --superuser --all | grep "Connected" | grep "PAM" | wc -l)
	
	echo $nomServeur";"$FrenchDate";ALL;"$CHECK_LSOF";0;0;0;"$DF_CACHE_USED";"$LOAD";"$CPU";0;0;0;"$somme_RSS";"$somme_VSZ";"$nbPidCasSession";"$CASRunning";"$timeCASRunning";"$sasAdminConnected";"$sasAdminConnectedPAM | tee -a $LOG_FILE
	
	chmod 777 $LOG_FILE
done

