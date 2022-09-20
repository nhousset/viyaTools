# Micro Service Health Check VIYA 3.5

## Overview 
This tool launches a complete audit of a SAS VIYA 3.5 platform. 

## How to

After cloning the repository, the health check is done simply by running msHealthCheck.sh  shell in the scripts directory

```
msHealthCheck.sh
```

You can use the --batch option to redirect the audit results to a file.

```
msHealthCheck.sh --batch
```

The output file is written to /tmp/ as SASmsHealthCheck_<PID>.log
