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
## Run a command in background, detached, and return at once: the command outlives the calling script, its
## terminal and the SSH session which ran it (multissh, deploy scripts, ...). It runs as root, through sudo.
##
## $1: the job name, as a path with no extension. Everything about the job sits next to it, i.e. for
##     /run/bashfx-reboot:
##       /run/bashfx-reboot.pid        the pid of the job, written by the job itself as soon as it starts
##       /run/bashfx-reboot.log        whatever the job prints, stdout and stderr
##       /run/bashfx-reboot.exit-code  written only once the job is over. No exit code and no such process
##                                     anymore means it was killed, or the system went down under it
##     The files of a previous run of the same job are wiped first
##
## $2: the command line, run by the job's own shell and not by a child of it: in "sleep 60; reboot", killing
##     that shell while it sleeps is enough to call the reboot off. No "exit" in it: that would end the job
##     before its exit code is written. Run a script instead
##
## To stop the job AND whatever it started: sudo kill -- -$(cat <job>.pid)
##
## Why not a plain "(command) &": a background job stays in the process group of the script, and that group
## gets a SIGHUP when the script ends -- it IS the session leader when ssh ran it -- or when its terminal goes
## away. setsid moves the job into a session of its own, out of reach of both. In the foreground and waited
## for (-w), not "setsid ... &": the detached shell must exist BEFORE this returns, or its fork races the exit
## of the caller and loses (the SIGHUP lands before it detaches). No stream left pointing at the caller's: with
## no pty (plain ssh, cron, a pipe) the caller's ssh only returns once nothing holds its stdout/stderr anymore,
## so a job still attached to them would keep it hanging for as long as the job runs.
##
## "set -m" is there for the kill above: with job control on, the job gets a process group of its own, whose id
## is the job's pid. Whatever the job starts stays in that group, so "kill -- -<pid>" reaches all of it, where a
## plain "kill <pid>" stops the job's shell only and leaves the command it's running at that moment orphaned
##
function fxRunDetached()
{
  local JOB_NAME="$1"
  local JOB_COMMAND="$2"

  if [ -z "${JOB_NAME}" ] || [ -z "${JOB_COMMAND}" ]; then

    fxCatastrophicError "fxRunDetached: the job name and the command line are both required" no-exit
    return 1
  fi

  local JOB_PIDFILE="${JOB_NAME}.pid"

  ## the paths travel inside the "bash -c" script below: quoted for it
  local JOB_DIR_Q JOB_PIDFILE_Q JOB_LOG_Q JOB_EXIT_CODE_Q
  printf -v JOB_DIR_Q '%q' "$(dirname "${JOB_NAME}")"
  printf -v JOB_PIDFILE_Q '%q' "${JOB_PIDFILE}"
  printf -v JOB_LOG_Q '%q' "${JOB_NAME}.log"
  printf -v JOB_EXIT_CODE_Q '%q' "${JOB_NAME}.exit-code"

  ## the command line gets a line of its own: a trailing "&" or comment in it can't swallow the exit code line
  sudo setsid -w bash -c "
    mkdir -p ${JOB_DIR_Q}
    rm -f ${JOB_PIDFILE_Q} ${JOB_EXIT_CODE_Q}
    set -m
    (
      echo \$BASHPID > ${JOB_PIDFILE_Q}
      ${JOB_COMMAND}
      echo \$? > ${JOB_EXIT_CODE_Q}
    ) > ${JOB_LOG_Q} 2>&1 < /dev/null &
  "

  ## Nothing says the job really started until its pidfile shows up: the job writes it, and a redirection
  ## failing in there fails where this side can't see it
  local JOB_WAIT
  for JOB_WAIT in {1..50}; do

    if [ -s "${JOB_PIDFILE}" ]; then
      break
    fi

    sleep 0.1
  done

  if [ ! -s "${JOB_PIDFILE}" ]; then

    fxCatastrophicError "The ##${JOB_NAME}## job didn't start: no pidfile after 5 seconds" no-exit
    return 1
  fi

  fxOK "Running in background with pid ##$(cat "${JOB_PIDFILE}")##. Not waiting for it: this script goes on"
  fxInfo "Output: ##${JOB_NAME}.log## | exit code, once it's over: ##${JOB_NAME}.exit-code##"
  fxMessage "To stop it: sudo kill -- -\$(cat ${JOB_PIDFILE})"
}


##
## Reboot in $1 seconds (default: 60) without waiting for it: this returns at once, the calling script ends
## normally and the pending reboot outlives it, its terminal and the SSH session which ran it (see fxRunDetached).
## To cancel it: sudo kill $(cat /run/bashfx-reboot.pid)
##
## Unattended by design: no countdown, no confirmation. That's for the caller, when a human is watching
##
function fxRebootDelayed()
{
  local REBOOT_DELAY_SEC="${1:-60}"

  if ! [[ "$REBOOT_DELAY_SEC" =~ ^[0-9]+$ ]]; then

    fxWarning "The reboot delay must be an integer, got '${REBOOT_DELAY_SEC}': rebooting in 60 seconds"
    REBOOT_DELAY_SEC=60
  fi

  fxTitle "🔌 Rebooting in ${REBOOT_DELAY_SEC} seconds"

  ## nothing got scheduled: the caller must know it, i.e. multissh must flag the host
  fxRunDetached /run/bashfx-reboot "sleep ${REBOOT_DELAY_SEC}; reboot" || return 1

  fxInfo "The system will reboot at $(date -d "+${REBOOT_DELAY_SEC} seconds" +'%T')"
}


##
## Installed packages, one "package source-package" per line. Reads Dir::State::status: APT_CONFIG is honored
##
function fxAptInstalledPackages()
{
  local DPKG_STATUS
  eval "$(apt-config shell DPKG_STATUS Dir::State::status/f)"

  awk 'BEGIN { RS = ""; FS = "\n" } {
    NAME = ""; SOURCE = ""; INSTALLED = 0
    for (i = 1; i <= NF; i++) {
      if ($i ~ /^Package: /) { NAME = substr($i, 10) }
      else if ($i ~ /^Source: /) { SOURCE = substr($i, 9); sub(/ .*/, "", SOURCE) }
      else if ($i ~ /^Status: .* installed$/) { INSTALLED = 1 }
    }
    if (INSTALLED) { print NAME, (SOURCE == "" ? NAME : SOURCE) }
  }' "$DPKG_STATUS"
}
