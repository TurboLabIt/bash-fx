#!/usr/bin/env bash
SCRIPT_NAME=$1

if [ -z "$(command -v curl)" ] || [ -z "$(command -v nano)" ] || [ -z "$(command -v dialog)" ]; then
  sudo apt update && sudo apt install curl nano dialog -y
fi

## bash-fx
if [ -f "/usr/local/turbolab.it/bash-fx/bash-fx.sh" ]; then
  source "/usr/local/turbolab.it/bash-fx/bash-fx.sh" 
else
  source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)
fi
## bash-fx is ready

fxHeader "💽 ${SCRIPT_NAME} setup script"

fxTitle "Suppress needrestart..."
if [ -d "/etc/needrestart/conf.d/" ]; then

  sudo curl -Lo /etc/needrestart/conf.d/zzupdate-needrestart-suppress.conf \
    https://raw.githubusercontent.com/TurboLabIt/zzupdate/master/needrestart-suppress.conf
else

  fxInfo "Not installed"
fi

if [ -z "$(command -v git)" ]; then
  sudo apt update && sudo apt install git -y
fi

## /etc/ config directory
mkdir -p "/etc/turbolab.it/"

## Install/update
echo ""
if [ ! -d "$INSTALL_DIR" ]; then

  fxTitle "💽 Installing..."
  mkdir -p "$INSTALL_DIR_PARENT"
  cd "$INSTALL_DIR_PARENT"
  git clone --depth 1 https://github.com/TurboLabIt/${SCRIPT_NAME}.git

  cd "$INSTALL_DIR"

else

  fxTitle "⏬ Updating..."
  cd "$INSTALL_DIR"

  ## trust the repo for the git commands below only: root may not own it (dev boxes), and
  ## "config --global --add" would append a duplicate line to root's .gitconfig on every run
  export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0="${INSTALL_DIR%/}"

  # Force SSH to prompt on the real terminal, not a hidden GUI dialog: under sudo-rs
  # DISPLAY is inherited (=:0), which can divert the host-key prompt to a graphical
  # askpass and leave the terminal frozen at "Updating...". Bound the connect too.
  SSH_ASKPASS_REQUIRE=never \
  GIT_SSH_COMMAND="ssh -o ConnectTimeout=15" \
  git fetch --depth 1 < /dev/tty \
    || fxCatastrophicError "Can't fetch ${SCRIPT_NAME} from $(git remote get-url origin) — if it's an SSH remote, root has no GitHub key/known_hosts. Use an HTTPS 'origin' or give root a key."

  git reset --hard @{upstream}

  fxTitle "🗜️ Pruning..."
  git gc --prune=all
fi
