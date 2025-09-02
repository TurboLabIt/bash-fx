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
  
  fxInfo "🔗 Linking..."
  
  if [ -L "${LINK_FULLPATH}" ]; then
    sudo rm -f "${LINK_FULLPATH}"
  fi
  
  echo "💻 Target: ${TARGET_FULLPATH}"
  echo "🔗 Link:   ${LINK_FULLPATH}"
  sudo ln -s "${TARGET_FULLPATH}" "${LINK_FULLPATH}"

  if [ ! -z "${3}" ]; then
  
    fxInfo "Changing owner to ${3}..."
    sudo chown -h ${3} "${LINK_FULLPATH}"
  fi
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


fxReplaceLinkWithCopy()
{
  local LINK_TO_REPLACE=$1
  if [ ! -e "$LINK_TO_REPLACE" ]; then
    fxCatastrophicError "fxReplaceLinkWithCopy: file ##${LINK_TO_REPLACE}## doesn't exist!"
  fi
  
  if [ ! -L "$LINK_TO_REPLACE" ]; then
    
    fxWarning "fxReplaceLinkWithCopy: ##${LINK_TO_REPLACE}## is NOT a link! Nothing to do here!"
    return 1
  fi
  
  fxInfo "♻ Replacing link with a copy..."
  echo "🎯 Working on: ${LINK_TO_REPLACE}"
  
  cp -L "${LINK_TO_REPLACE}" "/tmp/"
  rm -f "${LINK_TO_REPLACE}"
  mv "/tmp/$(basename ${LINK_TO_REPLACE})" "${LINK_TO_REPLACE}"
}
