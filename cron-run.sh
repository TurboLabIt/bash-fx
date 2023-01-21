#!/usr/bin/env bash
echo ""

source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"

CRON_RUN_SCRIPT_NAME=$1
CRON_RUN_SCRIPT_TO_RUN=$2
CRON_RUN_CRON_RUN_NO_ROOT_CHECK=$3
CRON_RUN_KEEP_FULL_LOG=$4
  
fxHeader "🕛 ${CRON_RUN_SCRIPT_NAME} cron (${CRON_RUN_SCRIPT_TO_RUN})"
  
if [ -z "${CRON_RUN_NO_ROOT_CHECK}" ]; then
  rootCheck
fi
  
fxMessage "The output is being redirect to a logfile, please wait..."

CRON_RUN_LOG_DIR="/var/log/turbolab.it/"
mkdir -p "${CRON_RUN_LOG_DIR}"
CRON_RUN_LOG_FILE=${CRON_RUN_LOG_DIR}${CRON_RUN_SCRIPT_NAME}-${CRON_RUN_SCRIPT_TO_RUN}_cron.log
  
if [ -z "${CRON_RUN_NO_ROOT_CHECK}" ]; then

  chmod ugo= "${CRON_RUN_LOG_DIR}"
  chmod ugo=rwX "${CRON_RUN_LOG_DIR}"
  chmod ugo=rw "${CRON_RUN_LOG_FILE}"
fi

 
if [ -z "${CRON_RUN_KEEP_FULL_LOG}" ]; then

  bash "/usr/local/turbolab.it/${CRON_RUN_SCRIPT_NAME}/${CRON_RUN_SCRIPT_TO_RUN}" "$1" >> "${CRON_RUN_LOG_FILE}" 2>&1
  fxTitle "${CRON_RUN_LOG_FILE}"
  fxWarning "Only the last 1.000 lines are shown"
  tail -1000 "${CRON_RUN_LOG_FILE}"
  
else

  bash "/usr/local/turbolab.it/${CRON_RUN_SCRIPT_NAME}/${CRON_RUN_SCRIPT_TO_RUN}" "$1" > "${CRON_RUN_LOG_FILE}" 2>&1
  fxTitle "${CRON_RUN_LOG_FILE}"
  cat ${CRON_RUN_LOG_FILE}

fi

