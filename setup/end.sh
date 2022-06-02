#!/usr/bin/env bash
echo ""

${SCRIPT_NAME}=$1

## bash-fx
if [ -f "/usr/local/turbolab.it/bash-fx/bash-fx.sh" ]; then
  source "/usr/local/turbolab.it/bash-fx/bash-fx.sh" 
else
  source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)
fi
## bash-fx is ready

printTitle "✅ ${SCRIPT_NAME} setup script DONE!"
printMessage "See https://github.com/TurboLabIt/${SCRIPT_NAME} for the quickstart guide."

