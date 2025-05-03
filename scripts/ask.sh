function fxAskConfirmation()
{
  if [ ! -z "$1" ]; then
    local CONFIRM_MESSAGE=$1
  else
    local CONFIRM_MESSAGE="Proceed? [Y/N]"
  fi

  fxWarning "$CONFIRM_MESSAGE"
  read -p ">> " -n 1 -r  < /dev/tty
  if [[ ! "$REPLY" =~ ^[Yy1]$ ]]; then
    fxCatastrophicError "Aborted by user"
  fi
}
