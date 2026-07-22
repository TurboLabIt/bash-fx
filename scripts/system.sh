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
