fxSshTestAccess()
{
  if [ -z "$1" ]; then
    fxCatastrophicError "fxSshTestAccess: you must provide user@server as an argument"
  fi
  
  fxTitle "🔭 Testing SSH access to ##$1##..."
  
  ssh -o BatchMode=yes -o ConnectTimeout=5 $1 'echo -e "🔭 \e[1;32mAccess to ##$(hostname)## GRANTED\e[0m 🔭"'
  
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
  
  ssh -o BatchMode=yes $1 "[ -d $2 ]"
  
  if [ "$?" != 0 ]; then
    fxCatastrophicError "Remote directory check FAILED"
  fi
  
  echo ""
  fxOK "Yes, it exists!"
  
  fxTitle "📂 Remote listing..."
  ssh -o BatchMode=yes $1 "ls -lah --color $2"
}


function fxSshGetUserSshPath()
{
  local INPUT_USERNAME=$1
  local USER_HOME=$(fxGetUserHomePath "${INPUT_USERNAME}")
  
  if [ "${USER_HOME}" == "" ]; then
    echo ""
    return 255
  fi

  local USER_SSH_DIR=${USER_HOME}.ssh/
  
  if [ -d "${USER_SSH_DIR}" ]; then
    echo "${USER_SSH_DIR}"
  else
    echo ""
  fi
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
  
  #fxTitle "🧹 Removing Bitbucket..."
  #${SUDO_USER} ssh-keygen -R bitbucket.org
  
  #fxTitle "🧹 Removing GitHub..."
  #${SUDO_USER} ssh-keygen -R github.com
  
  #fxTitle "✂ Trimming..."
  #local KNOWN_FILE_CONTENT=$(cat "${KNOWN_FILE}")
  #local KNOWN_FILE_CONTENT=$(fxTrim "${KNOWN_FILE_CONTENT}")
  #echo "${KNOWN_FILE_CONTENT}" > ${KNOWN_FILE}
  
  fxTitle "🍋 Adding Bitbucket..."
  #${SUDO_USER} echo -en '\n' >> ${KNOWN_FILE}
  ${SUDO_USER} curl https://bitbucket.org/site/ssh > ${KNOWN_FILE}
  
  fxTitle "🍋 Adding GitHub..."
  ${SUDO_USER} echo -en '\n' >> ${KNOWN_FILE}
  ${SUDO_USER} echo -en '\n' >> ${KNOWN_FILE}
  ${SUDO_USER} curl https://raw.githubusercontent.com/TurboLabIt/webstackup/master/config/ssh/github-fingerprint >> ${KNOWN_FILE}
  
  fxTitle "✂ Trimming..."
  local KNOWN_FILE_CONTENT=$(cat "${KNOWN_FILE}")
  local KNOWN_FILE_CONTENT=$(fxTrim "${KNOWN_FILE_CONTENT}")
  echo "${KNOWN_FILE_CONTENT}" > ${KNOWN_FILE}
  ${SUDO_USER} echo -en '\n' >> ${KNOWN_FILE}
  
  fxTitle "Final ${KNOWN_FILE}"
  cat "${KNOWN_FILE}"
}


function fxSshResetUserSshPermissions()
{
  if [ -z "${1}" ]; then

    local INPUT_USERNAME=$(logname)

  else

    local INPUT_USERNAME=$1
  fi

  fxTitle "👮 Resetting .ssh for ##${INPUT_USERNAME}##"

  local USER_HOME=$(fxGetUserHomePath "${INPUT_USERNAME}")

  if [ "${USER_HOME}" == "" ]; then

    fxWarning "Invalid home directory"
    return 255
  fi

  if [ ! -d "${USER_HOME}.ssh" ]; then

    fxWarning "User has no .ssh directory"
    return 255
  fi

  ## home directory should not be writeable by the group or others
  # https://superuser.com/a/304000/129204
  sudo chown ${INPUT_USERNAME} "${USER_HOME}"
  sudo chmod u=rwx "${USER_HOME}"
  sudo chmod go-w "${USER_HOME}"
  fxOK "Home OK"

  sudo chown ${INPUT_USERNAME} "${USER_HOME}.ssh" -R
  sudo chmod u=rwx,go= "${USER_HOME}.ssh"
  fxOK ".ssh OK"

  local FILES_IN_SSH=$(shopt -s nullglob dotglob; echo ${USER_HOME}.ssh/*)
  if !(( ${#FILES_IN_SSH} )); then

    fxWarning "The .ssh directory is empty"
    return 255
  fi

  ## max-restriction for everything, including id_rsa
  sudo chmod u=rw,go= ${USER_HOME}.ssh/*
  fxOK ".ssh/* OK"

  ## loosen public key(s)
  local FILES_IN_SSH=$(shopt -s nullglob dotglob; echo ${USER_HOME}.ssh/*.pub)
  if (( ${#FILES_IN_SSH} )); then

    sudo chmod u=rw,go=r ${USER_HOME}.ssh/*.pub
    fxOK ".pub OK"
  fi

  ## authorized_keys
  if [ -f "${USER_HOME}.ssh/authorized_keys" ]; then

    chmod u=rw,g=r,o= ${USER_HOME}.ssh/authorized_keys
    fxOK "authorized_keys OK"
  fi

  ## known_hosts
  if [ -f "${USER_HOME}.ssh/known_hosts" ]; then

    sudo chmod u=rw,go=r ${USER_HOME}.ssh/known_hosts
    fxOK "known_hosts OK"
  fi

  echo ""
  sudo ls -lah "${USER_HOME}.ssh"
}

