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


# Install

In the project `setup.sh`:

````bash
## bash-fx
if [ -z "$(command -v curl)" ]; then
  sudo apt update && sudo apt install curl -y
fi
curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/master/setup.sh?$(date +%s) | sudo bash
source /usr/local/turbolab.it/bash-fx/bash-fx.sh
## bash-fx is ready
````
