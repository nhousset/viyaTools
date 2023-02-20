#!/bin/bash
# Define variables
clidir=/opt/sas/viya/home/bin
tmpdir=/tmp

for arg in "$@" ; do
  case "$arg" in
    --user)
      USER="${opt#*=}";;
    --password)
      PASSWORD="${opt#*=}";;
     --host)
      HOSTNAME="${opt#*=}";;
      --jsonpath)
      JSONPATH="${opt#*=}";;
            
  esac
done

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
