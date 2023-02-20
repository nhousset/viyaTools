#!/bin/bash
# Define variables
clidir=/opt/sas/viya/home/bin
tmpdir=/tmp


helpFunction()
{
   echo ""
   echo "Usage: $0 -u viya user -p viya password -h viya ms hostname -d json directory"
   echo -e "\t-u Description of what is parameterA"
   echo -e "\t-p Description of what is parameterB"
   echo -e "\t-h Description of what is parameterC"
   echo -e "\t-d Description of what is parameterC"
   exit 1 # Exit script after printing help
}

while getopts "u:p:h:d" opt
do
   case "$opt" in
      u ) USER="$OPTARG" ;;
      p ) PASSWORD="$OPTARG" ;;
      h ) HOSTNAME="$OPTARG" ;;
      d ) JSONPATH="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$USER" ] || [ -z "$PASSWORD" ] || [ -z "$HOSTNAME" ] || [ -z "$JSONPATH" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

# Begin script in case all parameters are correct

echo $USER
echo $PASSWORD
echo $HOSTNAME
echo $JSONPATH

exit

RED='\033[031m'
GREEN='\033[032m'
YELLOW='\033[033m'
BLUE='\033[034m'
NC='\033[0m' 

# Set endpoint for default profile
$clidir/sas-admin profile set-endpoint http://$HOSTNAME
$clidir/sas-admin set-output text

# Refresh authentication token
$clidir/sas-admin auth login -user $USER -password $PASSWORD

# Code to be executed for all .json files in the JSONPATH directory

for filename in $JSONPATH/*.json; do

    # Extract report name from the filename variable
    
    name=$(basename -- "$filename")
    # Create variable for the different filenames
    
    out=$tmpdir/package_"${name%.*}".txt
    
    mappingFile=$tmpdir/package_"${name%.*}"_map.txt
    
    # Execute sas-admin command to upload the report package
    # Output is redirected to the out file
    $clidir/sas-admin --profile DevOps transfer upload --file $filename --mapping mappingFile > $out
    
    # Read the id of the uploaded package from the out file
    id="$(grep '"id":' $out | awk '{gsub(/"|,/, "", $2);print $2}')"
    
    # Import the uploaded package
    $clidir/sas-admin --profile DevOps transfer import --id $id --name mappingFile
done
