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
    fxCatastrophicError "$EXECUTABLE doesn't exist!"
  fi
  
  fxTitle "🧹 Removing existing $LINK_NAME links..."
  sudo rm -f "/usr/bin/$LINK_NAME" "/usr/local/bin/$LINK_NAME"
  
  fxTitle "🔗 Linking..."
  echo "Script:\t ${EXECUTABLE}"
  echo "Link:\t ${LINK_NAME}"
  sudo ln -s "$EXECUTABLE" "/usr/local/bin/$LINK_NAME"
}
