#!/usr/bin/env bash

INSTALL_DIR_PARENT="/usr/local/turbolab.it/"
INSTALL_DIR=${INSTALL_DIR_PARENT}${SCRIPT_NAME}/


function fxHeader()
{
  local CHAR_NUM=${#1}
  
  echo -e "\e[1;46m"
  printf '%0.s=' $(seq 0 $CHAR_NUM)
  echo ""
  echo "${1}"
  printf '%0.s=' $(seq 0 $CHAR_NUM)
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

