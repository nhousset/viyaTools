[![Activity](https://img.shields.io/github/commit-activity/m/nhousset/viyaTools)](https://github.com/nhousset/viyaTools)
[![Stars](https://img.shields.io/github/stars/nhousset?style=social)](https://github.com/nhousset/viyaTools)
[![Website](https://img.shields.io/website?down_color=red&down_message=down&up_color=green&up_message=up&url=https://www.nicolas-housset.fr)](https://www.nicolas-housset.fr)
[![Twitter](https://img.shields.io/twitter/follow/nicolas_housset?style=social)](https://twitter.com/nicolas_housset)
[![Youtube](https://img.shields.io/youtube/channel/views/UCHxbJPkSGlJxtvPVrmzjxbg?style=social)](https://www.youtube.com/channel/UCHxbJPkSGlJxtvPVrmzjxbg)

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

The output file is written to /tmp/ as SASmsHealthCheck_PID.log
