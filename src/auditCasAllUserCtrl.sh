	#!/bin/bash


	RED='\033[031m'
	GREEN='\033[032m'
	YELLOW='\033[033m'
	BLUE='\033[034m'
	NC='\033[0m' 



	helpFunction()
	{
	   echo ""
	   echo -e "${YELLOW}Usage: $0 -s <sleep time> -o <output dir> -c <cas server> [ optional : -a <admin> ]${NC}"
	   echo "       $0 -s 10 -l \"/tmp\" -c default -a admin"
	   echo ""
	   echo -e "\t-s SLEEP_TIME"
	   echo -e "\t-o LOG_PATH"
	   echo -e "\t-c CAS_SERVER"
	   echo -e "\t-a ADMIN"
	   exit 1 # Exit script after printing help
	}

	_HOSTNAME="http://localhost"

	while getopts "s:o:c:a:" opt
	do
	   case "$opt" in
		  s ) SLEEP_TIME="$OPTARG" ;;
		  o ) LOG_PATH="$OPTARG" ;;
		  c ) CAS_SERVER="$OPTARG" ;;
		  a ) ADMIN="$OPTARG" ;;
		  ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
	   esac
	done

	# Begin script in case all parameters are correct

	if [ "$SLEEP_TIME" == "" ]
	then
		SLEEP_TIME=30
	fi

	if [ "$LOG_PATH" == "" ]
	then
		LOG_PATH="/tmp"
	fi

	if [ "$CAS_SERVER" == "" ]
	then
		CAS_SERVER="default"
	fi

	export SAS_CLI_DEFAULT_CAS_SERVER=cas-shared-$CAS_SERVER

	echo "Launch $0 with :"
	echo "SLEEP_TIME : "$SLEEP_TIME
	echo "LOG_PATH : "$LOG_PATH
	echo "CAS_SERVER : "$CAS_SERVER
	echo "SAS_CLI_DEFAULT_CAS_SERVER : "cas-shared-$CAS_SERVER
	echo "MODE : "$ADMIN
	echo ""
	echo "$0 -h for options"
	echo ""

	if [ "$ADMIN" == "admin" ] 
	then
		# /opt/sas/viya/home/bin/sas-admin profile set-endpoint http://xxxxxxxxxxxxxxxxxxxxxxxxxx
		# /opt/sas/viya/home/bin/sas-admin auth login --user xxxxxxxxxx

		CASRunning=$(/usr/bin/time -ao /tmp/showinfo.time -f "%E" /opt/sas/viya/home/bin/sas-admin cas servers show-info | grep -i state)
		if [ "$CASRunning" == "" ]
		then
			echo "Admin Mode - Please connect to viya ";
			echo "/opt/sas/viya/home/bin/sas-admin profile set-endpoint http://xxxxxxxxxxxxxxxxxxxxxxxxxx";
			echo "/opt/sas/viya/home/bin/sas-admin auth login --user xxxxxxxxxx";
			exit
		fi
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

		# CHARGE et CPU du worker

		LOAD=$(cat /proc/loadavg | awk '{print $1}' |  sed s/"\."/","/g)
		CPU=$(sar 1 1 | grep Average| awk '{print $3}' |  sed s/"\."/","/g)

		# On parcours l'ensemble des process CAS
		for process in $(ps -aux | grep -v root | grep "cas session"  |  grep -v grep | awk '{print $1";"$2";"$3";"$4";"$5";"$6";"$8";"$9";"$13}'  )
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

		# CAS GLOBAL
		process=$(ps -aux | grep -v root | grep "cas session" | grep -v grep | grep -v tkmpicas | awk '{print $1";"$2";"$3";"$4";"$5";"$6";"$8";"$9";"$13}'   )

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

		echo $nomServeur";"$FrenchDate";GLOBAL;"$CASSessionID";"$processPID";"$NB_FILE_CACHE";"$SIZE_IN_CACHE";"$LOAD";"$CPU";"$processPID";"$processCPU";"$processMEM";"$processRSS";"$processVSZ";"$nbPidCasSession";0;0;0;0"  | tee -a $LOG_FILE
	  
		SIZE_IN_CACHE_ALL=SIZE_IN_CACHE_ALL+`expr $NB_FILE_CACHE_ALL*128*1024*1024`

		if [ "$ADMIN" == "admin" ] 
		then
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
		fi
		echo $nomServeur";"$FrenchDate";ALL;ALL;"$NB_FILE_CACHE_ALL";"$SIZE_IN_CACHE_ALL";"$DF_CACHE_USED";"$LOAD";"$CPU";0;0;0;"$somme_RSS";"$somme_VSZ";"$nbPidCasSession";"$CASRunning";"$timeCASRunning";"$sasAdminConnected";"$sasAdminConnectedPAM | tee -a $LOG_FILE

		chmod 777 $LOG_FILE
	done

