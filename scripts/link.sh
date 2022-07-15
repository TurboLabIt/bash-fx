#!/usr/bin/env bash

function fxLinkBin()
{
  EXECUTABLE=$1
  LINK_NAME=$2
  
  if [ -z "$LINK_NAME" ]; then
    LINK_NAME=$(basename "$EXECUTABLE" .sh)
  fi
  
  if [ -z "$EXECUTABLE" ] || [ -z "$LINK_NAME" ]; then
    fxCatastrophicError "Usage: pathOfTheScript linkName"
  fi
  
  if [ ! -f "$EXECUTABLE" ]; then
    fxCatastrophicError "$1 doesn't exist!"
  fi
  
  fxTitle "🧹 Removing existing $2 links..."
  sudo rm -f "/usr/bin/$2" "/usr/local/bin/$2"
  
  fxTitle "🔗 Linking..."
  fxMessage "Script: ${EXECUTABLE}"
  fxMessage "Script: ${LINK_NAME}"
  sudo ln -s "$1" "/usr/local/bin/$2"
}
