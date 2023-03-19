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

  local UPSTREAM=${1:-'@{u}'}
  local LOCAL_REV=$(git -C "${PROJECT_DIR}" rev-parse @)
  
  if [ -z "$SILENT_MODE" ]; then
   fxInfo "Local rev.: ##${LOCAL_REV}##"
  fi
  
  local REMOTE_REV=$(git -C "${PROJECT_DIR}" rev-parse "$UPSTREAM")
  
  if [ -z "$SILENT_MODE" ]; then
   fxInfo "Remote rev.: ##${REMOTE_REV}##"
  fi
  
  local BASE=$(git -C "${PROJECT_DIR}" merge-base @ "$UPSTREAM")

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
