[![Activity](https://img.shields.io/github/commit-activity/m/nhousset/viyaTools)](https://github.com/nhousset/viyaTools)
[![Stars](https://img.shields.io/github/stars/nhousset?style=social)](https://github.com/nhousset/viyaTools)
[![Website](https://img.shields.io/website?down_color=red&down_message=down&up_color=green&up_message=up&url=https://www.nicolas-housset.fr)](https://www.nicolas-housset.fr)
[![Twitter](https://img.shields.io/twitter/follow/nicolas_housset?style=social)](https://twitter.com/nicolas_housset)
[![Youtube](https://img.shields.io/youtube/channel/views/UCHxbJPkSGlJxtvPVrmzjxbg?style=social)](https://www.youtube.com/channel/UCHxbJPkSGlJxtvPVrmzjxbg)

# ViyaTools

This repository contains tools dedicated to SAS Viya 3.5

## Services Health Check VIYA 3.5

This tool launches a complete audit of a SAS VIYA 3.5 platform.
https://github.com/nhousset/viyaTools/blob/main/msHealthCheck.md 

## Import Json

This tool allows you to import files in a VIYA 3.5 platform.
https://github.com/nhousset/viyaTools/blob/main/importPackage.md

### Audit  identsvcs

https://github.com/nhousset/viyaTools/blob/main/src/audit_identsvc.sh

the two Linux processes identsvcs and launchsvcs authorize and launch the CAS server session. These services must be run as root because, under Linux, the root identity is required to start a running process under another identity. The launchsvcs process creates a CAS session under the identity of the user who submitted the request. The identsvcs process authenticates users when they attempt to connect to a CAS server with a username and password using PAM. ( https://www.nicolas-housset.fr/comprendre-le-demarrage-dune-session-cas/ )

