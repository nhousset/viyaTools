[![Activity](https://img.shields.io/github/commit-activity/m/nhousset/viyaTools)](https://github.com/nhousset/viyaTools)
[![Stars](https://img.shields.io/github/stars/nhousset?style=social)](https://github.com/nhousset/viyaTools)
[![Website](https://img.shields.io/website?down_color=red&down_message=down&up_color=green&up_message=up&url=https://www.nicolas-housset.fr)](https://www.nicolas-housset.fr)
[![Twitter](https://img.shields.io/twitter/follow/nicolas_housset?style=social)](https://twitter.com/nicolas_housset)
[![Youtube](https://img.shields.io/youtube/channel/views/UCHxbJPkSGlJxtvPVrmzjxbg?style=social)](https://www.youtube.com/channel/UCHxbJPkSGlJxtvPVrmzjxbg)

# Micro Service Health Check VIYA 3.5

## Overview 
This tool launches a complete audit of a SAS VIYA 3.5 platform. 


## prerequisites

- The script must be installed on the server you want to test (microservice server, Cas controller)
- You must have root or sudo rights to run this script

## How to

After cloning the repository, the health check is done simply by running msHealthCheck.sh  shell in the scripts directory

```
msHealthCheck.sh
```

### Options

--full perform a complete check

```
msHealthCheck.sh --full
```

--ms controls the microservice server

```
msHealthCheck.sh --ms
```

--casctrl controls the CAS controller server

```
msHealthCheck.sh --casctrl
```

--caswrk controls a CAS Worker server
```
msHealthCheck.sh --caswrk
```



### update viya mode

The --checkupdate  option allows to list the packages present in the repository but not installed on the viya environment

```
msHealthCheck.sh --checkupdate
```


## batch mode

You can use the --batch option to redirect the audit results to a file.

```
msHealthCheck.sh --batch
```

The output file is written to /tmp/ as SASmsHealthCheck_PID.log

### debug mode

```
msHealthCheck.sh --debug
```

