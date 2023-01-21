#!/usr/bin/env bash

function fxGetCurrentIpAddress()
{
  fxTitle "🧭 Acquiring the current IP address..."

  FX_CURRENT_IP_ADDRESS=$(curl -s v4.ident.me)

  if [ "$?" != 0 ] || [ -z "$FX_CURRENT_IP_ADDRESS" ]; then

    FX_CURRENT_IP_ADDRESS=""
    fxCatastrophicError "fxGetCurrentIpAddress: unable to retrieve the current IP address"
  fi

  fxMessage "The current IP address is ##${FX_CURRENT_IP_ADDRESS}##"
}


function fxCheckIpAddressChanged()
{
  fxTitle "🧭 Checking if the IP address has changed..."

  fxGetCurrentIpAddress
  FX_NEW_IP_ADDRESS=${FX_CURRENT_IP_ADDRESS}


  fxTitle "IP file..."
  if [ -z "$1" ]; then
    FX_IP_ADDRESS_FILE=/tmp/zzddns-last-ip-address.txt
  else
    FX_IP_ADDRESS_FILE="/tmp/zzddns-last-ip-address-$1.txt"
  fi

  fxInfo "Working on IP file ##${FX_IP_ADDRESS_FILE}##"


  fxTitle "Checking if the IP file exists..."
  if [ ! -f "$FX_IP_ADDRESS_FILE" ]; then

    fxWarning "IP file ##${FX_IP_ADDRESS_FILE}## not found. The IP address should be considered as changed"

    ## create the file with permissive permissions
    touch "${FX_IP_ADDRESS_FILE}"
    chmod ugo=rw "${FX_IP_ADDRESS_FILE}"
    return 1

  else

    fxOK "Yes, the IP file ##${FX_IP_ADDRESS_FILE}## exists"
  fi


  fxTitle "Checking if the IP file is too old..."
  if [ $(find "$FX_IP_ADDRESS_FILE" -mmin +90 -print) ]; then

    fxWarning "The IP file ##${FX_IP_ADDRESS_FILE}## is pretty old. The IP address should be considered as changed"
    return 1

  else

    fxOK "The IP file ##${FX_IP_ADDRESS_FILE}## is recent"
  fi


  fxTitle "Acquiring the last know IP address from ##${FX_IP_ADDRESS_FILE}##..."
  FX_LAST_KNOWN_IP_ADDRESS=$(<"${FX_IP_ADDRESS_FILE}")
  fxInfo "The last know IP address is ##$FX_LAST_KNOWN_IP_ADDRESS##"
  
  
  fxTitle "Comparing IP addresses..."
  echo "Last know (from file):    ##${FX_LAST_KNOWN_IP_ADDRESS}##"
  echo "Current:                  ##${FX_CURRENT_IP_ADDRESS}##"

  if [ "$FX_CURRENT_IP_ADDRESS" = "$FX_LAST_KNOWN_IP_ADDRESS" ]; then

    fxOK "The IP address is still the same"
    FX_NEW_IP_ADDRESS=""
    return 0
  fi

  echo ""
  fxMessage "💱 The IP address HAS CHANGED!"
  return 1
}

