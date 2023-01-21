#!/usr/bin/env bash

function lockCheck()
{
  fxTitle "🔒 Checking lockfile..."

  if [ "${1:0:1}" = "/" ]; then
    local LOCKFILE=$1.lock
  else
    local LOCKFILE=/tmp/$1.lock
  fi

  if [ -z "$2" ]; then
    local LOCKFILE_TIMEOUT=120
  else
    local LOCKFILE_TIMEOUT=$2
  fi
  
  fxInfo "Lockfile path: ##${LOCKFILE}## | Lock life: ${LOCKFILE_TIMEOUT}"

  if [ -f "${LOCKFILE}" ] && [ ! -z `find "${LOCKFILE}" -mmin -${LOCKFILE_TIMEOUT}` ]; then
  
    fxCatastrophicError "🔒 Lockfile detected. It looks like this script is already running!" "proceed"

    fxTitle "Lockfile"
    ls -l "${LOCKFILE}"

    echo ""
    echo "To override:"
    fxMessage "sudo rm -f \"$LOCKFILE\""
    
    fxEndFooter failure
    exit
  fi

  fxTitle "🔒 Creating lockfile in ##${LOCKFILE}##..."
  touch "$LOCKFILE"
}


function removeLock()
{
  fxTitle "🔓 Removing lockfile..."
  
  if [ "${1:0:1}" = "/" ]; then
    local LOCKFILE=$1.lock
  else
    local LOCKFILE=/tmp/$1.lock
  fi
  
  fxInfo "Lock file path: ##${LOCKFILE}##"
  
  if [ -f "${LOCKFILE}" ]; then
  
    rm "${LOCKFILE}"
    fxOK "${LOCKFILE} deleted"
    
  else
  
    fxInfo "No lockfile detected"
  fi
}
