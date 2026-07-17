## Usage: fxMirrorFromSsh "example.com" "/var/www/source" "/var/www/destination" <"root"> <"2222">
## Result: remote:/var/www/source/file.txt => local:/var/www/destination/file.txt
##         The CONTENTS of /var/www/source are synced INTO /var/www/destination.
##         It does NOT create /var/www/destination/source/
function fxMirrorFromSsh()
{
  local REMOTE_HOST="${1}"
  local REMOTE_PATH="${2}"
  local LOCAL_DESTINATION="${3}"
  local REMOTE_USER="${4}"
  local REMOTE_PORT="${5}"
  local DELAY_OPT="${6}"

  fxMirrorSsh "from" "${REMOTE_HOST}" "${REMOTE_PATH}" "${LOCAL_DESTINATION}" "${REMOTE_USER}" "${REMOTE_PORT}" "${DELAY_OPT}"
}


## Usage: fxMirrorToSsh "/var/www/source" "example.com" "/var/www/destination" <"root"> <"2222">
## Result: local:/var/www/source/file.txt => remote:/var/www/destination/file.txt
##         The CONTENTS of /var/www/source are synced INTO /var/www/destination.
##         It does NOT create /var/www/destination/source/
function fxMirrorToSsh()
{
  local LOCAL_SOURCE="${1}"
  local REMOTE_HOST="${2}"
  local REMOTE_PATH="${3}"
  local REMOTE_USER="${4}"
  local REMOTE_PORT="${5}"
  local DELAY_OPT="${6}"

  fxMirrorSsh "to" "${REMOTE_HOST}" "${REMOTE_PATH}" "${LOCAL_SOURCE}" "${REMOTE_USER}" "${REMOTE_PORT}" "${DELAY_OPT}"
}


## If the remote SSH user can sudo without a password, the remote sftp-server runs as
## root — read-only when direction is "from" — so root-only files get mirrored too.
function fxMirrorSsh()
{
  local DIRECTION="${1}"
  local REMOTE_HOST="${2}"
  local REMOTE_PATH="${3}"
  local LOCAL_PATH="${4}"
  local REMOTE_USER="${5}"
  local REMOTE_PORT="${6}"
  local DELAY_OPT="${7}"

  fxTitle "🪞 Mirroring!"
  if [ -z "$(command -v rclone)" ]; then

    fxWarning "rclone is not installed. Installing it now..."
    curl https://rclone.org/install.sh | sudo bash
  fi

  if [ -z "${REMOTE_HOST}" ]; then

    fxCatastrophicError "Please provide the remote hostname" 0
    return 255
  fi

  if [ -z "${REMOTE_PATH}" ]; then

    fxCatastrophicError "Please provide the remote path" 0
    return 255
  fi

  if [ -z "${LOCAL_PATH}" ]; then

    fxCatastrophicError "Please provide the local path" 0
    return 255
  fi

  local SFTP_PATH=":sftp:${REMOTE_PATH}"
  local SRC DST LABEL_FROM LABEL_TO

  local SSH_TARGET="${REMOTE_HOST}"

  local REMOTE_LABEL="${REMOTE_HOST}:${REMOTE_PATH}"
  if [ -n "${REMOTE_USER}" ]; then
    SSH_TARGET="${REMOTE_USER}@${REMOTE_HOST}"
    REMOTE_LABEL="${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}"
  fi

  if [ -n "${REMOTE_PORT}" ]; then
    if ! [[ "${REMOTE_PORT}" =~ ^[0-9]+$ ]]; then
      fxCatastrophicError "REMOTE_PORT must be an integer, got '${REMOTE_PORT}'" 0
      return 255
    fi
    SSH_TARGET="${SSH_TARGET} -p ${REMOTE_PORT}"
  fi

  local -a SFTP_SERVER_COMMAND_OPT=()
  local SFTP_SERVER_BIN="/usr/lib/openssh/sftp-server"

  if [ "${REMOTE_USER}" != "root" ]; then

    ## SSH_TARGET stays unquoted: it may carry ` -p <port>`
    if ssh -n ${SSH_TARGET} sudo -n test -x "${SFTP_SERVER_BIN}" > /dev/null 2>&1; then

      local SFTP_SUDO_CMD="sudo -n ${SFTP_SERVER_BIN}"
      if [ "${DIRECTION}" = "from" ]; then

        ## -R: read-only sftp-server — a pull can never write to the remote
        SFTP_SUDO_CMD="${SFTP_SUDO_CMD} -R"
      fi

      SFTP_SERVER_COMMAND_OPT=( --sftp-server-command "${SFTP_SUDO_CMD}" )
      REMOTE_LABEL="${REMOTE_LABEL} (root via sudo)"

    else

      fxWarning "No passwordless sudo on the remote: mirroring as the SSH user, root-only files won't be transferred"
    fi
  fi

  if [ "${DIRECTION}" = "from" ]; then

    SRC="${SFTP_PATH}"
    DST="${LOCAL_PATH}"
    LABEL_FROM="${REMOTE_LABEL}"
    LABEL_TO="${LOCAL_PATH}"

  elif [ "${DIRECTION}" = "to" ]; then

    SRC="${LOCAL_PATH}"
    DST="${SFTP_PATH}"
    LABEL_FROM="${LOCAL_PATH}"
    LABEL_TO="${REMOTE_LABEL}"

  else

    fxCatastrophicError "Direction must be 'from' or 'to'" 0
    return 255
  fi

  local -a RCLONE_FULL_COMMAND=(
    rclone sync
    --sftp-ssh "ssh ${SSH_TARGET}"
    "${SFTP_SERVER_COMMAND_OPT[@]}"
    --sftp-disable-hashcheck
    --create-empty-src-dirs
    --links
    --transfers 32 --checkers 64
    --retries 5 --low-level-retries 10
    --log-level ERROR
    --progress
    --delete-excluded
    --exclude '*.log' --exclude '*.log.[0-9]*'
    --filter='+ var/log/.gitignore' --filter='- var/log/**'
    --filter='+ var/logs/.gitignore' --filter='- var/logs/**'
    --filter='+ var/cache/.gitignore' --filter='- var/cache/**'
    --filter='+ var/tmp/.gitignore' --filter='- var/tmp/**'
    --filter='+ var/session/.gitignore' --filter='- var/session/**'
    --filter='+ var/sessions/.gitignore' --filter='- var/sessions/**'
    "${SRC}"
    "${DST}"
  )

  echo "From: ${LABEL_FROM}"
  echo "To:   ${LABEL_TO}"
  echo ""

  if [ "${DELAY_OPT}" != "no-delay" ]; then

    echo "${RCLONE_FULL_COMMAND[@]}"
    echo ""
    fxCountdown
  fi

  "${RCLONE_FULL_COMMAND[@]}"
}
