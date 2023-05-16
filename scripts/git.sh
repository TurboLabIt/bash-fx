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

  fxGitAsOwner "${PROJECT_DIR}" fetch

  local LOCAL_REV=$(fxGitAsOwner "${PROJECT_DIR}" rev-parse @)

  if [ -z "$SILENT_MODE" ]; then
   fxInfo "Local rev. : ##${LOCAL_REV}##"
  fi

  local REMOTE_REV=$(fxGitAsOwner "${PROJECT_DIR}" rev-parse @{u})

  if [ -z "$SILENT_MODE" ]; then
   fxInfo "Remote rev.: ##${REMOTE_REV}##"
  fi

  local BASE_REV=$(fxGitAsOwner "${PROJECT_DIR}" merge-base @ @{u})

  if [ "$LOCAL_REV" = "$REMOTE_REV" ]; then

    if [ -z "$SILENT_MODE" ]; then
      fxOK "Up-to-date"
    fi

    return 0
  fi


  if [ "$LOCAL_REV" = "$BASE_REV" ]; then

    if [ -z "$SILENT_MODE" ]; then
      fxWarning "Need to pull"
    fi

    return 1
  fi


  if [ "$REMOTE_REV" = "$BASE_REV" ]; then

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


function fxGitSetKnownHosts()
{
  local INPUT_USERNAME=$1
  
  if [ -z "${INPUT_USERNAME}" ]; then

    local  "⛲ Setting KnownHosts for ##${INPUT_USERNAME}##"
    local SUDO_USER="sudo -u ${INPUT_USERNAME} -H"

  else
  
    fxTitle "⛲ Setting KnownHosts..."
  fi
  
  local SUDO_USER_HOME=$($SUDO_USER echo $HOME)/
  
  fxTitle "🧹 Removing Bitbucket..."
  ${SUDO_USER} ssh-keygen -R bitbucket.org
  
  fxTitle "🍋 Adding Bitbucket..."
  ${SUDO_USER} curl https://bitbucket.org/site/ssh >> ${SUDO_USER_HOME}.ssh/known_hosts
  
  fxTitle "🧹 Removing GitHub..."
  ${SUDO_USER} ssh-keygen -R github.com
  
  fxTitle "🍋 Adding GitHub..."
  ${SUDO_USER} curl -L https://api.github.com/meta | jq -r '.ssh_keys | .[]' | sed -e 's/^/github.com /' >> ${SUDO_USER_HOME}.ssh/known_hosts
}
