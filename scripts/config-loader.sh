#!/usr/bin/env bash

CONFIGFILE_FULLPATH_DEFAULT=${SCRIPT_DIR}${SCRIPT_NAME}.default.conf
CONFIGFILE_NAME=${SCRIPT_NAME}.conf
CONFIGFILE_FULLPATH_ETC=/etc/turbolab.it/$CONFIGFILE_NAME
CONFIGFILE_FULLPATH_DIR=${SCRIPT_DIR}${CONFIGFILE_NAME}


function fxLoadConfigFromInput()
{
  for CONFIGFILE_FULLPATH in "$@"
  do
    if [ -f "$CONFIGFILE_FULLPATH" ]; then
    
      fxMessage "✅ $CONFIGFILE_FULLPATH"
      source "$CONFIGFILE_FULLPATH"
      
    else
    
      fxMessage "🕳️ $CONFIGFILE_FULLPATH"
    fi
  done
}


function fxConfigLoader()
{
  fxTitle "📋 Reading the config..."
  fxLoadConfigFromInput "$CONFIGFILE_FULLPATH_DEFAULT" "$CONFIGFILE_FULLPATH_ETC" "$CONFIGFILE_FULLPATH_DIR"
}

