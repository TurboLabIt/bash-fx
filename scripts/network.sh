#!/usr/bin/env bash

function fxReadRemoteFile()
{
  local URL_TO_READ=$1 
  if [ -z "$URL_TO_READ" ]; then
    fxCatastrophicError "fxReadRemoteFile usage: https://turbolab.it/scarica/204"
  fi
  
  local FILE_CONTENT=$(curl -L "$URL_TO_READ")
  echo "$FILE_CONTENT"
}
