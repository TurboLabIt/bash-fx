#!/usr/bin/env bash

function rootCheck()
{
  if ! [ $(id -u) = 0 ]; then
    fxCatastrophicError "💂 This script must run as ROOT"
  fi
}


function expectedUserSetCheck()
{
  if [ -z "${EXPECTED_USER}" ]; then
    fxCatastrophicError "🤷‍♂️ EXPECTED_USER not set"
  fi
}


function fxGetFileOwner()
{
  if [ -z "$1" ]; then
    fxCatastrophicError "fxGetFileOwner: you must provide the file/directory to check"
  fi

  if [ ! -e "$1" ]; then
    echo ''
    return 0
  fi

  stat -c '%U' "$1"
}


function fxPasswordGenerator()
{
  echo "$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 19)"
}


function fxPasswordHide()
{
  local PASSWORD=$1

  if [ ! -z "${PASSWORD}" ]; then
    echo "${PASSWORD:0:2}**...**${PASSWORD: -2}"
  fi
}


function fxSetWebPermissions()
{
  fxTitle "👮 Setting web permissions..."
  
  local OWN_USER=$1
  local PROJECT_DIR=$2
  
  if [ -z "$OWN_USER" ] || [ -z "$PROJECT_DIR" ]; then
    fxCatastrophicError "fxSetWebPermissions: you must provide the user to be set as owner and the directory path"
  fi
  
  if [ ! -d "$PROJECT_DIR" ]; then
    fxCatastrophicError "fxSetWebPermissions: the path ##$PROJECT_DIR## is not an existing directory"
  fi
  
  sudo chmod ugo= "${PROJECT_DIR}" -R
  sudo chmod u=rwx,g=rX "${PROJECT_DIR}" -R
  sudo chmod u=rwx,g=rx "${PROJECT_DIR}scripts/"*.sh -R
  sudo chmod u=rwx,g=rwX "${PROJECT_DIR}var" -R
  
  sudo chown ${OWN_USER}:www-data "${PROJECT_DIR}" -R
  
  fxTitle "📂 Listing ##${PROJECT_DIR}#"
  ls -la --color=always "${PROJECT_DIR}"
}
