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
  
  FX_NEW_IP_ADDRESS=""
  fxGetCurrentIpAddress
  
  
  fxTitle "IP file..."
  if [ -z "$1" ]; then
    local IP_FILE="/tmp/$1"
  else
    local IP_FILE=/tmp/last-ip-address.txt
  fi
  
  fxInfo "Working on IP file ##${IP_FILE}##"


  fxTitle "Checking if the IP file exists..."
  if [ ! -f "$IP_FILE" ]; then
  
    fxWarning "IP file ##${IP_FILE}## not found. The IP address should be considered as changed"
    FX_NEW_IP_ADDRESS=${FX_CURRENT_IP_ADDRESS}
    
    ## create the file with permissive permissions
    touch "${IP_FILE}"
    chmod ugo=rw "${IP_FILE}"
    
    return 1
    
  else
  
    fxOK "Yes, the IP file ##${IP_FILE}## exists"
  fi

  
  fxTitle "Checking if the IP file is too old..."
  if [ $(find "$IP_FILE" -mmin +90 -print) ]; then
  
    fxWarning "The IP file ##${IP_FILE}## is pretty old. The IP address should be considered as changed"
    FX_NEW_IP_ADDRESS=${FX_CURRENT_IP_ADDRESS}
    return 1
    
  else
    
    fxOK "The IP file ##${IP_FILE}## is recent"
  fi

  
  fxTitle "Acquiring the last know IP address from ##${IP_FILE}##..."
  FX_LAST_KNOWN_IP_ADDRESS=$(<"${IP_FILE}")
  fxInfo "The last know IP address is $FX_LAST_KNOWN_IP_ADDRESS"


  if [ "$FX_CURRENT_IP_ADDRESS" = "$FX_LAST_KNOWN_IP_ADDRESS" ]; then
  
    fxOK "The IP address is still the same"
    return 0
  fi

  fxMessage "💱 The IP address HAS CHANGED!"
  return 1
}

