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
  echo ""
}

