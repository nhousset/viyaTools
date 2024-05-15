echo "*******************************";
echo "********** PASSWORD";
export VIYA_BASE_URL=https://*********************************************************** ; echo ${VIYA_BASE_URL}
export CLIENT_ID=TEST_SPRE_TO_VIYA ; echo ${CLIENT_ID}
export CLIENT_SECRET************************************************************ ; echo ${CLIENT_SECRET}
export APP_TOKEN=$(curl -skX POST "${VIYA_BASE_URL}/SASLogon/oauth/token" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -u "${CLIENT_ID}:${CLIENT_SECRET}" \
      -d "grant_type=password&username=I21380R&password=Kade55d1#" | perl -ne '/{"access_token":"(.+)","t.+/ && print "$1"');

echo "Custom Application Access Token is: ${APP_TOKEN}";


export SAS_VIYA_TOKEN=${APP_TOKEN};


/opt/sas/spre/home/SASFoundation/sas -sysin $HOME/pgm_admin_test_spre_viya.sas -log $HOME/log_admin_test_spre_viya_password.log
echo "Token used : ${SAS_VIYA_TOKEN}";



echo "*******************************";
echo "********** CLIENT_CREDENTIALS";

export APP_TOKEN=$(curl -skX POST "${VIYA_BASE_URL}/SASLogon/oauth/token" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -u "${CLIENT_ID}:${CLIENT_SECRET}" \
      -d "grant_type=client_credentials" | perl -ne '/{"access_token":"(.+)","t.+/ && print "$1"'); \

echo "Custom Application Access Token is: ${APP_TOKEN}";

export SAS_VIYA_TOKEN=${APP_TOKEN};
/opt/sas/spre/home/SASFoundation/sas -sysin $HOME/pgm_admin_test_spre_viya.sas -log $HOME/log_admin_test_spre_viya_credential.log

echo "Token used : ${SAS_VIYA_TOKEN}";
