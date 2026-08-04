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

  REMOTE_URL=$(git remote get-url origin 2>/dev/null)

  # Force SSH to prompt on the real terminal, not a hidden GUI dialog: under sudo-rs
  # DISPLAY is inherited (=:0), which can divert the host-key prompt to a graphical
  # askpass and leave the terminal frozen at "Updating...". Bound the connect too.
  SSH_ASKPASS_REQUIRE=never \
  GIT_SSH_COMMAND="ssh -o ConnectTimeout=15" \
  git fetch --depth 1 < /dev/tty || {

    # blame what actually broke: only an SSH remote can fail on root's missing key,
    # an HTTPS one fails on connectivity/DNS (and git already printed the real reason)
    if [[ "$REMOTE_URL" =~ ^(ssh://|[^/]+@[^/]+:) ]]; then
      fxCatastrophicError "Can't fetch ${SCRIPT_NAME} from ${REMOTE_URL} — it's an SSH remote and root has no GitHub key/known_hosts. Use an HTTPS 'origin' or give root a key."
    else
      fxCatastrophicError "Can't fetch ${SCRIPT_NAME} from ${REMOTE_URL} — check connectivity/DNS, see git's error above."
    fi
  }

  git reset --hard @{upstream}

  fxTitle "🗜️ Pruning..."
  git gc --prune=all
fi

## exec-bit changes on disk must never count as local modifications
git config core.fileMode false
