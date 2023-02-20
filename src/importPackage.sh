#!/bin/bash

# *********************************************************
# *** Import package VIYA 3.5
# *** (c) Nicolas Housset
# *** https://www.nicolas-housset.fr
# ***
# *** SAS® Viya® 3.5 Administration: Using the Command-Line Interfaces - https://documentation.sas.com/doc/en/calcdc/3.5/calcli/titlepage.htm
# *** Command-Line Interfaces - CLI Examples: Reports - https://documentation.sas.com/doc/en/calcdc/3.5/calcli/n09r8rzfe0xt6gn1krnt75beevgk.htm
# *********************************************************

# Define variables
clidir=/opt/sas/viya/home/bin
tmpdir=/tmp

RED='\033[031m'
GREEN='\033[032m'
YELLOW='\033[033m'
BLUE='\033[034m'
NC='\033[0m' 



helpFunction()
{
   echo ""
   echo -e "${YELLOW}Usage: $0 -u <viya user> -p <viya password> -h <the URL to the SAS services> -d <json directory>${NC}"
   echo "       $0 -u adminuser -p password -h http://viya35.ms -d /tmp/import/"
   echo ""
   echo -e "\t-u userID"
   echo -e "\t-p password"
   echo -e "\t-h Sets the URL to the SAS services. [\$SAS_SERVICES_ENDPOINT]"
   echo -e "\t-d Sets the directory containing the json file(s) to import"
   exit 1 # Exit script after printing help
}

while getopts "u:p:h:d:" opt
do
   case "$opt" in
      u ) _USER="$OPTARG" ;;
      p ) _PASSWORD="$OPTARG" ;;
      h ) _HOSTNAME="$OPTARG" ;;
      d ) _JSONPATH="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$_USER" ] || [ -z "$_PASSWORD" ] || [ -z "$_HOSTNAME" ] || [ -z "$_JSONPATH" ]
then
   echo -e "${RED}Some or all of the parameters are empty${NC}"
   helpFunction
fi

# Begin script in case all parameters are correct

# check if json dir exists
if [ !  -d "$_JSONPATH" ]; then
   echo -e "${RED}${_JSONPATH} does not exist.${NC}"
   exit 1
fi

# Set endpoint for default profile
$clidir/sas-admin --colors-enabled profile set-endpoint $_HOSTNAME
$clidir/sas-admin --colors-enabled profile set-output fulljson

# Refresh authentication token
$clidir/sas-admin --colors-enabled auth login -user $_USER -password $_PASSWORD >/dev/null 2>/dev/null
if [ $? == 1 ]
then  
   echo -e "${RED}Login failed. Bad userid or password.${NC}"
   exit 1 
fi

echo ""
echo -e "${YELLOW}Import json files from ${_JSONPATH}${NC}"
 
# Code to be executed for all .json files in the JSONPATH directory
typeset -i nbImport=0
typeset -i nbImportOk=0
for filename in $_JSONPATH/*.json; do
   nbImport=nbImport+1
   # Extract report name from the filename variable
   name=$(basename -- "$filename")
   
   echo -e "${YELLOW}Processing : ${NC}"${name}
   
   # Execute sas-admin command to upload the report package  
   
   packageId=$($clidir/sas-admin transfer upload --file  $filename | grep id | awk '{ print $2}' | sed 's/"//g' | sed 's/,//g')
   if [ $? == 0 ]
   then
      nbImportOk=nbImportOk+1
      # Import the uploaded package
      
      url="$_HOSTNAME/transfer/packages/$packageId"
   
      echo -e "${YELLOW}Package url : ${NC}"$url
      echo -e "${YELLOW}Package Id : ${NC}"$packageId
      
     $clidir/sas-admin transfer import --request "{\"packageUri\":\"/transfer/packages/$packageId\"}"
      echo ""
      echo ""
    else
       echo -e "${RED}error while importing ${name}.${NC}"
       echo ""
    fi

done

if [ ${nbImport} -gt 0 ]
then
     echo -e "${GREEN}Package import completed [${nbImportOk}/${nbImport}]${NC}"
 fi
echo ""
