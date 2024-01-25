  export URL_KNOX="https://3/gateway/cdp-proxy-api/webhdfs/v1/"
  export USER_KNOX="-viya_svc"
  export PATH_KNOX=""
  export TABLE_NAME=""
  export PATH_OUTPUT="/tmp/${TABLE_NAME}"
  
  dateTransactionFile=`date +%d-%m-%y-%M-%S`
  
  echo ""
  echo "Download $TABLE_NAME "
  echo ""
  echo  "Enter $USER_KNOX password : " 
  read KNOX_PASSWORD
  echo ""
  
  curl -su $USER_KNOX:$KNOX_PASSWORD ${URL_KNOX}"/"${PATH_KNOX}"?op=LISTSTATUS" > /tmp/cdp_extract 
  
  cat /tmp/cdp_extract  | grep -Eo '"[^"]*" *(: *([0-9]*|"[^"]*")[^{}\["]*|,)?|[^"\]\[\}\{]*|\{|\},?|\[|\],?|[0-9 ]*,?' | awk '{if ($0 ~ /^[}\]]/ ) offset-=4; printf "%*c%s\n", offset, " ", $0; if ($0 ~ /^[{\[]/) offset+=4}' | grep pathSuffix | cut -d "\"" -f 4  > /tmp/cdp_extract_list_directory
  
  typeset -i nbFileSaved=0
  for directory in $(cat /tmp/cdp_extract_list_directory)
  do
  
    curl -su $USER_KNOX:$KNOX_PASSWORD ${URL_KNOX}"/"${PATH_KNOX}/${directory}/"?op=LISTSTATUS"  | grep -Eo '"[^"]*" *(: *([0-9]*|"[^"]*")[^{}\["]*|,)?|[^"\]\[\}\{]*|\{|\},?|\[|\],?|[0-9 ]*,?' | awk '{if ($0 ~ /^[}\]]/ ) offset-=4; printf "%*c%s\n", offset, " ", $0; if ($0 ~ /^[{\[]/) offset+=4}' | grep -e pathSuffix | cut -d "\"" -f 4  >  /tmp/cdp_extract_list_file
    for fichier in $(cat /tmp/cdp_extract_list_file )
    do
      totalTimeStart=$(date +%s%N)
  
     
      modificationTime=$(curl -su $USER_KNOX:$KNOX_PASSWORD ${URL_KNOX}"/"${PATH_KNOX}/${directory}/${fichier}"?op=GETFILESTATUS" | grep -Eo '"[^"]*" *(: *([0-9]*|"[^"]*")[^{}\["]*|,)?|[^"\]\[\}\{]*|\{|\},?|\[|\],?|[0-9 ]*,?' | grep modificationTime | cut -d "\"" -f 3)
      modificationTime=${modificationTime:1:11}
      
      modificationTimeFR=$(date -d @${modificationTime} +%y-%m-%d %MH%S)
      url=${URL_KNOX}"/"${PATH_KNOX}/${directory}/${fichier}"?op=OPEN"
      
      urlFichierOrc=$(curl -u $USER_KNOX:$KNOX_PASSWORD -Ls -o /dev/null -w %{url_effective} ${url} )
      #outputfile=$(echo ${fichier} | cut -d "-" -f 2 )".orc"
      outputfile=${TABLE_NAME}"_"$nbFileSaved".orc"
      
      downloadTimeStart=$(date +%s%N)
      curl -su ${USER_KNOX}:${KNOX_PASSWORD} ${urlFichierOrc}  > ${PATH_OUTPUT}/${outputfile}
      downloadTime=$((($(date +%s%N) - $downloadTimeStart)/1000000))
  
       
       filenameSaved=$(ls -lrth ${PATH_OUTPUT}/${outputfile} |  awk '{print $9}' )
       sizeSaved=$(ls -lrth ${PATH_OUTPUT}/${outputfile} |  awk '{print $5}' )
  
      totalTime=$((($(date +%s%N) - $totalTimeStart)/1000000))
  
  
       nbFileSaved=$nbFileSaved+1
  
       sizeAlldownload=$(du -h ${PATH_OUTPUT}  |  awk '{print $1}' )
  
       echo  ${nbFileSaved}";"${modificationTime}";"$modificationTimeFR";"${directory}"/"${fichier}";"$filenameSaved" >> ${PATH_OUTPUT}$dateTransactionFile".log"
       echo "["$nbFileSaved"]["$sizeAlldownload"][modificationTime : $modificationTimeFR"]" $filenameSaved" "$sizeSaved" ["$directory"]["${fichier}"[Time taken: $totalTime milliseconds - Time download : $downloadTime millisecond]"
     
      
    done
  done
