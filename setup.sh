#!/usr/bin/env bash
SCRIPT_NAME=bash-fx

## zzupdate & friends run several setup.sh back-to-back, each re-updating bash-fx: skip if freshly fetched
if [ -n "$(find /usr/local/turbolab.it/bash-fx/.git/FETCH_HEAD -mmin -2 2>/dev/null)" ]; then

  echo "🐇 bash-fx was updated less than 2 minutes ago, skipping"
  exit 0
fi

if [ -z $(command -v curl) ]; then sudo apt update && sudo apt install curl -y; fi

## begin
curl -o /tmp/bash-fx-setup-begin.sh -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/setup/start.sh
sudo bash /tmp/bash-fx-setup-begin.sh ${SCRIPT_NAME}

## end
curl -o /tmp/bash-fx-setup-end.sh -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/setup/the-end.sh
sudo bash /tmp/bash-fx-setup-end.sh ${SCRIPT_NAME}

## cleanup
sudo rm -f /tmp/bash-fx-setup*.sh
