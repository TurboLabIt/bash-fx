#!/usr/bin/env bash

function zzAppInstall()
{
  local APP_NAME=$1
  fxCheckNotEmptyInput "$APP_NAME"
  local CMD_TO_EXECUTE_IF_NEW=$2
  
  fxTitle "💿 Installing $APP_NAME..."
  if [ ! -d "/usr/local/turbolab.it/$APP_NAME" ]; then

    curl -s https://raw.githubusercontent.com/TurboLabIt/$APP_NAME/master/setup.sh?$(date +%s) | sudo bash
    ${CMD_TO_EXECUTE_IF_NEW}
  
  else
   
    fxOK "Already installed. Updating..."
    git -C "/usr/local/turbolab.it/$APP_NAME" pull
    bash "/usr/local/turbolab.it/$APP_NAME/setup.sh"
    fxOK "Done"
  fi
}
