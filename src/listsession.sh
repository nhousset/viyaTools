#!/bin/bash

# *********************************************************
# *** VIYA 3.5
# *** (c) Nicolas Housset
# *** https://www.nicolas-housset.fr
# ***
# *** SAS® Viya® 3.5 Administration: Using the Command-Line Interfaces - https://documentation.sas.com/doc/en/calcdc/3.5/calcli/titlepage.htm
# *********************************************************

# Define variables
clidir=/opt/sas/viya/home/bin
tmpdir=/tmp

RED='\033[031m'
GREEN='\033[032m'
YELLOW='\033[033m'
BLUE='\033[034m'
NC='\033[0m' 

export SAS_CLI_DEFAULT_CAS_SERVER=cas-shared-default

helpFunction()
{
   echo ""
   echo -e "${YELLOW}Usage: $0 -u <viya user> -p <viya password> -h <the URL to the SAS services> ${NC}"
   echo "       $0 -u adminuser -p password -h http://viya35.ms -d /tmp/import/"
   echo ""
   echo -e "\t-u userID"
   echo -e "\t-p password"
   echo -e "\t-h Sets the URL to the SAS services. [\$SAS_SERVICES_ENDPOINT]"
   exit 1 # Exit script after printing help
}

_HOSTNAME="http://localhost"

while getopts "u:p:h:" opt
do
   case "$opt" in
      u ) _USER="$OPTARG" ;;
      p ) _PASSWORD="$OPTARG" ;;
      h ) _HOSTNAME="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$_USER" ] || [ -z "$_PASSWORD" ] || [ -z "$_HOSTNAME" ] 
then
   echo -e "${RED}Some or all of the parameters are empty${NC}"
   helpFunction
fi

# Begin script in case all parameters are correct

# Set endpoint for default profile
$clidir/sas-admin --colors-enabled profile set-endpoint $_HOSTNAME
#$clidir/sas-admin --colors-enabled profile set-output fulljson

# Refresh authentication token
$clidir/sas-admin --colors-enabled auth login -user $_USER -password $_PASSWORD >/dev/null 2>/dev/null
if [ $? == 1 ]
then  
   echo -e "${RED}Login failed. Bad userid or password.${NC}"
   exit 1 
else
   echo -e "${GREEN}Login to $_HOSTNAME succesfull.${NC}"
fi

$clidir/sas-admin cas sessions list --superuser --server $SAS_CLI_DEFAULT_CAS_SERVER --sort-by state


# $clidir/sas-admin cas sessions delete --session-id d72397f0-1476-d94e-85ec-4b1ae8aa44a0  --force
