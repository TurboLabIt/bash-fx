#!/usr/bin/env bash

if [ ! -z "${PROJECT_DIR}" ]; then
  PROJECT_DIR_OWNER=$(fxGetFileOwner ${PROJECT_DIR})
fi


if [ ! -z "${PROJECT_DIR}" ] && [ -f "${PROJECT_DIR}env" ]; then

  APP_ENV=$(cat "${PROJECT_DIR}env")
  APP_ENV=$(echo "${APP_ENV}" | grep -v '^#' | grep .)

elif [ ! -z "${PROJECT_DIR}" ] && [ -d "${PROJECT_DIR}.git" ] && [ "$(whoami)" = "$PROJECT_DIR_OWNER" ]; then

  GIT_BRANCH=$(git -C $PROJECT_DIR branch | grep \* | cut -d ' ' -f2-)

elif [ ! -z "${PROJECT_DIR}" ] && [ -d "${PROJECT_DIR}.git" ] && [ "$(whoami)" != "$PROJECT_DIR_OWNER" ]; then

  GIT_BRANCH=$(sudo -u $PROJECT_DIR_OWNER -H git -C $PROJECT_DIR branch | grep \* | cut -d ' ' -f2-)
fi


if [ "$GIT_BRANCH" = "master" ] || [ "$GIT_BRANCH" = "main" ]; then

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
    fxCatastrophicError "🧑‍💻 This script cannot run if APP_ENV is not set or is PRODUCTION! Current env: ##$APP_ENV##"
  fi
}


function fxEnvProdOnly()
{
  if [ -z "$APP_ENV" ] || [ "$APP_ENV" != "prod" ]; then
    fxCatastrophicError "🧑‍💻 This script cannot run if APP_ENV is not PRODUCTION! Current env: ##$APP_ENV##"
  fi
}


function fxEnvNotDev()
{
  if [ -z "$APP_ENV" ] || [ "$APP_ENV" == "dev" ]; then
    fxCatastrophicError "🧑‍💻 This script cannot run if APP_ENV is DEV! Current env: ##$APP_ENV##"
  fi
}


function fxContainerDetection()
{
  local SILENT_MODE=$1
  
  if [ -z "$SILENT_MODE" ]; then
   fxTitle "🐋 Checking if the app is running in a container..."
  fi
  
  if grep -qa 'container=lxc' /proc/1/environ || [ -f "/.dockerenv" ]; then
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


function fxGetUbuntuVersion()
{
    if [ ! -f /etc/os-release ]; then
    fxCatastrophicError "fxGetUbuntuVersion Cannot check current OS version (/etc/os-release doesn't exist)"
  fi
  
  source /etc/os-release
  ## VERSION_ID="22.04"
  
  echo "${VERSION_ID}"
}


function fxRequireCompatbileUbuntuVersion()
{
  fxTitle "Checking OS compatibility..."
  
  local COMPATIBLE_OS_VERSIONS="$1"
  if [ -z "${COMPATIBLE_OS_VERSIONS}" ]; then
    fxCatastrophicError "fxRequireCompatbileUbuntuVersion error: provide COMPATIBLE_OS_VERSIONS as the first param"
  fi
  
  local VERSION_ID=$(fxGetUbuntuVersion)
  
  ## explode string to array 
  readarray -d ' ' -t  ARR_COMPATIBLE_OS_VERSIONS <<< "$COMPATIBLE_OS_VERSIONS"
    
  for COMPATIBLE_OS_VERSION in "${ARR_COMPATIBLE_OS_VERSIONS[@]}"; do

    ## trim the last element (?!?)
    COMPATIBLE_OS_VERSION=$(echo "${COMPATIBLE_OS_VERSION}")

    if [ "${VERSION_ID}" == "${COMPATIBLE_OS_VERSION}" ]; then
      fxOK "OK, your OS ##${VERSION_ID}## is compatible"
      return 0
    fi

  done
  
  fxCatastrophicError "The current operating system version ##${VERSION_ID}## is incompatbile with the expected ##${COMPATIBLE_OS_VERSIONS}##" 
}
