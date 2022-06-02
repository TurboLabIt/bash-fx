#!/usr/bin/env bash

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
}


function fxMessage()
{
  echo -e "\e[1;36m${1}\e[0m"
}

