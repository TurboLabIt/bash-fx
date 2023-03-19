function fxGitCheckForUpdate()
{
  if [ -z "$1" ]; then
    local PATH=$(pwd)
  else
    local PATH=$1
  fi
  
  local SILENT_MODE=$2
  
  if [ -z "$SILENT_MODE" ]; then
   fxTitle "🔎 Checking if a new git revision is available..."
  fi
  
  local UPSTREAM=${1:-'@{u}'}
  local LOCAL=$(git -C "${PATH}" rev-parse @)
  local REMOTE=$(git -C "${PATH}" rev-parse "$UPSTREAM")
  local BASE=$(git -C "${PATH}" merge-base @ "$UPSTREAM")

  if [ $LOCAL = $REMOTE ]; then
  
    if [ -z "$SILENT_MODE" ]; then
      fxOK "Up-to-date"
    fi
  
    return ""
    
  elif [ $LOCAL = $BASE ]; then
  
    if [ -z "$SILENT_MODE" ]; then
      fxWarning "Need to pull"
    fi
    
    return 1
    
  elif [ $REMOTE = $BASE ]; then
  
    if [ -z "$SILENT_MODE" ]; then
      fxWarning "Need to push"
    fi
  
    return 2
    
  else
  
     if [ -z "$SILENT_MODE" ]; then
      fxWarning "Branch diverged"
    fi
    
    return 3
  fi
}
