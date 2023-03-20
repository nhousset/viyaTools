import sys, argparse, requests, json, time, csv
import os
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)



def python_check(argv):

  parser = argparse.ArgumentParser(description='List')
  parser.add_argument('--protocol', default='https')
  parser.add_argument('--host', default='localhost')
  parser.add_argument('--port', default='443')
  parser.add_argument('--username', default='user')
  parser.add_argument('--password', default='pass')


  env = parser.parse_args()

  get_auth_token(env)
  get_info(env)
 
def convertTime(timeStr):
  return (pd.to_datetime(timeStr) - pd.datetime(1960, 1, 1)).days
 

def getHeaders():
  return {
    'Authorization': 'Basic c2FzLmVjOg==',
    'Accept': 'application/json',
    'Content-Type': 'application/x-www-form-urlencoded',
    'user_agent'  : 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36'
  }

def getAuthHeaders(env, acceptType):
  return {
    'Content-Type': 'application/json',
    'Authorization': 'bearer {env.authtoken}'.format(**locals()),
    'Accept': acceptType
  }

def get_auth_token(env):
  print('Sign in to SASLogon...')
  uri = '{env.protocol}://{env.host}:{env.port}/SASLogon/oauth/token'.format(**locals())
  body = 'grant_type=password&username={env.username}&password={env.password}'.format(**locals())
  
  response = requests.post(uri, headers=getHeaders(), data=body, verify=False, timeout=2000)
  if response.status_code == 200:
    env.authtoken = response.json()['access_token']
  else:
    print("Failed to sign in...")
    sys.exit(1)

def get_info(env):
  print('Retrieving Top-Level Data Sources')
  
  
  uri = '{env.protocol}://{env.host}:{env.port}/casManagement/providers/cas/sources'.format(**locals())
  headers = getAuthHeaders(env, 'application/vnd.sas.collection+json')
  response = requests.get(uri, headers=headers,  verify=False)
  
  if response.status_code == 200:
    env.projects = {}

    print('-------------------------------------------------\n')
    print('Number\t Name\t\t\t type\t\t providerId\n')
    print('-------------------------------------------------\n')
    i = 1
    for p in response.json()['items']:
      env.projects[i] = p
      print(str(i) + ':\t' + p['name'].strip() + '\t\t' + p['type'].strip() + '\t\t' + p['providerId'] + '\n')
      i = i + 1
    print('-------------------------------------------------\n')
  else:
    print('Retrieving Top-Level Data Sources failed')
    sys.exit(1)

  print('Retrieving List Nodes')
  uri = '{env.protocol}://{env.host}:{env.port}/casManagement/servers/cas-shared-default/nodes'.format(**locals())
  headers = getAuthHeaders(env, 'application/vnd.sas.collection+json')
  response = requests.get(uri, headers=headers,  verify=False)
  
  if response.status_code == 200:
    env.projects = {}

    print('-------------------------------------------------\n')
    print('Number\t Name\t\t\t role\t\t connected\n')
    print('-------------------------------------------------\n')
    i = 1
    for p in response.json()['items']:
      env.projects[i] = p
      print(str(i) + ':\t' + p['name'].strip() + '\t\t' + p['role'].strip() + '\t\t' + str(p['connected']) + '\n')
      i = i + 1
    print('-------------------------------------------------\n')
  else:
    print('List Nodes failed')
    sys.exit(1)

  print('Retrieving Caslibs')
  uri = '{env.protocol}://{env.host}:{env.port}/casManagement/servers/cas-shared-default/caslibs'.format(**locals())
  headers = getAuthHeaders(env, 'application/vnd.sas.collection+json')
  response = requests.get(uri, headers=headers,  verify=False)
  
  if response.status_code == 200:
    env.projects = {}

    print('-------------------------------------------------\n')
    print('Number\t Name\t\t\t type\t\t scope\t\t path\n')
    print('-------------------------------------------------\n')
    i = 1
    for p in response.json()['items']:
      env.projects[i] = p
      print(str(i) + ':\t' + p['name'].strip() + '\t\t' + p['type'].strip() + '\t\t' + p['scope'] + '\t\t' + p['path'] + '\n')
      i = i + 1
    print('-------------------------------------------------\n')
  else:
    print('Retrieving Caslibs failed')
    sys.exit(1)
def print_time(start, end, message): 
  timeEclapsed = end - start
  print('************************************')
  print('{message} took {timeEclapsed} seconds   '.format(**locals() ))
  print('************************************')


if __name__ == "__main__":
  python_check(sys.argv[1:])
