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
