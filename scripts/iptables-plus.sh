#!/usr/bin/env bash

function fxIptablesChainExists()
{
  local CHAIN_NAME=$1
  local SILENT_MODE=$2
  
  if [ -z "$SILENT_MODE" ]; then
   fxTitle "🔗 Checking if the iptables chain $CHAIN_NAME exists..."
  fi
  
  iptables -nL "$CHAIN_NAME" >/dev/null 2>&1
  local CHAIN_EXISTS=$?

  if [ "$CHAIN_EXISTS" = 0 ] && [ -z "$SILENT_MODE" ]; then
    fxMessage "✔️ The chain exists"
  elif [ -z "$SILENT_MODE" ]; then
    fxMessage "🕳️ The chain doesn't exists"
  fi
  
  return $CHAIN_EXISTS
}


function fxIptablesCreateChainIfNotExists()
{
  local CHAIN_NAME=$1
  local SILENT_MODE=$2
  
  fxIptablesChainExists "$CHAIN_NAME" "$SILENT_MODE"
  local CHAIN_EXISTS=$?
  
  if [ "$CHAIN_EXISTS" != 0 ] && [ -z "$SILENT_MODE" ]; then
    echo ""
    fxMessage "🆕 Creating the chain..."
  fi
  
  if [ "$CHAIN_EXISTS" != 0 ]; then
    iptables -N "$CHAIN_NAME"
  fi
  
  if [ "$CHAIN_EXISTS" != 0 ] && [ -z "$SILENT_MODE" ]; then
    iptables -nL "$CHAIN_NAME"
  fi
}
