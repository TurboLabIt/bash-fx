#!/usr/bin/env bash

function fxReplaceContentInDirectory()
{
  if [ ! -d "$1" ]; then
    fxCatastrophicError "fxReplaceContentInDirectory: ##$1## is not a directory!"
  fi

  if [ -z "$2" ]; then
    fxCatastrophicError "fxReplaceContentInDirectory: content to replace ##$2## is undefined!"
  fi

  find "$1" \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i "s|$2|$3|g"
}


function fxAlphanumOnly()
{
  echo "${1}" | tr -cd '[:alnum:]'
}


function fxTrim()
{
  local INPUT_STRING=$1

  local TRIMMED_STRING="${INPUT_STRING#"${INPUT_STRING%%[![:space:]]*}"}"
  local TRIMMED_STRING="${TRIMMED_STRING%"${TRIMMED_STRING##*[![:space:]]}"}"
  
  echo "${TRIMMED_STRING}"
}
