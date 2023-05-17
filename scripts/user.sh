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
  fxTitle "👮 Setting web permissions..."
  
  local OWN_USER=$1
  local PROJECT_DIR=$2
  local BACKGROUND=$3
  
  if [ -z "$OWN_USER" ] || [ -z "$PROJECT_DIR" ]; then
    fxCatastrophicError "fxSetWebPermissions: you must provide the user to be set as owner and the directory path"
  fi
  
  if [ ! -d "$PROJECT_DIR" ]; then
    fxCatastrophicError "fxSetWebPermissions: the path ##$PROJECT_DIR## is not an existing directory"
  fi
  
  local PROJECT_DIR=${PROJECT_DIR%*/}/
  
  if [ ! -z "${BACKGROUND}" ] && [ "${BACKGROUND}" != 0 ]; then
    local SUDOBACKGROUND="sudo -b"
  else
    local SUDOBACKGROUND="sudo" 
  fi
  
   ${SUDOBACKGROUND} chmod ugo= "${PROJECT_DIR}" -R
   ${SUDOBACKGROUND} chmod u=rwx,g=rX "${PROJECT_DIR}" -R
  
  if [ -d "${PROJECT_DIR}scripts" ]; then
    ${SUDOBACKGROUND} chmod u=rwx,g=rx "${PROJECT_DIR}scripts/"*.sh -R
  else
    fxWarning "${PROJECT_DIR}scripts/ not found"
  fi
  
  if [ -d "${PROJECT_DIR}var" ]; then
    ${SUDOBACKGROUND} chmod u=rwx,g=rwX "${PROJECT_DIR}var" -R
  else
    fxWarning "${PROJECT_DIR}var/ not found"
  fi

  ${SUDOBACKGROUND} chown ${OWN_USER}:www-data "${PROJECT_DIR}" -R
  
  fxTitle "📂 Listing ##${PROJECT_DIR}#"
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

