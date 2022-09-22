function fxAskDeployConfirmation()
{
  if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
    fxCatastrophicError "PROJECT_DIR is undefined. This deploy can't proceed! Aborting!"
  fi
  
  if [ -z "$APP_ENV" ]; then
    fxCatastrophicError "APP_ENV is undefined! This deploy can't proceed! Aborting!"
  fi

  if [ "$APP_ENV" = "prod" ]; then

    fxTitle '⚡⚡ You are about to deploy ${APP_NAME} on PRODUCTION ($HOSTNAME) ⚡⚡'
    local options=("OK" "Cancel")
    select opt in "${options[@]}"
    do
      case $opt in

        "OK")
          if [ -f ${SCRIPT_DIR}deploy_notify.sh ]; then
            bash ${SCRIPT_DIR}notify.sh "🏁 Deploy started for ${APP_NAME} on PRODUCTION ($HOSTNAME)" "deploy" "$1"
          fi
          break
          ;;

        "Cancel")
          if [ -f "${SCRIPT_DIR}script_end.sh" ]; then
            source ${SCRIPT_DIR}script_end.sh
          fi
          exit
          ;;

        *) echo "👎🏻 Invalid option";;
      esac
    done

  fi
}
