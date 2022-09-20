#!/bin/bash 

# *********************************************************
# *** Micro Service Health Check VIYA 3.5
# *** (c) Nicolas Housset
# *** https://www.nicolas-housset.fr
# ***
# *********************************************************


source /opt/sas/viya/config/consul.conf
export CONSUL_HTTP_TOKEN=$(cat /opt/sas/viya/config/etc/SASSecurityCertificateFramework/tokens/consul/default/client.token)


RED='\033[031m'
GREEN='\033[032m'
YELLOW='\033[033m'
BLUE='\033[034m'
NC='\033[0m' 

echo -en  "\n"
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

echo -en  "${YELLOW}CPU Info'${NC}\n"
cat /proc/cpuinfo | grep processor |  wc -l
echo -en  "${YELLOW}Memory'${NC}\n"
echo -en  "${YELLOW}Disk space'${NC}\n"
df -h /opt/
df -h /var/log
echo -en  "${YELLOW}Users'${NC}\n"
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
echo -en " process running"
echo -en  "${YELLOW}saspgpool${NC} : "
ps -u saspgpool -f   | grep -v grep | wc -l
echo -en " process running"
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
curl -k --header "X-Consul-Token:$CONSUL_HTTP_TOKEN" --request GET -n https://$vmPrivateIp:8501/v1/catalog/service/saslogon
echo
echo -en  "${YELLOW}compute${NC}\n"
curl -k --header "X-Consul-Token:$CONSUL_HTTP_TOKEN" --request GET -n https://$vmPrivateIp:8501/v1/catalog/service/compute
echo
echo -en  "${YELLOW}Compute/StudioV ${NC}\n"
curl -k --header "X-Consul-Token:$CONSUL_HTTP_TOKEN" --request GET -n https://$vmPrivateIp:8501/v1/catalog/service/modelstudio
echo 
curl -k --header "X-Consul-Token:$CONSUL_HTTP_TOKEN" --request GET -n https://$vmPrivateIp:8501/v1/catalog/service/sasstudioV
echo
exit



 
 




source /opt/sas/viya/config/consul.conf
export CONSUL_HTTP_TOKEN=$( cat /opt/sas/viya/config/etc/SASSecurityCertificateFramework/tokens/consul/default/client.token)
/opt/sas/viya/home/bin/sas-csq consul-status
/opt/sas/viya/home/bin/sas-bootstrap-config catalog services | grep serviceName

curl -vk --header "X-Consul-Token:$CONSUL_HTTP_TOKEN"  https://localhost:8501/v1/agent/members

echo -en  "${RED} Check SASlogon,Compute/StudioV and ModelStudio in Consul ${NC}\n"
echo -en  "${YELLOW}saslogon${NC}\n"
echo
curl -k --header "X-Consul-Token:$CONSUL_HTTP_TOKEN" --request GET -n https://$vmPrivateIp:8501/v1/catalog/service/saslogon
echo
echo -en  "${YELLOW}compute${NC}\n"
curl -k --header "X-Consul-Token:$CONSUL_HTTP_TOKEN" --request GET -n https://$vmPrivateIp:8501/v1/catalog/service/compute
echo
echo -en  "${YELLOW}Compute/StudioV ${NC}\n"
curl -k --header "X-Consul-Token:$CONSUL_HTTP_TOKEN" --request GET -n https://$vmPrivateIp:8501/v1/catalog/service/modelstudio
echo 
curl -k --header "X-Consul-Token:$CONSUL_HTTP_TOKEN" --request GET -n https://$vmPrivateIp:8501/v1/catalog/service/sasstudioV
echo

echo -en  "${RED}Health Check rabbitMQ${NC}\n"
cmd="sudo /opt/sas/viya/home/sbin/rabbitmqctl node_health_check"
ansible all -m shell -a "$cmd" 2>/dev/null | grep -v CHANGED

echo -en  "${RED}rabbitMQ PID${NC}\n"
rabbPid=$(/etc/init.d/sas-viya-rabbitmq-server-default status | grep pid)
echo "$rabbPid" | tr -d '[{},pid'

echo -en  "${RED} Check sasdatasvrc${NC}\n"
cmd="/etc/init.d/sas-viya-sasdatasvrc-postgres-pgpool0 status"
ansible all -m shell -a "$cmd" 2>/dev/null | grep -v CHANGED

echo -en  "${RED} Check vault${NC}\n"
cmd="sudo /opt/sas/viya/home/bin/vault status"
ansible all -m shell -a "$cmd" 2>/dev/null | grep -v CHANGED


export SSL_CERT_FILE=/opt/sas/viya/config/etc/SASSecurityCertificateFramework/cacerts/trustedcerts.pem
/opt/sas/viya/home/bin/vault version
/opt/sas/viya/home/bin/vault status
curl -k -K- https://localhost:8200/v1/viya_inter/roles/test_web_server <<< "header=\"X-Vault-Token: $(sudo cat /opt/sas/viya/config/etc/SA

echo -en  "${RED} Check disabled services${NC}\n"
cmd="cat /opt/sas/viya/config/etc/viya-svc-mgr/svc-ignore | grep -v '#'"
ansible all -m shell -a "$cmd" 2>/dev/null | grep -v CHANGED
