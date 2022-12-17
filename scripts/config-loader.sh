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
  fxLoadConfigFromInputProfile "$1"
}


function fxLoadConfigFromInputProfile()
{

  if [ ! -z "$1" ] && [ "$1" != "default" ]; then
    
    fxTitle "📋 Profile ${1} requested..."
    
    ## new naming format: appname-profilename
    local CONFIGFILE_PROFILE_NAME=${SCRIPT_NAME}-${1}.conf
    local CONFIGFILE_PROFILE_FULLPATH_ETC=/etc/turbolab.it/$CONFIGFILE_PROFILE_NAME
    local CONFIGFILE_PROFILE_FULLPATH_DIR=${SCRIPT_DIR}$CONFIGFILE_PROFILE_NAME
    
    ## legacy naming format: appname.profile.profilename
    local CONFIGFILE_LEGACYPROFILE_NAME=${SCRIPT_NAME}.profile.${1}.conf
    local CONFIGFILE_LEGACYPROFILE_FULLPATH_ETC=/etc/turbolab.it/$CONFIGFILE_LEGACYPROFILE_NAME
    local CONFIGFILE_LEGACYPROFILE_FULLPATH_DIR=${SCRIPT_DIR}$CONFIGFILE_LEGACYPROFILE_NAME
    
    fxLoadConfigFromInput \
      "$CONFIGFILE_PROFILE_FULLPATH_ETC" "$CONFIGFILE_PROFILE_FULLPATH_DIR" \
      "$CONFIGFILE_LEGACYPROFILE_FULLPATH_ETC" "$CONFIGFILE_LEGACYPROFILE_FULLPATH_DIR"

    if \
      [ ! -f "$CONFIGFILE_PROFILE_FULLPATH_ETC" ] && [ ! -f "$CONFIGFILE_PROFILE_FULLPATH_DIR" ] && \
      [ ! -f "$CONFIGFILE_LEGACYPROFILE_FULLPATH_ETC" ] && [ ! -f "$CONFIGFILE_LEGACYPROFILE_FULLPATH_DIR" ]; then

      fxCatastrophicError "Profile config file(s) not found" no-exit

      fxTitle "How to fix it"
      echo "Create a config file for this profile:"
      echo ""
      
      fxMessage "sudo cp $CONFIGFILE_FULLPATH_DEFAULT $CONFIGFILE_PROFILE_FULLPATH_ETC && sudo nano $CONFIGFILE_PROFILE_FULLPATH_ETC && sudo chmod u=rwx,go=rx /etc/turbolab.it/${SCRIPT_NAME}*"

      fxEndFooter failure
      exit
    fi

  fi
}
