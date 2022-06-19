#!/bin/bash 

# *********************************************************
# *** Check rapide de VIYA 3.5
# *** (c) Nicolas Housset
# *** https://www.nicolas-housset.fr
# ***
# *** Copier ce shell dans sas_viya_playbook
# *********************************************************

RED='\033[031m'
GREEN='\033[032m'
YELLOW='\033[033m'
BLUE='\033[034m'
NC='\033[0m' 


echo -en  "${RED}Check Consul ${NC}\n"


cmd="sudo netstat -tupln | grep 8501"
ansible deployTarget -m shell -a "$cmd" 2>/dev/null | grep -v CHANGED


source /opt/sas/viya/config/consul.conf
export CONSUL_HTTP_TOKEN=$( cat /opt/sas/viya/config/etc/SASSecurityCertificateFramework/tokens/consul/default/client.token)
echo $CONSUL_HTTP_TOKEN
/opt/sas/viya/home/bin/sas-bootstrap-config catalog services | grep serviceName


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
  ansible deployTarget -m shell -a "$cmd" 2>/dev/null | grep -v CHANGED

echo -en  "${RED} Check sasdatasvrc${NC}\n"
cmd="sudo /etc/init.d/sas-viya-sasdatasvrc-postgres-pgpool0 status"
ansible deployTarget -m shell -a "$cmd" 2>/dev/null | grep -v CHANGED
