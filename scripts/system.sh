#!/usr/bin/env bash

function fxHostnameRename()
{
  local NEW_HOSTNAME=$1
  local OLD_HOSTNAME="$(hostname)"

  if [ -z "$NEW_HOSTNAME" ]; then

    fxTitle "📛 Enter the new hostname"
    fxInfo "For example: appname-prd - avoid dots and real DNS names"
    while [ -z "$NEW_HOSTNAME" ]; do

      echo "🤖 Provide the new hostname"
      read -p ">> " NEW_HOSTNAME < /dev/tty
    done
  fi

  NEW_HOSTNAME="${NEW_HOSTNAME,,}"
  fxTitle "Renaming the system to ##${NEW_HOSTNAME}##..."

  sudo hostnamectl set-hostname "${NEW_HOSTNAME}"

  ## setting ##${NEW_HOSTNAME}## as the first line of /etc/hosts..."
  sudo sed -i -E "/^127\.0\.1\.1[[:space:]]/d; /^127\.0\.0\.1[[:space:]]+${NEW_HOSTNAME}$/d" /etc/hosts

  ## drop the previous name's loopback entry too, but never nuke the real 'localhost' line
  if [ -n "$OLD_HOSTNAME" ] && [ "$OLD_HOSTNAME" != "localhost" ]; then
    sudo sed -i -E "/^127\.0\.0\.1[[:space:]]+${OLD_HOSTNAME}$/d" /etc/hosts
  fi
  sudo sed -i "1i 127.0.0.1\t${NEW_HOSTNAME}" /etc/hosts

  local CURRENT_HOSTNAME="$(hostname)"
  fxOK "Done. The current, updated hostname is: ##${CURRENT_HOSTNAME}##"

  ## a shell caches the hostname in its prompt (\h) at login, so already-open shells stay stale
  fxInfo "Run 'exec bash' (or re-login) to refresh your shell prompt"
}


function fxAptUpdate()
{
  ## refresh the apt cache, but only if it's older than $1 minutes (default: 15)
  ## pass 0 to force it: mandatory right after adding a new repo!
  local MAX_AGE_MINUTES="${1:-15}"

  ## apt has no built-in "update only if stale" option, so we look at the cache's mtime.
  ## pkgcache.bin is rebuilt by apt itself on every successful update
  ## (/var/lib/apt/periodic/update-success-stamp would be stricter, but it's touched by a hook
  ## shipped with update-notifier-common, which is missing on minimal servers and in containers)
  local APT_CACHE_FILE=/var/cache/apt/pkgcache.bin

  if [ "$MAX_AGE_MINUTES" -gt 0 ] && [ -f "$APT_CACHE_FILE" ] &&
     [ -n "$(find "$APT_CACHE_FILE" -maxdepth 0 -mmin "-${MAX_AGE_MINUTES}" 2>/dev/null)" ]; then

    fxInfo "The apt cache is younger than ${MAX_AGE_MINUTES} min: skipping ##apt update##"
    return 0
  fi

  fxTitle "📦 Updating the apt cache..."

  ## -qq: warnings and errors only
  ## short timeouts + 1 retry: an unreachable mirror makes apt retry silently for minutes, which looks like a freeze
  if ! sudo apt-get update -qq -o Acquire::Retries=1 -o Acquire::http::Timeout=20 -o Acquire::https::Timeout=20; then

    fxCatastrophicError "##apt update## failed" 0
    return 255
  fi

  fxOK "apt cache updated"
}


##
## Reboot in $1 seconds (default: 60) without waiting for it: this returns at once, the calling script
## ends normally and the pending reboot outlives it, its terminal and the SSH session which ran it
## (multissh, deploy scripts, ...). To cancel it: sudo kill $(cat /run/bashfx-reboot.pid)
##
## Why not a plain "(sleep N; reboot) &": a background job stays in the process group of the script, and
## that group gets a SIGHUP when the script ends -- it IS the session leader when ssh ran it -- or when its
## terminal goes away. setsid moves the wait into a session of its own, out of reach of both. In the
## foreground and waited for (-w), not "setsid ... &": the detached shell must exist BEFORE this returns,
## or its fork races the exit of the caller and loses (the SIGHUP lands before it detaches). Every stream
## to /dev/null: with no pty (plain ssh, cron, a pipe) the caller's ssh only returns once nothing holds its
## stdout/stderr anymore, so a wait still attached to them would keep it hanging for the whole delay.
##
## Unattended by design: no countdown, no confirmation. That's for the caller, when a human is watching
##
function fxRebootDelayed()
{
  local REBOOT_DELAY_SEC="${1:-60}"
  local REBOOT_PIDFILE=/run/bashfx-reboot.pid

  if ! [[ "$REBOOT_DELAY_SEC" =~ ^[0-9]+$ ]]; then

    fxWarning "The reboot delay must be an integer, got '${REBOOT_DELAY_SEC}': rebooting in 60 seconds"
    REBOOT_DELAY_SEC=60
  fi

  fxTitle "🔌 Rebooting in ${REBOOT_DELAY_SEC} seconds"

  ## $BASHPID is the pid of the detached subshell, the one to kill to call it off ($$ would be its parent, gone at once)
  sudo setsid -w bash -c "( echo \$BASHPID > '${REBOOT_PIDFILE}'; sleep ${REBOOT_DELAY_SEC}; reboot ) > /dev/null 2>&1 < /dev/null &"

  fxInfo "The system will reboot at $(date -d "+${REBOOT_DELAY_SEC} seconds" +'%T'). Not waiting for it: the wait runs in background, this script goes on"
  fxMessage "To cancel it: sudo kill \$(cat ${REBOOT_PIDFILE})"
}
