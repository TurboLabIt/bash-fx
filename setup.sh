#!/usr/bin/env bash
SCRIPT_NAME=bash-fx

sudo apt update && sudo apt install curl -y

## begin
curl -o /tmp/bash-fx-setup-begin.sh -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/setup/start.sh
sudo bash /tmp/bash-fx-setup-begin.sh ${SCRIPT_NAME}

## end
curl -o /tmp/bash-fx-setup-end.sh -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/setup/the-end.sh
sudo bash /tmp/bash-fx-setup-end.sh ${SCRIPT_NAME}

## cleanup
sudo rm -f /tmp/bash-fx-setup*.sh
