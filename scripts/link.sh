#!/usr/bin/env bash

function fxLink()
{
  local TARGET_FULLPATH=$1
  local LINK_FULLPATH=$2
  
  if [ -z "$TARGET_FULLPATH" ] || [ -z "$LINK_FULLPATH" ]; then
    fxCatastrophicError "fxLink usage: pathOfTheExistingTarget pathOfTheLink"
  fi
  
  if [ ! -e "$TARGET_FULLPATH" ]; then
    fxCatastrophicError "fxLink ##${TARGET_FULLPATH}## doesn't exist!"
  fi
  
  fxTitle "🔗 Linking..."
  sudo rm -f "${LINK_FULLPATH}"
  echo "💻 Target: ${TARGET_FULLPATH}"
  echo "🔗 Link:   ${LINK_FULLPATH}"
  sudo ln -s "${TARGET_FULLPATH}" "${LINK_FULLPATH}"
}


function fxLinkBin()
{
  local EXECUTABLE=$1
  local LINK_NAME=$2
  
  if [ -z "$LINK_NAME" ]; then
    LINK_NAME=$(basename "$EXECUTABLE" .sh)
  fi
  
  if [ -z "$EXECUTABLE" ] || [ -z "$LINK_NAME" ]; then
    fxCatastrophicError "Usage: pathOfTheScript linkName"
  fi
  
  if [ ! -f "$EXECUTABLE" ]; then
    fxCatastrophicError "$EXECUTABLE doesn't exist!"
  fi
  
  sudo rm -f "/usr/bin/$LINK_NAME" "/usr/local/bin/$LINK_NAME"
  fxLink "$EXECUTABLE" "/usr/local/bin/$LINK_NAME"
}


function fxCopyCron()
{
  local ORIGIN_CRON_FILEPATH=$1
  
  if [ -z "$2" ]; then
    local DEST_CRON_FILE_PATH="/etc/cron.d/$(basename -- ${ORIGIN_CRON_FILEPATH})"
  else
    local DEST_CRON_FILE_PATH="/etc/cron.d/$2"
  fi
  
  fxTitle "🕛 Copying cron file..."
  echo "💻 Origin: ${ORIGIN_CRON_FILEPATH}"
  echo "🕕 Destin: ${DEST_CRON_FILE_PATH}"
  
  sudo cp "${ORIGIN_CRON_FILEPATH}" "${DEST_CRON_FILE_PATH}"
  sudo chown root:root "${DEST_CRON_FILE_PATH}"
  sudo chmod u=rw,go= "${DEST_CRON_FILE_PATH}"
}
