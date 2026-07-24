## Usage: fxMirrorFromSsh "example.com" "/var/www/source" "/var/www/destination" <"root"> <"2222"> <"no-delay"> <"with-logs"> <"fast">
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
  local WITH_LOGS_OPT="${7}"
  local FAST_OPT="${8}"

  fxMirrorSsh "from" "${REMOTE_HOST}" "${REMOTE_PATH}" "${LOCAL_DESTINATION}" "${REMOTE_USER}" "${REMOTE_PORT}" "${DELAY_OPT}" "${WITH_LOGS_OPT}" "${FAST_OPT}"
}


## Usage: fxMirrorToSsh "/var/www/source" "example.com" "/var/www/destination" <"root"> <"2222"> <"no-delay"> <"with-logs"> <"fast">
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
  local WITH_LOGS_OPT="${7}"
  local FAST_OPT="${8}"

  fxMirrorSsh "to" "${REMOTE_HOST}" "${REMOTE_PATH}" "${LOCAL_SOURCE}" "${REMOTE_USER}" "${REMOTE_PORT}" "${DELAY_OPT}" "${WITH_LOGS_OPT}" "${FAST_OPT}"
}


## Transport: rsync over ONE ssh connection, however big the tree. Do NOT go back to
## a per-file transport: rclone's sftp backend spawns a separate ssh process per
## pooled connection, --sftp-connections defaults to UNLIMITED, and with sudo in the
## middle those connections are never reaped. It snowballed to ~8k live sessions,
## tripped the remote sshd MaxStartups limit and locked us out of the box.
##
## If the remote SSH user can sudo without a password, the remote rsync runs as root,
## so root-only files get mirrored too. A "from" run cannot write on the remote:
## rsync invokes it as `rsync --server --sender`, which only ever reads. To make that
## a guarantee rather than a convention, on pull-only hosts restrict sudoers to
##   <user> ALL=(root) NOPASSWD: /usr/bin/rsync --server --sender *, /usr/bin/rsync --version
## (--version is what the probe below calls; drop " --sender *" to also allow pushes)
function fxMirrorSsh()
{
  local DIRECTION="${1}"
  local REMOTE_HOST="${2}"
  local REMOTE_PATH="${3}"
  local LOCAL_PATH="${4}"
  local REMOTE_USER="${5}"
  local REMOTE_PORT="${6}"
  local DELAY_OPT="${7}"
  local WITH_LOGS_OPT="${8}"
  local FAST_OPT="${9}"

  fxTitle "🪞 Mirroring!"
  if [ -z "$(command -v rsync)" ]; then

    fxWarning "rsync is not installed. Installing it now..."
    sudo apt update && sudo apt install rsync -y
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

  if [ "${DIRECTION}" != "from" ] && [ "${DIRECTION}" != "to" ]; then

    fxCatastrophicError "Direction must be 'from' or 'to'" 0
    return 255
  fi

  local SSH_LOGIN="${REMOTE_HOST}"
  if [ -n "${REMOTE_USER}" ]; then

    SSH_LOGIN="${REMOTE_USER}@${REMOTE_HOST}"
  fi

  ## the same ssh options in the two shapes we need: argv for the sudo probe,
  ## a single string for rsync's -e
  local -a SSH_PROBE_CMD=( ssh -n )
  local SSH_TRANSPORT="ssh"

  if [ -n "${REMOTE_PORT}" ]; then

    if ! [[ "${REMOTE_PORT}" =~ ^[0-9]+$ ]]; then

      fxCatastrophicError "REMOTE_PORT must be an integer, got '${REMOTE_PORT}'" 0
      return 255
    fi

    SSH_PROBE_CMD+=( -p "${REMOTE_PORT}" )
    SSH_TRANSPORT="ssh -p ${REMOTE_PORT}"
  fi

  SSH_PROBE_CMD+=( "${SSH_LOGIN}" )

  ## the trailing slash is what makes rsync sync the CONTENTS of the source
  local REMOTE_SPEC="${SSH_LOGIN}:${REMOTE_PATH%/}/"
  local LOCAL_SPEC="${LOCAL_PATH%/}/"
  local REMOTE_LABEL="${REMOTE_SPEC}"

  local -a SUDO_OPT=()
  local REMOTE_IS_ROOT=0

  if [ "${REMOTE_USER}" = "root" ]; then

    REMOTE_IS_ROOT=1

  elif "${SSH_PROBE_CMD[@]}" sudo -n rsync --version > /dev/null 2>&1; then

    SUDO_OPT=( --rsync-path "sudo -n rsync" )
    REMOTE_IS_ROOT=1
    REMOTE_LABEL="${REMOTE_LABEL} (root via sudo)"

  else

    fxWarning "No passwordless sudo on the remote: mirroring as the SSH user, root-only files won't be transferred"
  fi

  ## --hard-links: without it every hard link is copied as a full separate file. rsync
  ## only detects links WITHIN a single transfer set, so links spanning two calls
  ## (mirror-backup.sh mirrors /var/www, /etc, /home, /root separately) stay unlinked.
  ##
  ## --owner/--group/--devices/--specials need root on the RECEIVING side: without it
  ## rsync warns on every single file and exits 23. Ask for them only when we can
  ## honour them, and keep --numeric-ids so UIDs survive a cross-machine restore.
  local -a ARCHIVE_OPT=( --recursive --links --hard-links --perms --times )
  local RECEIVER_IS_ROOT="${REMOTE_IS_ROOT}"

  if [ "${DIRECTION}" = "from" ]; then

    RECEIVER_IS_ROOT=0
    if [ "${EUID}" -eq 0 ]; then

      RECEIVER_IS_ROOT=1
    fi
  fi

  if [ "${RECEIVER_IS_ROOT}" -eq 1 ]; then

    ARCHIVE_OPT+=( --owner --group --devices --specials --numeric-ids )
  fi

  local SRC DST LABEL_FROM LABEL_TO

  if [ "${DIRECTION}" = "from" ]; then

    SRC="${REMOTE_SPEC}"
    DST="${LOCAL_SPEC}"
    LABEL_FROM="${REMOTE_LABEL}"
    LABEL_TO="${LOCAL_SPEC}"

    if ! mkdir -p "${LOCAL_PATH}"; then

      fxCatastrophicError "Could not create the local destination '${LOCAL_PATH}'" 0
      return 255
    fi

  else

    SRC="${LOCAL_SPEC}"
    DST="${REMOTE_SPEC}"
    LABEL_FROM="${LOCAL_SPEC}"
    LABEL_TO="${REMOTE_LABEL}"
  fi

  ## rsync filter rules are FIRST MATCH WINS, so every --include must come before the
  ## --exclude it carves an exception out of.
  ## logs are excluded by default (webapp mirroring); "with-logs" mirrors them too
  local -a LOG_FILTER_OPT=(
    --include 'var/log/.gitignore'  --exclude 'var/log/**'
    --include 'var/logs/.gitignore' --exclude 'var/logs/**'
    --exclude '*.log' --exclude '*.log.[0-9]*'
  )

  if [ "${WITH_LOGS_OPT}" = "with-logs" ]; then

    LOG_FILTER_OPT=()
  fi

  ## "fast" skips the subtrees that typically dwarf the codebase itself: bulk uploaded
  ## content and regenerable build artifacts. Those often live on another filesystem
  ## too, and rsync crosses mount points (we pass no --one-file-system), so a plain
  ## mirror can pull far more than the source host's own disk even holds.
  local -a FAST_FILTER_OPT=()
  if [ "${FAST_OPT}" = "fast" ]; then

    FAST_FILTER_OPT=(
      --exclude 'pub/media/**'          --exclude 'var/import/**'
      --exclude 'var/report/**'         --exclude 'generated/code/**'
      --exclude 'wp-content/uploads/**'
      --exclude '*.pdf'
    )
  fi

  ## live progress on a terminal, a quiet summary under cron
  local -a PROGRESS_OPT=( --stats )
  if [ -t 1 ]; then

    PROGRESS_OPT=( --info=progress2 --human-readable )
  fi

  ## --compress is zstd since rsync 3.2: it compresses far faster than any uplink we
  ## mirror over, so it's free bandwidth on the text we move (PHP, JS, configs, dumps).
  ## Never pair it with ssh's own `Compression yes`: that would compress twice.
  local -a RSYNC_FULL_COMMAND=(
    rsync
    "${ARCHIVE_OPT[@]}"
    -e "${SSH_TRANSPORT}"
    --compress
    "${SUDO_OPT[@]}"
    --delete --delete-excluded
    "${PROGRESS_OPT[@]}"
    "${FAST_FILTER_OPT[@]}"
    "${LOG_FILTER_OPT[@]}"
    --include 'var/cache/.gitignore'    --exclude 'var/cache/**'
    --include 'var/tmp/.gitignore'      --exclude 'var/tmp/**'
    --include 'var/session/.gitignore'  --exclude 'var/session/**'
    --include 'var/sessions/.gitignore' --exclude 'var/sessions/**'
    "${SRC}"
    "${DST}"
  )

  echo "From: ${LABEL_FROM}"
  echo "To:   ${LABEL_TO}"

  if [ "${FAST_OPT}" = "fast" ]; then

    echo "Mode: ⚡ fast - skipping pub/media, var/import, var/report, generated/code, wp-content/uploads, *.pdf"
  fi

  echo ""

  if [ "${DELAY_OPT}" != "no-delay" ]; then

    echo "${RSYNC_FULL_COMMAND[@]}"
    echo ""
    fxCountdown
  fi

  local RSYNC_EXIT_CODE=0
  "${RSYNC_FULL_COMMAND[@]}"
  RSYNC_EXIT_CODE=$?

  ## 24 = "some files vanished before they could be transferred": business as usual
  ## when mirroring a live server, not a failure
  if [ "${RSYNC_EXIT_CODE}" -eq 24 ]; then

    fxWarning "Some files vanished on the source during the mirror: they'll be picked up next run"
    return 0
  fi

  return "${RSYNC_EXIT_CODE}"
}
