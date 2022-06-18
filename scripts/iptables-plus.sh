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


function fxIptablesCheckEmptyChain()
{
  local CHAIN_NAME=$1
  local SILENT_MODE=$2
  
  fxIptablesChainExists "$CHAIN_NAME" "$SILENT_MODE"
  local CHAIN_EXISTS=$?
  
  if [ "$CHAIN_EXISTS" != 0 ]; then
    return 255
  fi


  local CHAIN_RULES=$(iptables -S "$CHAIN_NAME" | grep -v "\-N $CHAIN_NAME")
  
  
  if [ -z "$CHAIN_RULES" ] && [ -z "$SILENT_MODE" ]; then
    echo ""
    fxMessage "🕳️ The chain $CHAIN_NAME is empty"
    return 255
  fi
  
  if [ -z "$CHAIN_RULES" ]; then
    return 255
  fi
  
  
  if [ -z "$SILENT_MODE" ]; then
    echo ""
    fxMessage "✔️ The chain is not empty"
    return 0
  fi
  
  return 0
}


function fxOpenPort()
{
  local PORT_NUMBER=$1
  local COMMENT=$2
  local PROTOCOL=$3
  local SILENT_MODE=$4
  
  if [ -z "$PROTOCOL" ]; then
    PROTOCOL=tcp
  fi
  
  if [ -z "$SILENT_MODE" ]; then
   fxMessage "${COMMENT}"
  fi
  
  iptables -A INPUT -p "$PROTOCOL" --dport "${PORT_NUMBER}" -j ACCEPT -m comment --comment "${COMMENT}"
}

