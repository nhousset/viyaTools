#!/bin/bash 

# *********************************************************
# *** Health Check VIYA 3.5
# *** (c) Nicolas Housset
# *** https://www.nicolas-housset.fr
# ***
# *** Source : https://support.sas.com/kb/69/131.html
# *********************************************************

#  export ANSIBLE_KEEP_REMOTE_FILES=1
# ansible.cfg


export casID="default"

source /opt/sas/viya/config/consul.conf
export CONSUL_HTTP_TOKEN=$(cat /opt/sas/viya/config/etc/SASSecurityCertificateFramework/tokens/consul/default/client.token)
export SSL_CERT_FILE=/opt/sas/viya/config/etc/SASSecurityCertificateFramework/cacerts/trustedcerts.pem



RED='\033[031m'
GREEN='\033[032m'
YELLOW='\033[033m'
BLUE='\033[034m'
NC='\033[0m' 

_GLOBAL_PROFIL=ALL
_GLOBAL_FULL=0
_GLOBAL_CHECKUPDATE=0

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
      --full)
      _GLOBAL_FULL=1;;
      --checkupdate)
      _GLOBAL_CHECKUPDATE=1;;
      
  esac
done

read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

if [ "${_GLOBAL_CHECKUPDATE}" == "1" ]
then
	echo -en "${BLUE}==================================================${NC}\n"
	echo -en "${BLUE} Check before update ${NC}\n"
	echo -en "${BLUE}==================================================${NC}\n"
	echo ""    
	echo -en  "${YELLOW}SAS repo${NC}\n"
	ls -lrt /etc/yum.repos.d/sas*
	echo ""
	echo -en  "${YELLOW}check update${NC}\n"
	yum check-update "sas-*" | grep yum
	echo ""
	echo -en  "${YELLOW}rpm list to /tmp/viya_rpms.txt${NC}\n"
	rpm -qg SAS | tee -a /tmp/viya_rpms.txt
	echo ""
	echo -en  "${YELLOW}rpm group to /tmp/viya_yumgroups.txt${NC}\n"
	yum grouplist "SAS*" | tee -a /tmp/viya_yumgroups.txt
	exit 0
fi


if [ "${_GLOBAL_PROFIL}" == "ALL" ]
then
	_TITRE="Service Health Check VIYA 3.5"
fi
if [ "${_GLOBAL_PROFIL}" == "MS" ]
then
	_TITRE="MicroService Health Check VIYA 3.5"
fi
if [ "${_GLOBAL_PROFIL}" == "CASCTRL" ]
then
	_TITRE="CAS Controller Check VIYA 3.5"
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



echo -en  "${YELLOW}Linux Version${NC}\n"
echo -en  "${BLUE}cat /etc/redhat-release${NC} : " 
cat /etc/redhat-release
echo -en  "\n"

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

echo -en  "${BLUE}/etc/hosts${NC}\n"
cat /etc/hosts
echo -en  "\n"

echo -en  "${BLUE}nslookup${NC}\n"
while read line  
do   
   echo -e "${YELLOW}$line${NC}"
   hostIP=$(echo -e "$line" | awk '{ print $1}')
   hostFQDN=$(echo -e "$line" | awk '{ print $2}')
   nslookup $hostFQDN
done < /etc/hosts

echo -en  "${YELLOW}CPU Info${NC} : "
cat /proc/cpuinfo | grep processor |  wc -l
echo ""

echo -en  "${YELLOW}Memory${NC}\n"
free -h

echo -en  "${YELLOW}Disk space${NC}\n"
df -h /opt/
df -h /var/log/
df -h /tmp/

echo -en  "${YELLOW}noexec${NC}\n"
findmnt -l | grep noexec

echo -en  "${YELLOW}fstab${NC}\n"
cat /etc/fstab



# TODO ajouter une option  pour avoir le FS du CAS_CACHE_DISK

echo -en  "${YELLOW}SELinux${NC}\n"
/sbin/sestatus | grep "Current mode"
/etc/selinux/config |grep SELINUX


echo -en  "${YELLOW}Ulimit values ${NC}\n"
ulimit -a

echo -en  "${YELLOW}Check /etc/sysctl.conf ${NC}\n"
cat /etc/sysctl.conf | grep "kernel\.sem\|net\.core\.somaxconn"

echo -en  "${YELLOW}Check systemd - Default Time-Outs ${NC}\n"
# SAS® Business Orchestration Services 10.1: Deployment Guide
# https://documentation.sas.com/doc/en/dplyboss0phy0lax/10.1/p06ojoph47tdwin12otv7qfoxqo3.htm#n029evhqptj50tn1uypnh8epqe1m
cat /etc/systemd/system.conf | grep DefaultTimeoutSt

