#!/usr/bin/env bash

if [ -z "$TIME_START" ]; then
  TIME_START="$(date +%s)"
  DOWEEK="$(date +'%u')"
fi

INSTALL_DIR_PARENT="/usr/local/turbolab.it/"
INSTALL_DIR=${INSTALL_DIR_PARENT}${SCRIPT_NAME}/

SCRIPT_FULLPATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_FULLPATH")/

if [ -z "$SCRIPT_NAME" ]; then
  SCRIPT_NAME=$(basename "$SCRIPT_FULLPATH" .sh)
fi

function fxHeader()
{
  local CHAR_NUM=${#1}
  
  echo -e "\e[1;46m"
  printf '%0.s=' $(seq 0 $CHAR_NUM)
  echo ""
  echo "${1}"
  printf '%0.s=' $(seq 0 $CHAR_NUM)
  echo ""
  echo "$(date) on $(hostname)"
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


function fxOK()
{
  echo -e "\e[1;32m ✔ OK \e[0m"
}


function fxCatastrophicError()
{
  echo -e "\e[1;41m${1}\e[0m"
}


rootCheck()
{
  if ! [ $(id -u) = 0 ]; then
    echo ""
    fxCatastrophicError "💂 This script must run as ROOT"
    fxEndFooter
    exit
  fi
}


function fxEndFooter()
{
  local CHAR_NUM=20
  
  echo -e "\e[1;42m"
  printf '%0.s=' $(seq 0 $CHAR_NUM)
  echo ""
  echo "🏁 The End 🏁"
  printf '%0.s=' $(seq 0 $CHAR_NUM)
  echo ""
  echo "$(date) on $(hostname)"
  echo "Total time: $((($(date +%s)-$TIME_START)/60)) min."
  echo -e "\e[0m"
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

fxSourceLocalOrRemote "scripts/config-loader.sh"

