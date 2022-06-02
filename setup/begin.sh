#!/usr/bin/env bash
SCRIPT_NAME=$1

## bash-fx
if [ -f "/usr/local/turbolab.it/bash-fx/bash-fx.sh" ]; then
  source "/usr/local/turbolab.it/bash-fx/bash-fx.sh" 
else
  source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)
fi
## bash-fx is ready

fxHeader "💽 ${SCRIPT_NAME} setup script"

## Install directory
if [ -f "/usr/local/turbolab.it/bash-fx/setup/path.sh" ]; then
  source "/usr/local/turbolab.it/bash-fx/setup/path.sh" 
else
  source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/setup/path.sh)
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
git pull

