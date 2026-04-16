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
  while true; do
    local PASSWORD=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 19)
    if [[ "$PASSWORD" =~ [0-9] ]] && [[ "$PASSWORD" =~ [a-z] ]] && [[ "$PASSWORD" =~ [A-Z] ]]; then
      echo "$PASSWORD"
      return 0
     fi
  done
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
  fxTitle "👮 Setting web permissions (u=rwX,go=rX)..."
  
  local OWN_USER=$1
  local PROJECT_DIR=$2
  
  if [ -z "$OWN_USER" ] || [ -z "$PROJECT_DIR" ]; then
    fxCatastrophicError "fxSetWebPermissions: you must provide the user to be set as owner and the directory path"
  fi

  if [ ! -d "$PROJECT_DIR" ]; then
    fxCatastrophicError "fxSetWebPermissions: the path ##$PROJECT_DIR## is not an existing directory"
  fi

  PROJECT_DIR="${PROJECT_DIR%*/}/"

  fxInfo "Working on ##${PROJECT_DIR}##"

  sudo chown -R "${OWN_USER}:www-data" "${PROJECT_DIR}"
  sudo find "${PROJECT_DIR}" -type d -exec chmod u=rwx,g=rxs,o=rx {} +
  sudo find "${PROJECT_DIR}" -type f -exec chmod u=rw,go=r {} +
  fxOK "Done"

  if [ -d "${PROJECT_DIR}scripts" ]; then

    sudo find "${PROJECT_DIR}scripts" -type f -name "*.sh" -exec chmod u=rwx,g=rx,o= {} +
    fxOK "scripts/*.sh done"
  fi

  if [ -d "${PROJECT_DIR}var" ]; then

    sudo find "${PROJECT_DIR}var" -type d -exec chmod u=rwx,g=rwxs,o=rx {} +
    sudo find "${PROJECT_DIR}var" -type f -exec chmod ug=rw,o=r {} +
    fxOK "var/ done"
  fi
  
  fxTitle "📂 Listing ##${PROJECT_DIR}##"
  ls -la --color=always "${PROJECT_DIR}"
}


function fxUserExists()
{
  local INPUT_USERNAME=$1
  
  if [ -z "${INPUT_USERNAME}" ]; then
    fxCatastrophicError "fxUserExists(): please provide the username to check"
  fi
  
  if id "${INPUT_USERNAME}" &>/dev/null; then
    echo "0"
  else
    echo ""
  fi
}


function fxGetUserHomePath()
{
  local INPUT_USERNAME=$1
  local USER_EXISTS=$(fxUserExists "${INPUT_USERNAME}")

  if [ ! "$USER_EXISTS" ]; then
    echo ""
    return 255
  fi
  
  local USER_HOME_PATH=$(eval echo ~$INPUT_USERNAME)
  
  if [ -d "${USER_HOME_PATH}" ]; then
    echo "${USER_HOME_PATH}/"
  else
    echo ""
  fi
}

