/* Domain */
/*
options sastrace=',,,d' sastraceloc=SASLOG;

libname OSCAMPS3  oracle authdomain="AAUTDOM_ORA_OSCAMPS" schema=DOSC5ADM
       path=OSCAMPS2
                  ;
proc contents data = OSCAMPS3.DWH_TF_TRIM_COMM;
run ;
*/


/*
%let _CASHOSTCONT_=lxdv1000pv.res.private;
%let _CASHOST_=lxdv1000pv.res.private;
%let _CASPORT_=5570;

option set=CASCLIENTDEBUG=1 CASAUTHINFO="/home/users/autres/i21380r/.authinfo";
cas pgo ;
*/

options noquotelenmax;

proc options option=SERVICESBASEURL;run ;
/*
systask command 'export VIYA_BASE_URL=https://lxdv1000pv.res.private ; echo ${VIYA_BASE_URL}' shell wait ;
systask command 'export CLIENT_ID=TEST_SPRE_TO_VIYA ; echo ${CLIENT_ID}' shell wait ;
systask command 'export CLIENT_SECRET=ZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXBfNzk5U1hid1ZiMWVST0pleW1BRGtackE= ; echo ${CLIENT_SECRET}' shell wait ;

systask command 'export SAS_VIYA_TOKEN=$(curl -skX POST "${VIYA_BASE_URL}/SASLogon/oauth/token" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -u "${CLIENT_ID}:${CLIENT_SECRET}" \
-d "grant_type=password&username=I21380R&password=Kade55d1#" );' shell wait ;
*/

/*
export VIYA_BASE_URL=https://lxdv1000pv.res.private ; echo ${VIYA_BASE_URL}
export CLIENT_ID=TEST_SPRE_TO_VIYA ; echo ${CLIENT_ID}
export CLIENT_SECRET=ZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXBfNzk5U1hid1ZiMWVST0pleW1BRGtackE= ; echo ${CLIENT_SECRET}
export APP_TOKEN=$(curl -skX POST "${VIYA_BASE_URL}/SASLogon/oauth/token" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -u "${CLIENT_ID}:${CLIENT_SECRET}" \
      -d "grant_type=password&username=I21380R&password=Kade55d1#" | perl -ne '/{"access_token":"(.+)","t.+/ && print "$1"');
echo "Custom Application Access Token is: ${APP_TOKEN}"
*/


/*
export VIYA_BASE_URL=https://lxdv1000pv.res.private ; echo ${VIYA_BASE_URL}
export CLIENT_ID=TEST_SPRE_TO_VIYA; echo ${CLIENT_ID}
export CLIENT_SECRET=ZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXBfNzk5U1hid1ZiMWVST0pleW1BRGtackE=; echo ${CLIENT_SECRET}
export APP_TOKEN=$(curl -skX POST "${VIYA_BASE_URL}/SASLogon/oauth/token" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -u "${CLIENT_ID}:${CLIENT_SECRET}" \
      -d "grant_type=client_credentials" | perl -ne '/{"access_token":"(.+)","t.+/ && print "$1"'); \
echo "Custom Application Access Token is: ${APP_TOKEN}"
*/


/*
systask command 'export APP_TOKEN=$(curl -skX POST "${VIYA_BASE_URL}/SASLogon/oauth/token" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -u "${CLIENT_ID}:${CLIENT_SECRET}" \
      -d "grant_type=password&username=I21380R&password=Kade55d1#" | perl -ne ''/{"access_token":"(.+)","t.+/ && print "$1"'');' shell wait ;
*/

/*
systask command 'echo "Custom Application Access Token is: ${SAS_VIYA_TOKEN}"' shell wait ;
*/



%let TOKEN=%sysget(SAS_VIYA_TOKEN);
%put &TOKEN;

%let baseurl=http://********************;
/*
proc http url="&baseurl./credentials/domains/AUTDOM_ORA_OSCAMPS/credentials" oauth_bearer=sas_services out=info headerout=headout HEADEROUT_OVERWRITE;
    headers "Accept"="application/json";
run;
*/



options noquotelenmax;

filename libj temp;
proc http
  url="&baseurl./credentials/domains/AUTDOM_ORA_OSCAMPS"
   method='GET'
   ct='application/json'
   out=libj;
   headers "Authorization" = "Bearer &token.";
  ;
 run;
 %put &=SYS_PROCHTTP_STATUS_CODE;

libname libj json fileref=libj;

proc contents data=libj._all_ ;
run ;

proc print data=libj.ALLDATA;
run;


libname OSCAMPS3  postgres authdomain="AUTDOM_ORA_OSCAMPS" ;
