#!/usr/bin/env bash
echo ""

if [ -z "$(command -v curl)" ]; then
  sudo apt update && sudo apt install curl -y
fi

SCRIPT_NAME=bash-fx

## begin
curl -o /tmp/bash-fx-setup-begin.sh -s https://raw.github.com/TurboLabIt/bash-fx/setup/begin.sh
sudo bash /tmp/bash-fx-setup-begin.sh ${SCRIPT_NAME}

## end
curl -o /tmp/bash-fx-setup-end.sh -s https://raw.github.com/TurboLabIt/bash-fx/setup/end.sh
sudo bash /tmp/bash-fx-setup-end.sh ${SCRIPT_NAME}

## cleanup
sudo rm -f /tmp/bash-fx-setup*.sh

