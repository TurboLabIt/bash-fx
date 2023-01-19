#!/usr/bin/env bash
SCRIPT_NAME=$1

if [ -z "$(command -v curl)" ] || [ -z "$(command -v nano)" ] || [ -z "$(command -v dialog)" ]; then
  sudo apt update && sudo apt install curl nano dialog -y
fi

## bash-fx
if [ -f "/usr/local/turbolab.it/bash-fx/bash-fx.sh" ]; then
  source "/usr/local/turbolab.it/bash-fx/bash-fx.sh" 
else
  source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)
fi
## bash-fx is ready

fxHeader "💽 ${SCRIPT_NAME} setup script"

fxTitle "Suppress needrestart..."
if [ -d "/etc/needrestart/conf.d/" ]; then

  sudo curl -Lo /etc/needrestart/conf.d/zzupdate-needrestart-suppress.conf \
    https://raw.githubusercontent.com/TurboLabIt/zzupdate/master/needrestart-suppress.conf?$(date +%s)
else

  fxInfo "Not installed"
fi

if [ -z "$(command -v git)" ]; then
  sudo apt update && sudo apt install git -y
fi

## /etc/ config directory
mkdir -p "/etc/turbolab.it/"

## Install/update
echo ""
if [ ! -d "$INSTALL_DIR" ]; then

  fxTitle "💽 Installing..."
  mkdir -p "$INSTALL_DIR_PARENT"
  cd "$INSTALL_DIR_PARENT"
  git clone https://github.com/TurboLabIt/${SCRIPT_NAME}.git
  
else

  fxTitle "⏬ Updating..."
fi

cd "$INSTALL_DIR"
git reset --hard
git pull --no-rebase
