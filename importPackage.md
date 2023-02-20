[![Activity](https://img.shields.io/github/commit-activity/m/nhousset/viyaTools)](https://github.com/nhousset/viyaTools)
[![Stars](https://img.shields.io/github/stars/nhousset?style=social)](https://github.com/nhousset/viyaTools)
[![Website](https://img.shields.io/website?down_color=red&down_message=down&up_color=green&up_message=up&url=https://www.nicolas-housset.fr)](https://www.nicolas-housset.fr)
[![Twitter](https://img.shields.io/twitter/follow/nicolas_housset?style=social)](https://twitter.com/nicolas_housset)
[![Youtube](https://img.shields.io/youtube/channel/views/UCHxbJPkSGlJxtvPVrmzjxbg?style=social)](https://www.youtube.com/channel/UCHxbJPkSGlJxtvPVrmzjxbg)

# Import Json

## Overview 
This tool allows you to import files in a VIYA 3.5 platform. 

On the SAS Viya platform, the import phase of the promotion process can be performed using the transfer plug-in to the sas-admin CLI.
This shell uses the sas-admin CLI.

## prerequisites

- The sas-admin CLI and its plug-ins is available on every SAS Viya server in the deployment.
- Do not run this tools as the root user on a host where SAS Viya 3.X is installed.
- You can download the sas-admin CLI and install the plug-ins on a server other than the servers running SAS Viya 3.5

## How to

After cloning the repository, the health check is done simply by running ./importPackage.sh shell in the scripts (src directory)
```
importPackage.sh
```

## Usage

```
./importPackage.sh -u <viya user> -p <viya password> -h <the URL to the SAS services> -d <json directory>
```
  
### Options

-u userID

-p password

-h Sets the URL to the SAS services. [$SAS_SERVICES_ENDPOINT]

-d Sets the directory containing the json file(s) to import

![Import Package](https://github.com/nhousset/viyaTools/blob/main/img/importpackage.JPG?raw=true)
