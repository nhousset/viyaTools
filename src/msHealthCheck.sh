#!/bin/bash 

# *********************************************************
# *** Micro Service Health Check VIYA 3.5
# *** (c) Nicolas Housset
# *** https://www.nicolas-housset.fr
# ***
# *********************************************************


source /opt/sas/viya/config/consul.conf
export CONSUL_HTTP_TOKEN=$(cat /opt/sas/viya/config/etc/SASSecurityCertificateFramework/tokens/consul/default/client.token)
export SSL_CERT_FILE=/opt/sas/viya/config/etc/SASSecurityCertificateFramework/cacerts/trustedcerts.pem

RED='\033[031m'
GREEN='\033[032m'
YELLOW='\033[033m'
BLUE='\033[034m'
NC='\033[0m' 

_GLOBAL_PROFIL=ALL

for arg in "$@" ; do
  case "$arg" in
    --debug)
      _GLOBAL_DEBUG=1;; 
    --batch)
      _GLOBAL_BATCH=1;;
     --casctrl)
      _GLOBAL_PROFIL=CASCTRL;;
      --caswrk)
      _GLOBAL_PROFIL=CASWRK;; 
      --ms)
      _GLOBAL_PROFIL=MS;; 
      
  esac
done

if [ "${_GLOBAL_PROFIL}" == "ALL" ]
then
	_TITRE="Service Health Check VIYA 3.5"
fi
if [ "${_GLOBAL_PROFIL}" == "MS" ]
then
	_TITRE="MicroService Health Check VIYA 3.5"
fi
if [ "${_GLOBAL_PROFIL}" == "CASWRK" ]
then
	_TITRE="CAS Worker Check VIYA 3.5"
fi

echo -en "${BLUE}==================================================${NC}\n"
echo -en "${BLUE} ${_TITRE} ${NC}\n"
echo -en "${BLUE}==================================================${NC}\n"
echo ""                                                                                                                                                       

           
_GLOBAL_LOG_FILE=/tmp/SASmsHealthCheck_$$.log


if [ "${_GLOBAL_BATCH}" == "1" ]
then
	echo "msHealthCheck.sh s'execute en mode BATCH. L'output se fait dans le fichier $_GLOBAL_LOG_FILE"
	exec > $_GLOBAL_LOG_FILE 2>&1
fi

_GLOBAL_HTTPD_STATUS="KO"

_GLOBAL_CONSUL_STATUS="KO"
_GLOBAL_CONSUL_CONFIG="KO"

_GLOBAL_RABBITMQ_STATUS="KO"
_GLOBAL_RABBITMQ_CONFIG="KO"

_GLOBAL_VAULT_STATUS="KO"
_GLOBAL_NODE_STATUS="KO"
_GLOBAL_PGPOOL_STATUS="KO"


                                                                                                                                                                                                                                       
                             
echo -en  "${RED}Check system ${NC}\n"
echo -en  "${RED}==================================================${NC}\n"

echo -en  "${YELLOW}Hostname Info${NC}\n"
echo -en  "${BLUE}hostname -s${NC} : " 
hostname -s
echo -en  "\n"

echo -en  "${BLUE}hostname -f${NC} : "
hostname -f
echo -en  "\n"

echo -en  "${BLUE}hostname -A${NC} : "
hostname -A
echo -en  "\n"

echo -en  "${BLUE}hostnamectl${NC}\n"
hostnamectl
echo -en  "\n"

echo -en  "${YELLOW}CPU Info${NC} : "
cat /proc/cpuinfo | grep processor |  wc -l
echo ""

echo -en  "${YELLOW}Memory${NC}\n"
free -h

echo -en  "${YELLOW}Disk space${NC}\n"
df -h /opt/
df -h /var/log

echo -en  "${YELLOW}SELinux${NC}\n"
/sbin/sestatus | grep "Current mode"


echo -en  "${YELLOW}User'${NC}\n"
cat /etc/passwd | grep -E '^(cas|sas|viyassh|apache)';

echo -en  "\n"
echo -en  "${RED}Check process ${NC}\n"
echo -en  "${RED}==================================================${NC}\n"
echo -en  "${YELLOW}ps auxw | grep '/opt/sas/viya'${NC}\n"
ps auxw | grep '/opt/sas/viya'  | grep -v grep | wc -l
echo -en "\n"
echo -en  "${YELLOW}ps -u sas -f ${NC}\n"
ps -u sas -f  | grep -v grep | wc -l


