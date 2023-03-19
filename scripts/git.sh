function fxGitAsOwner()
{
  if [ -z "$1" ]; then
    local PROJECT_DIR=$(pwd)
  else
    local PROJECT_DIR=$1
  fi
  
  local PROJECT_DIR_OWNER=$(fxGetFileOwner ${PROJECT_DIR})
  
  if [ "$(whoami)" = "$PROJECT_DIR_OWNER" ]; then
    git -C "${PROJECT_DIR}" "${@:2}"
  else
    sudo -u $PROJECT_DIR_OWNER -H  git -C "${PROJECT_DIR}" "${@:2}"
  fi
}


function fxGitCheckForUpdate()
{
  if [ -z "$1" ]; then
    local PROJECT_DIR=$(pwd)
  else
    local PROJECT_DIR=$1
  fi

  local SILENT_MODE=$2

  if [ -z "$SILENT_MODE" ]; then
   fxTitle "🔎 Checking if a new git revision is available..."
  fi

  fxGitAsOwner fetch

  local UPSTREAM=${1:-'@{u}'}
  local LOCAL_REV=$(fxGitAsOwner "${PROJECT_DIR}" rev-parse @)
  
  if [ -z "$SILENT_MODE" ]; then
   fxInfo "Local rev. : ##${LOCAL_REV}##"
  fi
  
  local REMOTE_REV=$(fxGitAsOwner "${PROJECT_DIR}" rev-parse "$UPSTREAM")
  
  if [ -z "$SILENT_MODE" ]; then
   fxInfo "Remote rev.: ##${REMOTE_REV}##"
  fi
  
  local BASE=$(fxGitAsOwner "${PROJECT_DIR}" merge-base @ "$UPSTREAM")

  if [ "$LOCAL_REV" = "$REMOTE_REV" ]; then

    if [ -z "$SILENT_MODE" ]; then
      fxOK "Up-to-date"
    fi

    return 0
  fi


  if [ $LOCAL = $BASE ]; then

    if [ -z "$SILENT_MODE" ]; then
      fxWarning "Need to pull"
    fi

    return 1
  fi


  if [ $REMOTE = $BASE ]; then

    if [ -z "$SILENT_MODE" ]; then
      fxWarning "Need to push"
    fi

    return 2
  fi


  if [ -z "$SILENT_MODE" ]; then
      fxWarning "Branch diverged"
  fi

  return 3
}
