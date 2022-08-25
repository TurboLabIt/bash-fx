#!/usr/bin/env bash
SCRIPT_NAME=$1

if [ -z "$(command -v curl)" ]; then
  sudo apt update && sudo apt install curl -y
fi

## bash-fx
if [ -f "/usr/local/turbolab.it/bash-fx/bash-fx.sh" ]; then
  source "/usr/local/turbolab.it/bash-fx/bash-fx.sh" 
else
  source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)
fi
## bash-fx is ready

fxHeader "💽 ${SCRIPT_NAME} setup script"

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
git pull --no-rebase