echo -en  "${YELLOW}ps -u cas -f${NC}\n"
ps -u cas -f  | grep -v grep | wc -l

echo -en  "${YELLOW}sasrabbitmq${NC}\n"
ps -u sasrabbitmq -f   | grep -v grep | wc -l

echo -en  "${YELLOW}saspgpool${NC}\n"
ps -u saspgpool -f   | grep -v grep | wc -l

echo -en  "${YELLOW}**** sas-viya services *** ${NC}\n"
systemctl list-units | grep sas-viya
echo -en "\n"
echo -en  "${YELLOW}**** sas-viya services is enabled ?*** ${NC}\n"
systemctl list-unit-files | grep enabled | grep sas
echo -en "\n"


if [[ "${_GLOBAL_PROFIL}" == "ALL" || "${_GLOBAL_PROFIL}" == "MS"  ]]
then
	echo -en  "${YELLOW}Apache${NC}\n"                                         
	netstat -tupln | grep :80
	netstat -tupln | grep :443


	if [[ $(curl --insecure  --location -s -o /dev/null -w  "%{http_code}" http://localhost) == 200 ]]
	then
		_GLOBAL_HTTPD_STATUS="OK"
	else
    		if [[ $(curl --insecure  --location -s -o /dev/null -w  "%{http_code}" http://localhost) == 401 ]]
    		then
		  	_GLOBAL_HTTPD_STATUS="OK"
    		else
       			if [[ $(curl --insecure  --location -s -o /dev/null -w  "%{http_code}" http://localhost ) == 403 ]]
    			then
			  	_GLOBAL_HTTPD_STATUS="OK"
		    	fi
    		fi
	fi
fi

echo -en  "\n"
echo -en  "${RED}Check Viya ${NC}\n"
echo -en  "${RED}==================================================${NC}\n"

echo -en  "${YELLOW}sas-ops env${NC}\n"
/opt/sas/viya/home/bin/sas-ops env

echo -en  "${YELLOW}sas-ops info${NC}\n"
/opt/sas/viya/home/bin/sas-ops info

if [[ "${_GLOBAL_PROFIL}" == "ALL" || "${_GLOBAL_PROFIL}" == "MS"  ]]
then
	echo ""
	echo -en "${RED}******************************************${NC}\n"   
	echo -en "${RED}*** SASSecurityCertificateFramework ${NC}\n"                                      
	echo -en "${RED}******************************************${NC}\n"   
	echo ""
	ls -lrt /opt/sas/viya/config/etc/SASSecurityCertificateFramework/tls/certs/sasdatasvrc/postgres/pgpool0/sascert.pem
	ls -lrt /opt/sas/viya/config/etc/SASSecurityCertificateFramework/private/sasdatasvrc/postgres/pgpool0/saskey.pem
	ls -lrt /opt/sas/viya/config/etc/SASSecurityCertificateFramework/tls/certs/sasdatasvrc/postgres/pgpool0/sascert.pem
	ls -lrt /opt/sas/viya/config/etc/SASSecurityCertificateFramework/cacerts/trustedcerts.pem
fi

echo ""
echo -en "${RED}************************${NC}\n"   
echo -en "${RED}*** CONSUL${NC}\n"                                      
echo -en "${RED}************************${NC}\n"   
echo ""
echo -en  "${YELLOW}netstat${NC}\n"                                         
netstat -tupln | grep :8501


echo -en  "${YELLOW}status${NC}\n"     
/opt/sas/viya/home/bin/sas-csq consul-status
statusRun=$(/opt/sas/viya/home/bin/sas-csq consul-status | grep "leader")
if [ "$statusRun" != "" ]
then
  _GLOBAL_CONSUL_STATUS="OK"
fi

echo -en  "${YELLOW}Agents${NC}\n"     
curl -vk --header "X-Consul-Token:$CONSUL_HTTP_TOKEN"  https://localhost:8501/v1/agent/members

if [[ "${_GLOBAL_PROFIL}" == "ALL" || "${_GLOBAL_PROFIL}" == "MS"  ]]
then
	echo -en  "${RED} Check SASlogon,Compute/StudioV and ModelStudio in Consul ${NC}\n"
	echo -en  "${YELLOW}saslogon${NC}\n"
	echo
	curl -k --header "X-Consul-Token:$CONSUL_HTTP_TOKEN" --request GET -n https://localhost:8501/v1/catalog/service/saslogon
	echo
	echo -en  "${YELLOW}compute${NC}\n"
	curl -k --header "X-Consul-Token:$CONSUL_HTTP_TOKEN" --request GET -n https://localhost:8501/v1/catalog/service/compute
	echo
	echo -en  "${YELLOW}Compute/StudioV ${NC}\n"
	curl -k --header "X-Consul-Token:$CONSUL_HTTP_TOKEN" --request GET -n https://localhost:8501/v1/catalog/service/modelstudio
	echo 
	curl -k --header "X-Consul-Token:$CONSUL_HTTP_TOKEN" --request GET -n https://localhost:8501/v1/catalog/service/sasstudioV
	echo
 
	echo ""
	echo -en "${RED}************************${NC}\n"   
	echo -en "${RED}*** RabbitMQ${NC}\n"                                      
	echo -en "${RED}************************${NC}\n"   
	echo ""


	echo -en  "${YELLOW}.erlang.cookie ${NC}\n"   

	erlang=$(ls -lrt /opt/sas/viya/config/var/lib/rabbitmq-server/sasrabbitmq/.erlang.cookie | grep "r--------")
	if [ "$erlang" != "" ]
	then
  	echo -en $(ls -lrt /opt/sas/viya/config/var/lib/rabbitmq-server/sasrabbitmq/.erlang.cookie)" : " "${GREEN}OK${NC}\n"   
  	_GLOBAL_RABBITMQ_CONFIG="OK"
	else
  	echo -en $(ls -lrt /opt/sas/viya/config/var/lib/rabbitmq-server/sasrabbitmq/.erlang.cookie)" : " "${RED}KO${NC}\n"   
  	_GLOBAL_RABBITMQ_CONFIG="KO"
	fi

	echo -en  "${YELLOW}rabbitMQ status ${NC}\n"
	/etc/init.d/sas-viya-rabbitmq-server-default status 

	statusRun=$(/etc/init.d/sas-viya-rabbitmq-server-default status | grep "service is running")
	if [ "$statusRun" != "" ]
	then
  	_GLOBAL_RABBITMQ_STATUS="OK"
	fi

	echo -en  "${YELLOW}rabbitMQ Health Check ${NC}\n"
	/opt/sas/viya/home/sbin/rabbitmqctl node_health_check

	echo ""
	echo -en "${RED}************************${NC}\n"   
	echo -en "${RED}*** VAULT${NC}\n"                                      
	echo -en "${RED}************************${NC}\n"   
	echo ""

	echo -en  "${YELLOW}Vault version ${NC} : "
	/opt/sas/viya/home/bin/vault version
	echo -en "\n"                              

	echo -en  "${YELLOW}Vault status ${NC}\n"
	/opt/sas/viya/home/bin/vault status
	statusRun=$(/etc/init.d/sas-viya-sasdatasvrc-postgres-pgpool0 status | grep "is running with PID")

	echo -en  "${YELLOW}Vault Server Configuration${NC}\n"

	cat /opt/sas/viya/config/etc/vault/default/vault.hcl

	echo -en  "${YELLOW}Vault test ${NC}\n"
	VaultTestWebVaumt=$(curl -k -K- https://localhost:8200/v1/viya_inter/roles/test_web_server <<< "header=\"X-Vault-Token: $(sudo cat /opt/sas/viya/config/etc/SASSecurityCertificateFramework/tokens/consul/default/vault.token)\"" | grep warnings)

	if [ "$VaultTestWebVaumt" != "" ]
	then
  	_GLOBAL_VAULT_STATUS="OK"
	fi

	echo -en  "${YELLOW}Vault ssl test ${NC}\n"
	openssl s_client -connect localhost:8200 -prexit -CAfile /opt/sas/viya/config/etc/SASSecurityCertificateFramework/cacerts/trustedcerts.pem -showcerts

	echo ""
	echo -en "${RED}************************${NC}\n"   
	echo -en "${RED}*** SASDatasvrc${NC}\n"                                      
	echo -en "${RED}************************${NC}\n"   
	echo ""
	echo -en  "${YELLOW}SASDatasvrc status${NC}\n"

	/etc/init.d/sas-viya-sasdatasvrc-postgres-node0 status
	statusRun=$(/etc/init.d/sas-viya-sasdatasvrc-postgres-node0 status | grep "is running with PID")
	if [ "$statusRun" != "" ]
	then
	  _GLOBAL_NODE_STATUS="OK"
	fi

	/etc/init.d/sas-viya-sasdatasvrc-postgres-pgpool0 status
	statusRun=$(/etc/init.d/sas-viya-sasdatasvrc-postgres-pgpool0 status | grep "is running with PID")
	if [ "$statusRun" != "" ]
	then
  	_GLOBAL_PGPOOL_STATUS="OK"
	fi

	echo -en  "${YELLOW}Postgres Consul status${NC}\n"
	echo -en  "${NC}node0 : node_status${NC}\n"
	/opt/sas/viya/home/bin/sas-bootstrap-config kv read "config/postgres/admin/node0/node_status"

	echo -en  "${NC}node0 : operation_status${NC}\n"
	/opt/sas/viya/home/bin/sas-bootstrap-config kv read "config/postgres/admin/node0/operation_status"

	echo -en  "${NC}pgpool0 : node_status${NC}\n"
	/opt/sas/viya/home/bin/sas-bootstrap-config kv read "config/postgres/admin/pgpool0/node_status"

	echo -en  "${NC}pgpool0 : operation_status${NC}\n"
	/opt/sas/viya/home/bin/sas-bootstrap-config kv read "config/postgres/admin/pgpool0/operation_status"

	echo -en  "${YELLOW}Audit${NC}\n"
	ls -la /opt/sas/viya/config/var/cache/auditcli

	echo -en  "${YELLOW}Web App${NC}\n"
	echo -en  "${NC}SASDrive : "
	if [[ $(curl --insecure  --location -s -o /dev/null -w  "%{http_code}" https://localhost/SASDrive/) == 200 ]]
	then
		SASDrive="OK"
	else
    	if [[ $(curl --insecure  --location -s -o /dev/null -w  "%{http_code}" https://localhost/SASDrive/) == 401 ]]
    	then
		  	SASDrive="OK"
    	else
       		if [[ $(curl --insecure  --location -s -o /dev/null -w  "%{http_code}" https://localhost/SASDrive/ ) == 403 ]]
    		then
	  		SASDrive="OK"
    		fi
    	fi
	fi
	echo -en  $SASDrive"\n"

fi

echo ""
echo -en "${RED}************************${NC}\n"   
echo -en "${RED}*** Other check${NC}\n"                                      
echo -en "${RED}************************${NC}\n"   
echo ""
echo -en  "${YELLOW}Check disabled services${NC}\n"
cat /opt/sas/viya/config/etc/viya-svc-mgr/svc-ignore | grep -v '#'
echo ""

echo -en  "${YELLOW}sas-ops validate${NC}\n"
/opt/sas/viya/home/bin/sas-ops validate --level 3 --verbose

echo -en  "${YELLOW}sas-ops validate${NC}\n"
/opt/sas/viya/home/bin/sas-ops validate --level 3 --verbose

if [[ "${_GLOBAL_PROFIL}" == "ALL" || "${_GLOBAL_PROFIL}" == "MS"  ]]
then
	echo -en  "${YELLOW}SASFoundation Sticky bit${NC}\n"
	sasperm=$(ls -lrt /opt/sas/viya/home/SASFoundation/utilities/bin/sasperm | grep "rwsr-xr-x")
	if [ "$sasperm" != "" ]
	then
  	echo -en $(ls -lrt /opt/sas/viya/home/SASFoundation/utilities/bin/sasperm)" : " "${GREEN}OK${NC}\n"   
	else
  	echo -en $(ls -lrt /opt/sas/viya/home/SASFoundation/utilities/bin/sasperm)" : " "${RED}KO${NC}\n"   
	fi


	sasauth=$(ls -lrt /opt/sas/viya/home/SASFoundation/utilities/bin/sasauth | grep "rwsr-xr-x")
	if [ "$sasauth" != "" ]
	then
  	echo -en $(ls -lrt /opt/sas/viya/home/SASFoundation/utilities/bin/sasauth)" : " "${GREEN}OK${NC}\n"   
	else
  	echo -en $(ls -lrt /opt/sas/viya/home/SASFoundation/utilities/bin/sasauth)" : " "${RED}KO${NC}\n"   
	fi
	
	elssrv=$(ls -lrt /opt/sas/viya/home/SASFoundation/utilities/bin/elssrv | grep "rwsr-xr-x")
	if [ "$elssrv" != "" ]
	then	
	  	echo -en $(ls -lrt /opt/sas/viya/home/SASFoundation/utilities/bin/elssrv)" : " "${GREEN}OK${NC}\n"   
	else
	  	echo -en $(ls -lrt /opt/sas/viya/home/SASFoundation/utilities/bin/elssrv)" : " "${RED}KO${NC}\n"   
	fi
fi

	caslaunch=$(ls -lrt /opt/sas/viya/home/SASFoundation/utilities/bin/caslaunch | grep "rwsr-xr-x")
	if [ "$caslaunch" != "" ]
	then
  		echo -en $(ls -lrt /opt/sas/viya/home/SASFoundation/utilities/bin/caslaunch)" : " "${GREEN}OK${NC}\n"   
	else
  	echo -en $(ls -lrt /opt/sas/viya/home/SASFoundation/utilities/bin/caslaunch)" : " "${RED}KO${NC}\n"   
	fi

	echo -en  "${YELLOW}SASFoundation SPRE Sticky bit${NC} https://support.sas.com/kb/15/231.html \n"
	sasperm=$(ls -lrt /opt/sas/spre/home/SASFoundation/utilities/bin/sasperm | grep "rwsr-xr-x")
	if [ "$sasperm" != "" ]
	then	
  		echo -en $(ls -lrt /opt/sas/spre/home/SASFoundation/utilities/bin/sasperm)" : " "${GREEN}OK${NC}\n"   
	else
  		echo -en $(ls -lrt /opt/sas/spre/home/SASFoundation/utilities/bin/sasperm)" : " "${RED}KO${NC}\n"   
	fi


	sasauth=$(ls -lrt /opt/sas/spre/home/SASFoundation/utilities/bin/sasauth | grep "rwsr-xr-x")
	if [ "$sasauth" != "" ]
	then
  		echo -en $(ls -lrt /opt/sas/spre/home/SASFoundation/utilities/bin/sasauth)" : " "${GREEN}OK${NC}\n"   
	else
  		echo -en $(ls -lrt /opt/sas/spre/home/SASFoundation/utilities/bin/sasauth)" : " "${RED}KO${NC}\n"   
	fi

	elssrv=$(ls -lrt /opt/sas/spre/home/SASFoundation/utilities/bin/elssrv | grep "rwsr-xr-x")
	if [ "$elssrv" != "" ]
	then
  		echo -en $(ls -lrt /opt/sas/spre/home/SASFoundation/utilities/bin/elssrv)" : " "${GREEN}OK${NC}\n"   
	else
  		echo -en $(ls -lrt /opt/sas/spre/home/SASFoundation/utilities/bin/elssrv)" : " "${RED}KO${NC}\n"   
	fi



echo ""
echo -en "${RED}************************${NC}\n"   
echo -en "${RED}*** GLOBAL HEALTH-CHECK${NC}\n"                                      
echo -en "${RED}************************${NC}\n"   
echo ""



if [ "$_GLOBAL_HTTPD_STATUS" == "OK" ]
then
  echo -en "httpd : ${GREEN}OK${NC}\n"
else
   echo -en "httpd : ${RED}KO${NC}\n"
fi

if [ "$_GLOBAL_CONSUL_STATUS" == "OK" ]
then
  echo -en "Consul : ${GREEN}OK${NC}\n"
else
   echo -en "Consul : ${RED}KO${NC}\n"
fi

if [ "$_GLOBAL_VAULT_STATUS" == "OK" ]
then
  echo -en "Vault : ${GREEN}OK${NC}\n"
else
   echo -en "Vault : ${RED}KO${NC}\n"
fi



if [ "$_GLOBAL_RABBITMQ_CONFIG" == "OK" ]
then
  echo -en "RabbitMQ config : ${GREEN}OK${NC}\n"
else
   echo -en "RabbitMQ config : ${RED}KO${NC}\n"
fi

if [ "$_GLOBAL_RABBITMQ_STATUS" == "OK" ]
then
  echo -en "RabbitMQ process : ${GREEN}OK${NC}\n"
else
   echo -en "RabbitMQ process : ${RED}KO${NC}\n"
fi



if [ "$_GLOBAL_NODE_STATUS" == "OK" ]
then
  echo -en "sasdatasvrc-postgres-node0 : ${GREEN}OK${NC}\n"
else
   echo -en "sasdatasvrc-postgres-node0 : ${RED}KO${NC}\n"
fi

if [ "$_GLOBAL_PGPOOL_STATUS" == "OK" ]
then
  echo -en "sasdatasvrc-postgres-pgpool0 : ${GREEN}OK${NC}\n"
else
   echo -en "sasdatasvrc-postgres-pgpool0 : ${RED}KO${NC}\n"
fi



