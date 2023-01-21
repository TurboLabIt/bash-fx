#!/usr/bin/env bash

function fxGetCurrentIpAddress()
{
  local SILENT=$1
  
  if [ -z "${SILENT}" ]; then
    fxTitle "🧭 Acquiring the current IP address..."
  fi
  
  
  local MY_IP=$(curl -s v4.ident.me)
  
  
  if [ "$?" != 0 ] || [ -z "$MY_IP" ]; then
    fxCatastrophicError "fxGetCurrentIpAddress: unable to retrieve the current IP address"
  fi
  
  
  if [ -z "${SILENT}" ]; then
    fxOK "The current IP address is ##${MY_IP}##"
  else
    echo "${MY_IP}"
  fi
}


function fxCheckIpAddressChanged()
{
  local SILENT=$2
  
  if [ -z "${SILENT}" ]; then
    fxTitle "🧭 Checking if IP address changed..."
  fi
  
  
  if [ -z "$1" ]; then
    local IP_FILE="/tmp/$1"
  else
    local IP_FILE=/tmp/last-ip-address.txt
  fi
  
  
  if [ -z "${SILENT}" ]; then
    fxInfo "Working on IP file ##${IP_FILE}##"
  fi


  local CURRENT_IP=$(fxGetCurrentIpAddress "silent")
  
  
  if [ -z "${SILENT}" ]; then
    fxOK "The current IP address is ##${CURRENT_IP}##"
  fi


  if [ ! -f "$IP_FILE" ]; then
  
    touch "${IP_FILE}"
    chmod ugo=rw "${IP_FILE}"
    echo "${CURRENT_IP}" > "${IP_FILE}"
  
    if [ -z "${SILENT}" ]; then
      fxWarning "IP file ##${IP_FILE}## was not found. IP should be considered as changed"
    else
      echo "${CURRENT_IP}"
    fi
  
    return 0
  fi

  
  if [ $(find "$CURRENT_IP" -mmin +90 -print) ]; then
  
    echo "${CURRENT_IP}" > "${IP_FILE}"
  
    if [ -z "${SILENT}" ]; then
      fxWarning "IP file ##${IP_FILE}## was pretty old. IP should be considered as changed"
    else
      echo "${CURRENT_IP}"
    fi
  
    return 0
  fi


  local LAST_KNOWN_IP=$(<"${IP_FILE}")


  if [ "$CURRENT_IP" = "$LAST_KNOWN_IP" ]; then
  
    if [ -z "${SILENT}" ]; then
      fxOK "IP address is still the same"
    else
      echo ""
    fi

    return 0
  fi
  
  
  ## IP has changed
  echo "${CURRENT_IP}" > "${IP_FILE}"
  echo "${CURRENT_IP}"
  return 0
}
