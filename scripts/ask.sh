function fxAskConfirmation()
{
  if [ ! -z "$1" ]; then
    local CONFIRM_MESSAGE=$1
  else
    local CONFIRM_MESSAGE="Proceed? [Y/N]"
  fi

  fxWarning "$CONFIRM_MESSAGE"

  if [ -t 0 ]; then

    # Running in a terminal, interactively ask for confirmation
    read -p ">> " -n 1 -r < /dev/tty
    echo
    if [[ ! "$REPLY" =~ ^[Yy1]$ ]]; then
      fxCatastrophicError "Aborted by user"
    fi
    
  else
  
    # Not running in a terminal (e.g., via cron), proceed automatically
    fxWarning "No terminal detected (non-interactive environment). Proceeding automatically."
  fi
}
