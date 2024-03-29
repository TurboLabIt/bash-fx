# bash-fx

A collection of common Bash functions and variables


# Option 1: Run from local or remote

````bash
#!/usr/bin/env bash
echo ""
SCRIPT_NAME=sample-script-name

## https://github.com/TurboLabIt/bash-fx
if [ -z $(command -v curl) ]; then sudo apt update && sudo apt install curl -y; fi

if [ -f "/usr/local/turbolab.it/bash-fx/bash-fx.sh" ]; then
  source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
else
  source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)
fi
## bash-fx is ready

fxHeader "🚀 ${SCRIPT_NAME}"
rootCheck
fxConfigLoader "$1"

...

fxEndFooter

````

# Option 2: Install and run

````bash
#!/usr/bin/env bash

## bash-fx
if [ -z $(command -v curl) ]; then sudo apt update && sudo apt install curl -y; fi
if [ ! -f "/usr/local/turbolab.it/bash-fx/bash-fx.sh" ]; then curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/master/setup.sh?$(date +%s) | sudo bash; fi
source /usr/local/turbolab.it/bash-fx/bash-fx.sh
## bash-fx is ready

fxHeader "MY SCRIPT NAME"
rootCheck

...

fxEndFooter

````


# How to create a setup.sh

In the project `setup.sh`:

````bash
#!/usr/bin/env bash
echo ""
SCRIPT_NAME=sample-script-name

## bash-fx
if [ -z $(command -v curl) ]; then sudo apt update && sudo apt install curl -y; fi
curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/master/setup.sh?$(date +%s) | sudo bash
source /usr/local/turbolab.it/bash-fx/bash-fx.sh
## bash-fx is ready

sudo bash /usr/local/turbolab.it/bash-fx/setup/start.sh ${SCRIPT_NAME}

fxLinkBin ${INSTALL_DIR}${SCRIPT_NAME}.sh

if [ ! -f "/etc/cron.d/${SCRIPT_NAME}" ]; then
  sudo cp "${INSTALL_DIR}cron" "/etc/cron.d/${SCRIPT_NAME}"
fi

## ... other stuff ...

sudo bash /usr/local/turbolab.it/bash-fx/setup/the-end.sh ${SCRIPT_NAME}

````

[Live example](https://github.com/TurboLabIt/zzfirewall/blob/main/setup.sh)
