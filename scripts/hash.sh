#!/usr/bin/env bash

function fxHashFile
{
  md5sum "${1}" | awk '{ print $1 }'
}


function fxSelfUpdateHashCheck()
{
  if [ "${1}" != "${2}" ]; then
    catastrophicError "🔃 The script itself has been updated! Please run it again!"
    exit
  fi
}
