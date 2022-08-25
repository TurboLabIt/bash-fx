#!/usr/bin/env bash

if [ -z "$TIME_START" ]; then
  TIME_START="$(date +%s)"
  DOWEEK="$(date +'%u')"
fi


function fxCountdown()
{
  if [ -z "${1}" ]; then
    local TIMEOUT=10
  else
    local TIMEOUT=${1}
  fi

  while [ "$TIMEOUT" -gt 0 ]; do

    echo -ne "\e[1;33m⏳ ${TIMEOUT}\e[0m"
    sleep 1
    : $((TIMEOUT--))

  done
}

