#!/usr/bin/env bash
SCRIPT_NAME=bash-fx

## stop needrestart https://askubuntu.com/a/1421221/181869
if [ -e "/etc/needrestart/needrestart.conf" ]; then
  sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
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
