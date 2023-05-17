fxSshTestAccess()
{
  if [ -z "$1" ]; then
    fxCatastrophicError "fxSshTestAccess: you must provide user@server as an argument"
  fi
  
  fxTitle "🔭 Testing SSH access to ##$1##..."
  
  ssh -t $1 'echo -e "🔭 \e[1;32mAccess to ##$(hostname)## GRANTED\e[0m 🔭"'
  
  if [ "$?" != 0 ]; then
    fxCatastrophicError "Access to ##$1## DENIED"
  fi
}


fxSshCheckRemoteDirectory()
{
  if [ -z "$1" ] || [ -z "$2" ]; then
    fxCatastrophicError "fxSshTestRemoteDirectory: you must provide these arguments: user@server /path/to/test/"
  fi

  fxTitle "🔭 Checking directory..."
  echo "🖥 Server:    ##$1##"
  echo "📂 Dir:      ##$2##"
  echo ""
  
  ssh -t $1 "[ -d $2 ]"
  
  if [ "$?" != 0 ]; then
    fxCatastrophicError "Remote directory check FAILED"
  fi
  
  echo ""
  fxOK "Yes, it exists!"
  
  fxTitle "📂 Remote listing..."
  ssh -t $1 "ls -lah --color $2"
}


function fxSshSetKnownHosts()
{
  local INPUT_USERNAME=$1
  
  if [ ! -z "${INPUT_USERNAME}" ]; then

    fxTitle  "⛲ Setting KnownHosts for ##${INPUT_USERNAME}##"
    local SUDO_USER="sudo -u ${INPUT_USERNAME} -H"
    local SUDO_USER_HOME=$(eval echo ~$INPUT_USERNAME)

  else
  
    fxTitle "⛲ Setting KnownHosts..."
    local SUDO_USER_HOME=$HOME
  fi

  local KNOWN_FILE=${SUDO_USER_HOME}/.ssh/known_hosts
  fxInfo "${KNOWN_FILE}"
  
  fxTitle "🧹 Removing Bitbucket..."
  ${SUDO_USER} ssh-keygen -R bitbucket.org
  
  fxTitle "🍋 Adding Bitbucket..."
  ${SUDO_USER} curl https://bitbucket.org/site/ssh >> ${KNOWN_FILE}
  
  fxTitle "🧹 Removing GitHub..."
  ${SUDO_USER} ssh-keygen -R github.com
  
  fxTitle "🍋 Adding GitHub..."
  ${SUDO_USER} curl https://raw.githubusercontent.com/TurboLabIt/webstackup/master/config/ssh/github-fingerprint >> ${KNOWN_FILE}
}
