#!/usr/bin/env bash

if [ ! -z "${PROJECT_DIR}" ]; then
  PROJECT_DIR_OWNER=$(fxGetFileOwner ${PROJECT_DIR})
fi


if [ ! -z "${PROJECT_DIR}" ] && [ -f "${PROJECT_DIR}env" ]; then

  APP_ENV=$(head -n 1 ${PROJECT_DIR}env)

elif [ ! -z "${PROJECT_DIR}" ] && [ -d "${PROJECT_DIR}.git" ] && [ "$(whoami)" = "$PROJECT_DIR_OWNER" ]; then

  GIT_BRANCH=$(git -C $PROJECT_DIR branch | grep \* | cut -d ' ' -f2-)

elif [ ! -z "${PROJECT_DIR}" ] && [ -d "${PROJECT_DIR}.git" ] && [ "$(whoami)" != "$PROJECT_DIR_OWNER" ]; then

  GIT_BRANCH=$(sudo -u $PROJECT_DIR_OWNER -H git -C $PROJECT_DIR branch | grep \* | cut -d ' ' -f2-)
fi


if [ "$GIT_BRANCH" = "master" ]; then

  APP_ENV=prod
  
elif [ "$GIT_BRANCH" = "staging" ]; then

  APP_ENV=staging
  
elif [ "$GIT_BRANCH" = "dev" ] || [[ "$GIT_BRANCH" = "dev-"* ]]; then

  APP_ENV=dev
fi


function devOnlyCheck()
{
  if [ "$APP_ENV" != "dev" ]; then
    fxCatastrophicError "🧑‍💻 This script can run in the **DEV** environment only! Current env: ##$APP_ENV##"
  fi
}


function fxEnvNotProd()
{
  if [ -z "$APP_ENV" ] || [ "$APP_ENV" = "prod" ]; then
    fxCatastrophicError "🧑‍💻 This script cannot run if APP_ENV is not set or in PRODUCTION! Current env: ##$APP_ENV##"
  fi
}


function fxContainerDetection()
{
  local SILENT_MODE=$1
  
  if [ -z "$SILENT_MODE" ]; then
   fxTitle "🐋 Checking if the app is running in a container..."
  fi
  
  if [ -f "/.dockerenv" ]; then
    local IS_CONTAINER=1
  else
    local IS_CONTAINER=0
  fi

  if [ "$IS_CONTAINER" = 1 ] && [ -z "$SILENT_MODE" ]; then
    fxMessage "✔️ Yes, container detected"
  elif [ "$IS_CONTAINER" = 0 ] && [ -z "$SILENT_MODE" ]; then
    fxMessage "🕳️ No container detected"
  fi
  
  return $IS_CONTAINER
}


function fxCtrlConce()
{
  ## kill the whole script on Ctrl+C
  trap "exit" INT
}


## if fxVersionMinCheck ${MIN_VERSION} ${CURRENT_VERSION}; then
function fxVersionMinCheck()
{
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}
