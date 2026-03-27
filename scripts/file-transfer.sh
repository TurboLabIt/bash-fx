function fxMirrorFromSsh()
{
  local REMOTE_USER="${1}"
  local REMOTE_HOST="${2}"
  local REMOTE_PATH="${3}"
  local LOCAL_DESTINATION="${4}"
  local DELAY_OPT="${5}"
  wsuMirrorSsh "from" "${REMOTE_USER}" "${REMOTE_HOST}" "${REMOTE_PATH}" "${LOCAL_DESTINATION}" "${DELAY_OPT}"
}


function fxMirrorToSsh()
{
  local REMOTE_USER="${1}"
  local REMOTE_HOST="${2}"
  local REMOTE_PATH="${3}"
  local LOCAL_SOURCE="${4}"
  local DELAY_OPT="${5}"
  wsuMirrorSsh "to" "${REMOTE_USER}" "${REMOTE_HOST}" "${REMOTE_PATH}" "${LOCAL_SOURCE}" "${DELAY_OPT}"
}


function fxMirrorSsh()
{
  local DIRECTION="${1}"
  local REMOTE_USER="${2}"
  local REMOTE_HOST="${3}"
  local REMOTE_PATH="${4}"
  local LOCAL_PATH="${5}"
  local DELAY_OPT="${6}"

  fxTitle "🪞 Mirroring!"
  if [ -z "$(command -v rclone)" ]; then

    fxWarning "rclone is not installed. Installing it now..."
    curl https://rclone.org/install.sh | sudo bash
  fi

  if [ -z "${REMOTE_USER}" ]; then
    fxCatastrophicError "Please provide the remote username"
  fi

  if [ -z "${REMOTE_HOST}" ]; then
    fxCatastrophicError "Please provide the remote hostname"
  fi

  if [ -z "${REMOTE_PATH}" ]; then
    fxCatastrophicError "Please provide the remote path"
  fi

  if [ -z "${LOCAL_PATH}" ]; then
    fxCatastrophicError "Please provide the local path"
  fi

  local SFTP_PATH=":sftp:${REMOTE_PATH}"
  local SRC DST LABEL_FROM LABEL_TO

  if [ "${DIRECTION}" = "from" ]; then

    SRC="${SFTP_PATH}"
    DST="${LOCAL_PATH}"
    LABEL_FROM="${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}"
    LABEL_TO="${LOCAL_PATH}"

  elif [ "${DIRECTION}" = "to" ]; then

    SRC="${LOCAL_PATH}"
    DST="${SFTP_PATH}"
    LABEL_FROM="${LOCAL_PATH}"
    LABEL_TO="${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}"

  else

    fxCatastrophicError "Direction must be 'from' or 'to'"
  fi

  local -a RCLONE_FULL_COMMAND=(
    rclone sync
    --sftp-ssh "ssh ${REMOTE_USER}@${REMOTE_HOST}"
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
