#!/usr/bin/env bash

function lockCheck()
{
  local LOCKFILE=${1}.lock
  if [ -z "$2" ]; then
    LOCKFILE_TIMEOUT=120
  else
    LOCKFILE_TIMEOUT=$2
  fi 

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

  fxTitle "🔒 Creating lockfile in ##${LOCKFILE}##"
  touch "$LOCKFILE"
}


function removeLock()
{
  local LOCKFILE=${1}.lock
  
  if [ -f "${LOCKFILE}" ]; then
  
    fxTitle "🔓 Removing lockfile in ##${LOCKFILE}##"
    rm "${LOCKFILE}"
    fxMessage "${LOCKFILE} deleted"
  fi
}
