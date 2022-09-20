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

echo ""
echo -en "${RED}    _    ${NC}              _   _ _______   _____         _   _  _____  ___   _    _____ _   _        _____  _   _  _____ _____  _   __            ${RED}    _    ${NC}\n"
echo -en "${RED} /\| |/\ ${NC}             | | | |_   _\ \ / / _ \       | | | ||  ___|/ _ \ | |  |_   _| | | |      /  __ \| | | ||  ___/  __ \| | / /            ${RED} /\| |/\ ${NC}\n"
echo -en "${RED} \ ' ' / ${NC}______ ______| | | | | |  \ V / /_\ \______| |_| || |__ / /_\ \| |    | | | |_| |______| /  \/| |_| || |__ | /  \/| |/ /______ ______${RED} \ ' ' / ${NC}\n"
echo -en "${RED}|_     _|${NC}______|______| | | | | |   \ /|  _  |______|  _  ||  __||  _  || |    | | |  _  |______| |    |  _  ||  __|| |    |    \______|______${RED}|_     _|${NC}\n"
echo -en "${RED} / ' . \ ${NC}             \ \_/ /_| |_  | || | | |      | | | || |___| | | || |____| | | | | |      | \__/\| | | || |___| \__/\| |\  \            ${RED} / ' . \ ${NC}\n"
echo -en "${RED} \/|_|\/ ${NC}              \___/ \___/  \_/\_| |_/      \_| |_/\____/\_| |_/\_____/\_/ \_| |_/       \____/\_| |_/\____/ \____/\_| \_/            ${RED} \/|_|\/ ${NC}\n"
echo ""                                                                                                                                                       
                                                                                                                                                                                                                                                  
                             
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

echo -en  "${YELLOW}CPU Info'${NC} : "
cat /proc/cpuinfo | grep processor |  wc -l
echo "\n"

echo -en  "${YELLOW}Memory${NC}\n"
free -h

echo -en  "${YELLOW}Disk space${NC}\n"
df -h /opt/
df -h /var/log

echo -en  "${YELLOW}User'${NC}\n"
cat /etc/passwd | grep -E '^(cas|sas|viyassh|apache)';

echo -en  "\n"
echo -en  "${RED}Check process ${NC}\n"
echo -en  "${RED}==================================================${NC}\n"
echo -en  "${YELLOW}ps auxw | grep '/opt/sas/viya'${NC} : "
ps auxw | grep '/opt/sas/viya'  | grep -v grep | wc -l
echo -en "\n"
echo -en  "${YELLOW}ps -u sas -f ${NC} : "
ps -u sas -f  | grep -v grep | wc -l
echo -en " process running"

echo -en  "${YELLOW}ps -u cas -f${NC} : "
ps -u cas -f  | grep -v grep | wc -l
echo -en " process running\n"

echo -en  "${YELLOW}sasrabbitmq${NC} : "
ps -u sasrabbitmq -f   | grep -v grep | wc -l
echo -en " process running\n"

echo -en  "${YELLOW}saspgpool${NC} : "
ps -u saspgpool -f   | grep -v grep | wc -l
echo -en " process running\n"

echo -en  "${YELLOW}Services sas-viya${NC}\n"
systemctl list-units | grep sas-viya
echo -en "\n"

echo -en  "\n"
echo -en  "${RED}Check Viya ${NC}\n"
echo -en  "${RED}==================================================${NC}\n"
echo -en  "${YELLOW}Consul${NC}\n"
netstat -tupln | grep 8501
/opt/sas/viya/home/bin/sas-csq consul-status
curl -vk --header "X-Consul-Token:$CONSUL_HTTP_TOKEN"  https://localhost:8501/v1/agent/members
echo -en "\n"
echo -en "\n"

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
 
echo -en  "${RED}rabbitMQ ${NC}\n"
/etc/init.d/sas-viya-rabbitmq-server-default status 

echo -en  "${RED}Health Check rabbitMQ${NC}\n"
/opt/sas/viya/home/sbin/rabbitmqctl node_health_check


echo -en  "${RED} Check vault${NC}\n"
/opt/sas/viya/home/bin/vault version
/opt/sas/viya/home/bin/vault status

cat /opt/sas/viya/config/etc/vault/default/vault.hcl


curl -k -K- https://localhost:8200/v1/viya_inter/roles/test_web_server <<< "header=\"X-Vault-Token: $(sudo cat /opt/sas/viya/config/etc/SASSecurityCertificateFramework/tokens/consul/default/vault.token)\"" 

openssl s_client -connect localhost:8200 -prexit -CAfile /opt/sas/viya/config/etc/SASSecurityCertificateFramework/cacerts/trustedcerts.pem -showcerts


echo -en  "${RED} Check sasdatasvrc${NC}\n"
/etc/init.d/sas-viya-sasdatasvrc-postgres-pgpool0 status



echo -en  "${RED} Check disabled services${NC}\n"
cmd="cat /opt/sas/viya/config/etc/viya-svc-mgr/svc-ignore | grep -v '#'"
ansible all -m shell -a "$cmd" 2>/dev/null | grep -v CHANGED
