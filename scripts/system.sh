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

  if ! sudo apt-get update; then

    fxCatastrophicError "##apt update## failed" 0
    return 255
  fi

  fxOK "apt cache updated"
}
