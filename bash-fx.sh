#!/usr/bin/env bash

# when the including script is sourced directly from the user shell (zzalias) we cannot use this
if [ "$0" != 'bash' ] && [ "$0" != '-bash' ]; then
  SCRIPT_FULLPATH=$(readlink -f "$0")
  SCRIPT_DIR=$(dirname "$SCRIPT_FULLPATH")/
fi

if [ "$0" != 'bash' ] && [ "$0" != '-bash' ] && [ -z "$SCRIPT_NAME" ]; then
  SCRIPT_NAME=$(basename "$SCRIPT_FULLPATH" .sh)
fi

INSTALL_DIR_PARENT=/usr/local/turbolab.it/
INSTALL_DIR=${INSTALL_DIR_PARENT}${SCRIPT_NAME}/

BASHFX_INSTALL_DIR="/usr/local/turbolab.it/bash-fx/"

function fxDate()
{
  date +"🗓️ %T | %A, %B %d, %Y on $(hostname)"
}


function fxHeader()
{
  local CHAR_NUM=${#1}
  
  echo -e "\e[1;46m"
  printf '%0.s=' $(seq 0 $CHAR_NUM)
  echo ""
  echo "${1}"
  printf '%0.s=' $(seq 0 $CHAR_NUM)
  echo ""
  fxDate
  if [ ! -z "${APP_ENV}" ]; then
    echo "🌳 Env: ${APP_ENV}"
  fi
  echo -e "\e[0m"
}


function fxTitle()
{
  local CHAR_NUM=${#1}
  local UNDERLINE=$(printf '%0.s-' $(seq 0 $CHAR_NUM))
  
  echo ""
  echo -e "\e[1;44m${1}\e[0m"
  echo -e "\e[1;44m${UNDERLINE}\e[0m"
  echo ""
}


function fxMessage()
{
  echo -e "\e[1;45m${1}\e[0m"
}


function fxInfo()
{
  echo -e "\e[1;34mℹ️ ${1}\e[0m"
}


function fxOK()
{
  local MESSAGE=$1
  if [ -z "$MESSAGE" ]; then
    MESSSAGE=OK
  fi
  
  echo -e "\e[1;32m✔ ${MESSAGE}\e[0m"
}


function fxImportantMessage()
{
  echo -e "\e[1;33m${1}\e[0m"
}


function fxWarning()
{
  echo -e "\e[1;33m⚠⚠⚠ ${1}\e[0m"
}


function fxCatastrophicError()
{
  echo ""
  echo -e "\e[1;41mvvvvvvvvvvvvvvvvvvvvvvvv\e[0m"
  echo -e "\e[1;41m🛑 Catastrophic error 🛑\e[0m"
  echo -e "\e[1;41m^^^^^^^^^^^^^^^^^^^^^^^^\e[0m"
  echo -e "\e[1;41m${1}\e[0m"
  
  if [ -z "$2" ]; then
    fxEndFooter failure
    exit
  fi
}


function fxExitOnNonZero()
{
  if [ "$1" != 0 ]; then
    fxCatastrophicError "🛑 Critical command failure! Forced exit"
  fi
}


function fxEndFooter()
{
  if [ ! -z "$INITIAL_DIR" ]; then
    fxTitle "Switching back to $INITIAL_DIR"
    cd "$INITIAL_DIR"
    pwd
  fi

  local CHAR_NUM=20
  
  if [ "$1" = "failure" ]; then
    echo -e "\e[1;41m"
  else
    echo -e "\e[1;42m"
  fi
  
  printf '%0.s=' $(seq 0 $CHAR_NUM)
  echo ""
  echo "🏁 The End 🏁"
  printf '%0.s=' $(seq 0 $CHAR_NUM)
  echo ""
  
  fxDate
  echo "Total time: $((($(date +%s)-$TIME_START)/60)) min."
  echo -e "\e[0m"
  echo ""
}


function fxSourceLocalOrRemote()
{
  local LOCAL_FILE=/usr/local/turbolab.it/bash-fx/${1}
  
  if [ -f "$LOCAL_FILE" ]; then
    source "$LOCAL_FILE"
  else
    source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/${1})
  fi
}

fxSourceLocalOrRemote "scripts/timer.sh"
fxSourceLocalOrRemote "scripts/validators.sh"
fxSourceLocalOrRemote "scripts/config-loader.sh"
fxSourceLocalOrRemote "scripts/iptables-plus.sh"
fxSourceLocalOrRemote "scripts/network.sh"
fxSourceLocalOrRemote "scripts/hash.sh"
fxSourceLocalOrRemote "scripts/link.sh"
fxSourceLocalOrRemote "scripts/user.sh"
fxSourceLocalOrRemote "scripts/app-env.sh"
fxSourceLocalOrRemote "scripts/app-installer.sh"
fxSourceLocalOrRemote "scripts/ask.sh"
fxSourceLocalOrRemote "scripts/lock.sh"
fxSourceLocalOrRemote "scripts/replace.sh"
fxSourceLocalOrRemote "scripts/ssh.sh"
