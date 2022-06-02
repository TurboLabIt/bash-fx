#!/usr/bin/env bash
echo ""

${SCRIPT_NAME}=$1

## bash-fx
if [ -f "/usr/local/turbolab.it/bash-fx/bash-fx.sh" ]; then
  source "/usr/local/turbolab.it/bash-fx/bash-fx.sh" 
else
  source <(curl -s https://raw.github.com/TurboLabIt/bash-fx/bash-fx.sh)
fi
## bash-fx is ready

printTitle "💽 ${SCRIPT_NAME} setup script..."

## Install directory
INSTALL_DIR_PARENT="/usr/local/turbolab.it/"
INSTALL_DIR=${INSTALL_DIR_PARENT}${SCRIPT_NAME}/

## /etc/ config directory
mkdir -p "/etc/turbolab.it/"

## Install/update
echo ""
if [ ! -d "$INSTALL_DIR" ]; then

  printTitle "💽 Installing..."
  mkdir -p "$INSTALL_DIR_PARENT"
  cd "$INSTALL_DIR_PARENT"
  git clone https://github.com/TurboLabIt/${SCRIPT_NAME}.git
  
else
  printTitle "⏬ Updating..."
fi

cd "$INSTALL_DIR"
git pull

