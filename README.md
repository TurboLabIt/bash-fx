# bash-fx

A collection of common Bash functions and variables


# Usage

At the top of the script:

````bash
## bash-fx
if [ -f "/usr/local/turbolab.it/bash-fx/bash-fx.sh" ]; then
  source "/usr/local/turbolab.it/bash-fx/bash-fx.sh" 
else
  source <(curl -s https://raw.github.com/TurboLabIt/bash-fx/bash-fx.sh)
fi
## bash-fx is ready
````


# How to create a setup.sh

In the project `setup.sh`:

````bash
#!/usr/bin/env bash
echo ""
SCRIPT_NAME=sample-script-name

## bash-fx
if [ -z "$(command -v curl)" ]; then
  sudo apt update && sudo apt install curl -y
fi
curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/master/setup.sh?$(date +%s) | sudo bash
source /usr/local/turbolab.it/bash-fx/bash-fx.sh
## bash-fx is ready

sudo bash /usr/local/turbolab.it/bash-fx/setup/begin.sh ${SCRIPT_NAME}

## Symlink (globally-available zzfirewall command)
if [ ! -f "/usr/local/bin/${SCRIPT_NAME}" ]; then
  ln -s ${INSTALL_DIR}${SCRIPT_NAME}.sh /usr/local/bin/${SCRIPT_NAME}
fi

## ... other stuff ...

sudo bash /usr/local/turbolab.it/bash-fx/setup/end.sh ${SCRIPT_NAME}

````

[Live example](https://github.com/TurboLabIt/zzfirewall/blob/main/setup.sh)