if [ "${_GLOBAL_FULL}" == "1" ]
then
	echo -en  "${YELLOW}User'${NC}\n"
	cat /etc/passwd | grep -E '^(cas|sas|viyassh|apache)';
fi

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
	
	# *** 
	# *** Web server verification
	# ***
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

if [ "${_GLOBAL_FULL}" == "1" ]
then
	echo -en  "${YELLOW}sas-ops env${NC}\n"
	/opt/sas/viya/home/bin/sas-ops env

	echo -en  "${YELLOW}sas-ops info${NC}\n"
	/opt/sas/viya/home/bin/sas-ops info
	
	echo -en  "${YELLOW}sas-ops tasks agent${NC}\n"
	/opt/sas/viya/home/bin/sas-ops tasks --name "ops-agentsrv"
fi

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


### BOOTSTRAP CONFIG
export CONSUL_TOKEN=$(cat /opt/sas/viya/config/etc/SASSecurityCertificateFramework/tokens/consul/default/management.token)
/opt/sas/viya/home/bin/sas-bootstrap-config kv read --recurse config > /tmp/sas-bootstrap-config



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


 	echo ""
	echo -en "${RED}************************${NC}\n"   
	echo -en "${RED}*** Specific configuration ${NC}\n"                                      
	echo -en "${RED}************************${NC}\n"   
	echo ""
	echo -en  "${YELLOW}Timeout${NC}\n"

 	# https://documentation.sas.com/doc/en/calcdc/3.5/calconfig/n08025sasconfiguration0admin.htm 
 	accessTokenValiditySeconds=$(grep policy.accessTokenValiditySeconds /tmp/sas-bootstrap-config | grep -v name )
	echo "policy.accessTokenValiditySecond : "$accessTokenValiditySeconds
 
   	accessTokenValiditySecondsGlobal=$(grep policy.global.accessTokenValiditySeconds /tmp/sas-bootstrap-config | grep -v name )
  	echo " policy.global.accessTokenValiditySeconds : "$accessTokenValiditySecondsGlobal

   	
   
	petrichorTimeout=$(cat /etc/httpd/conf.d/petrichor.conf  | grep -i timeout | grep -v \# | grep -v KeepAliveTimeout)
	echo "timeout petrichor.conf : "$petrichorTimeout
 
  	# https://documentation.sas.com/doc/en/calcdc/3.5/calconfig/n03000sasconfiguration0admin.htm
   	servletSessionTimeout=$(grep servlet.session.timeout /tmp/sas-bootstrap-config | grep -v name )
  	echo " servlet.session.timeout : "$servletSessionTimeout
   	
 

fi

echo ""
echo -en "${RED}************************${NC}\n"   
echo -en "${RED}*** CAS ${NC}\n"                                      
echo -en "${RED}************************${NC}\n"   
echo ""

#configured caslib

# https://MS/casManagement/servers?limit=9999
# https://MS/casManagement/servers/cas-shared-default/nodes?limit=10000

echo -en  "${YELLOW}CAS Consul configuration${NC}\n"
CAS_MODE=$(/opt/sas/viya/home/bin/sas-bootstrap-config kv read --recurse config | grep -v configurationservice | grep "sas.cas" | grep ${casID} | grep configuration | grep mode  | cut -d "=" -f 2)
echo "CAS_MODE : "$CAS_MODE

CAS_INITIAL_WORKER_COUNT=$(/opt/sas/viya/home/bin/sas-bootstrap-config kv read --recurse config | grep -v configurationservice | grep "sas.cas" | grep ${casID} | grep CAS_INITIAL_WORKER_COUNT  | cut -d "=" -f 2)
echo "CAS_INITIAL_WORKER_COUNT : "$CAS_INITIAL_WORKER_COUNT

SASCONSULHOST=$(/opt/sas/viya/home/bin/sas-bootstrap-config kv read --recurse config | grep -v configurationservice | grep "sas.cas" |  grep SASCONSULHOST | grep ${casID}  | cut -d "=" -f 2)
echo "SASCONSULHOST : "$SASCONSULHOST

SASCONTROLLERHOST=$(/opt/sas/viya/home/bin/sas-bootstrap-config kv read --recurse config | grep -v configurationservice | grep "sas.cas" |  grep SASCONTROLLERHOST | grep ${casID}  | cut -d "=" -f 2)
echo "SASCONTROLLERHOST : "$SASCONTROLLERHOST

CAS_DISK_CACHE=$(/opt/sas/viya/home/bin/sas-bootstrap-config kv read --recurse config | grep -v configurationservice | grep "sas.cas" |  grep CAS_DISK_CACHE | grep ${casID}  | cut -d "=" -f 2)
echo "CAS_DISK_CACHE : "$CAS_DISK_CACHE

SASWORKERHOSTS=$(/opt/sas/viya/home/bin/sas-bootstrap-config kv read --recurse config | grep -v configurationservice | grep "sas.cas" |  grep SASWORKERHOSTS | grep ${casID}  | cut -d "=" -f 2)
echo "SASWORKERHOSTS : " $SASWORKERHOSTS


echo -en  "${YELLOW}cas.hosts${NC}\n"
cat /opt/sas/viya/config/etc/cas/default/cas.hosts

echo ""
echo -en "${RED}************************${NC}\n"   
echo -en "${RED}*** ELASTICSEARCH ${NC}\n"                                      
echo -en "${RED}************************${NC}\n"   
echo ""
# https://documentation.sas.com/doc/en/calcdc/3.5/dplyml0phy0lax/n0s1g2zrw0jfbln1kd0r88zg6nlx.htm

vault_token=/opt/sas/viya/config/etc/SASSecurityCertificateFramework/tokens/elasticsearch-secure/default/vault.token
ca_cert=/opt/sas/viya/config/etc/SASSecurityCertificateFramework/cacerts/trustedcerts.pem
key_file=/tmp/elastic-verification-key.pem
cert_file=/tmp/elastic-verification-cert.pem

source /opt/sas/viya/config/consul.conf
read vault_ip vault_port <<< $(/opt/sas/viya/home/bin/sas-bootstrap-config catalog service vault | awk '/"address"/||/"servicePort"/{print $2}' |sed -e 's/"//g' -e 's/,//' | head -n 2)

/opt/sas/viya/home/SASSecurityCertificateFramework/bin/sas-crypto-management req-vault-cert --common-name "sgadmin" --vault-addr "https://${vault_ip}:${vault_port}" --vault-cafile "${ca_cert}" --vault-token "${vault_token}"  --out-crt "${cert_file}"  --out-form 'pem' --out-key "${key_file}"
curl --cacert ${ca_cert} --key ${key_file} --cert ${cert_file} https://IP-address-for-Elasticsearchmaster-node:9200/_cluster/health?pretty=true



echo ""
echo -en "${RED}************************${NC}\n"   
echo -en "${RED}*** SPRE ${NC}\n"                                      
echo -en "${RED}************************${NC}\n"   
echo ""

#proc setinit; run;

# check allowXCMD 
# systask command "id" shell wait ;

read -p "Viya Admin Username? : " _SAS_USER 
read -p "Viya Admin Password? : " _SAS_PASSWORD 


clidir=/opt/sas/viya/home/bin
$clidir/sas-admin --colors-enabled profile set-endpoint http://localhost
$clidir/sas-admin --colors-enabled profile set-output fulljson

$clidir/sas-admin --colors-enabled auth login -user $_SAS_USER -password $_SAS_PASSWORD 

$clidir/sas-admin licenses site-info list
$clidir/sas-admin licenses products list --expired
$clidir/sas-admin licenses count --current



echo ""
echo -en "${RED}************************${NC}\n"   
echo -en "${RED}*** Other check${NC}\n"                                      
echo -en "${RED}************************${NC}\n"   
echo ""
if [ "${_GLOBAL_FULL}" == "1" ]
then
	echo -en  "${YELLOW}Check disabled services${NC}\n"
	cat /opt/sas/viya/config/etc/viya-svc-mgr/svc-ignore | grep -v '#'
	echo ""

	echo -en  "${YELLOW}sas-ops validate${NC}\n"
	/opt/sas/viya/home/bin/sas-ops validate --level 3 --verbose

	echo -en  "${YELLOW}sas-ops validate${NC}\n"
	/opt/sas/viya/home/bin/sas-ops validate --level 3 --verbose
fi

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

if [ "${_GLOBAL_PROFIL}" == "CASCTRL" ]
then
	caslaunch=$(ls -lrt /opt/sas/viya/home/SASFoundation/utilities/bin/caslaunch | grep "rwsr-xr-x")
	if [ "$caslaunch" != "" ]
	then
  		echo -en $(ls -lrt /opt/sas/viya/home/SASFoundation/utilities/bin/caslaunch)" : " "${GREEN}OK${NC}\n"   
	else
  	echo -en $(ls -lrt /opt/sas/viya/home/SASFoundation/utilities/bin/caslaunch)" : " "${RED}KO${NC}\n"   
	fi
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



