## Ask a yes/no question. Returns 0 for yes, 1 for no
## $1: the question | $2: the answer to a bare Enter (default: Y)
## Usage: if fxAskYesNo "Do you want Twig?"; then ... fi
function fxAskYesNo()
{
  if [ ! -z "$1" ]; then
    local QUESTION=$1
  else
    local QUESTION="Proceed?"
  fi

  local DEFAULT_ANSWER=Y
  if [[ "$2" =~ ^[Nn]$ ]]; then
    DEFAULT_ANSWER=N
  fi

  local HINT="[Y/n]"
  if [ "${DEFAULT_ANSWER}" = N ]; then
    HINT="[y/N]"
  fi

  fxWarning "${QUESTION} ${HINT}"

  ## Not running in a terminal (e.g. via cron): don't hang on read, go with the default
  if [ ! -t 0 ]; then

    fxWarning "No terminal detected (non-interactive environment). Assuming ##${DEFAULT_ANSWER}##"
    [ "${DEFAULT_ANSWER}" = Y ]
    return
  fi

  local REPLY
  while true; do

    read -p ">> " -n 1 -r REPLY < /dev/tty
    echo

    ## a bare Enter selects the default
    if [ -z "$REPLY" ]; then
      REPLY=${DEFAULT_ANSWER}
    fi

    case "$REPLY" in
      [Yy]) return 0 ;;
      [Nn]) return 1 ;;
      *) fxWarning "Please answer Y or N" ;;
    esac
  done
}


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
