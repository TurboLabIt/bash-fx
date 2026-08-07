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


## the system-wide known hosts file: it works for every user, no matter which
## $HOME ssh ends up with (cron, sudo, ...)
KNOWN_HOSTS_FULLPATH=/etc/ssh/ssh_known_hosts


function fxSshAddKnownHost()
{
  local INPUT_HOSTNAME=$1
  local INPUT_HOST_KEYS=$2

  if ssh-keygen -F "${INPUT_HOSTNAME}" -f "${KNOWN_HOSTS_FULLPATH}" > /dev/null 2>&1; then

    fxOK "##${INPUT_HOSTNAME}## is already known"
    return 0
  fi

  if [ -z "${INPUT_HOST_KEYS}" ]; then

    fxCatastrophicError "Unable to fetch the ##${INPUT_HOSTNAME}## host keys" 0
    return 255
  fi

  echo "${INPUT_HOST_KEYS}" | sudo tee -a "${KNOWN_HOSTS_FULLPATH}" > /dev/null
  sudo chmod u=rw,go=r "${KNOWN_HOSTS_FULLPATH}"
  fxOK "##${INPUT_HOSTNAME}## is now known"
}


function fxSshSetKnownHosts()
{
  fxTitle "⛲ Setting the known hosts..."
  fxInfo "${KNOWN_HOSTS_FULLPATH}"

  fxTitle "Installing jq..."
  if [ -z "$(command -v jq)" ]; then
    sudo apt update && sudo apt install jq -y
  fi

  ## the host keys are fetched over https, so they are verified by TLS
  fxTitle "🍋 Adding GitHub..."
  fxSshAddKnownHost github.com "$(curl -s https://api.github.com/meta | jq -r '.ssh_keys[] | "github.com " + .')"

  fxTitle "🪣 Adding Bitbucket..."
  ## this one is served in known_hosts format already
  fxSshAddKnownHost bitbucket.org "$(curl -s https://bitbucket.org/site/ssh)"
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


function fxSshGenerateUserKey()
{
  local INPUT_USERNAME=$1

  if [ -z "${INPUT_USERNAME}" ]; then
    fxCatastrophicError "fxSshGenerateUserKey: you must provide the username to generate the key for"
  fi

  local USER_HOME=$(fxGetUserHomePath "${INPUT_USERNAME}")

  if [ -z "${USER_HOME}" ]; then
    fxCatastrophicError "fxSshGenerateUserKey: ##${INPUT_USERNAME}## doesn't exist or has no home directory"
  fi

  local USER_SSH_DIR=${USER_HOME}.ssh/
  local USER_SSH_KEY=${USER_SSH_DIR}id_rsa
  local USER_SSH_OWNER=${INPUT_USERNAME}:$(id -gn ${INPUT_USERNAME})
  local USER_SSH_DIR_CHANGED=

  ## the key must belong to its user: switch to it, unless we already are it
  if [ "$(id -un)" = "${INPUT_USERNAME}" ]; then

    local SUDO_CMD=
    local SUDO_USER_CMD=

  else

    local SUDO_CMD=sudo
    local SUDO_USER_CMD="sudo -u ${INPUT_USERNAME} -H"
  fi

  fxTitle "🔐 SSH key of ##${INPUT_USERNAME}##"

  if [ ! -f "${USER_SSH_KEY}" ]; then

    fxInfo "##${USER_SSH_KEY}## not found: generating it now..."

    ${SUDO_CMD} mkdir -p "${USER_SSH_DIR}"
    ${SUDO_CMD} chown "${USER_SSH_OWNER}" "${USER_SSH_DIR}"
    ${SUDO_CMD} chmod u=rwx,go= "${USER_SSH_DIR}"

    ${SUDO_USER_CMD} ssh-keygen -t rsa -N "" -f "${USER_SSH_KEY}" \
      -C "${INPUT_USERNAME} on $(hostname) by ${SCRIPT_NAME:-bash-fx}"

    if [ ! -f "${USER_SSH_KEY}" ]; then
      fxCatastrophicError "fxSshGenerateUserKey: key generation FAILED"
    fi

    ## without the host keys every git clone dies on host key verification
    fxSshSetKnownHosts

    USER_SSH_DIR_CHANGED=1
    fxOK "SSH key generated"

  elif [ ! -f "${USER_SSH_KEY}.pub" ]; then

    ## the public key is the one everybody looks for: rebuild it, never touch the private one
    fxWarning "##${USER_SSH_KEY}.pub## not found: rebuilding it from ##${USER_SSH_KEY}##..."
    ${SUDO_USER_CMD} ssh-keygen -y -f "${USER_SSH_KEY}" | ${SUDO_CMD} tee "${USER_SSH_KEY}.pub" > /dev/null
    USER_SSH_DIR_CHANGED=1

  else

    fxInfo "##${USER_SSH_KEY}## already exists, skipping 🦘"
  fi

  ## whatever we just wrote as root (known_hosts, id_rsa.pub) belongs to the user
  if [ ! -z "${USER_SSH_DIR_CHANGED}" ]; then

    ${SUDO_CMD} chown -R "${USER_SSH_OWNER}" "${USER_SSH_DIR}"
    fxSshResetUserSshPermissions "${INPUT_USERNAME}"
  fi

  if [ ! -f "${USER_SSH_KEY}.pub" ]; then
    fxCatastrophicError "fxSshGenerateUserKey: ##${USER_SSH_KEY}.pub## not found!"
  fi

  fxTitle "🔑 Public SSH key of ##${INPUT_USERNAME}##"
  fxInfo "${USER_SSH_KEY}.pub"
  fxMessage "$(${SUDO_CMD} cat "${USER_SSH_KEY}.pub")"
}

