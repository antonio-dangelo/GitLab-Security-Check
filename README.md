# GitLab-Security-Check
Clone all the repositories you have access to and run the tool deepsecrets in order to have a nice report

# Why this tool
Well, im relatively new where i work and here everything is on GitLab. So i needed something like GitGuardian without the hassle to pay or anything.

So...i discovered [DeepSecrets](https://github.com/ntoskernel/deepsecrets) and decided to run an analisys on all the company projects.

# Requirements
This script will take care of this by itself that you use MacOS, Debian derivate or Arch.

## System Requirments
But here in details the list of requirements:
- Homebrew (only if you are on MacOS)
- Git
- JQ
- Python3
- PIP

## Requirements to make it Wor
- Pesonal Access Token from GitLab with the following permissions: api, read_api, read_user, read_repository, write_repository (i know, some are an overkill...but i look into the future)

# Problems ? Want to Collaborate ?
Feel free to open an issue or MR.
