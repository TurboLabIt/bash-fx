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


## fxDotEnvSet <file> <KEY> <value>
## Sets KEY=value in an env-style file (.env, /etc/default/*, ...): the active `KEY=` line is replaced,
## a recipe-style commented-out `# KEY=` one is uncommented in place (the first only: the others are
## alternative examples), and a missing key is appended. The value is written verbatim: quote it yourself
## if the format requires it
function fxDotEnvSet()
{
  local ENV_FILE=$1
  local ENV_KEY=$2
  local ENV_VALUE=$3

  if [ ! -f "${ENV_FILE}" ]; then
    fxCatastrophicError "fxDotEnvSet: ##${ENV_FILE}## is not a file!"
  fi

  if [[ ! "${ENV_KEY}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    fxCatastrophicError "fxDotEnvSet: ##${ENV_KEY}## is not a valid variable name!"
  fi

  local ENV_LINE="${ENV_KEY}=${ENV_VALUE}"
  ## sed replacement: escape the | delimiter, the backslash and the "whole match" &
  local SED_REPLACEMENT=$(printf '%s' "${ENV_LINE}" | sed -E 's/[\\|&]/\\&/g')

  if grep -qE "^${ENV_KEY}=" "${ENV_FILE}"; then

    sed -i -E "s|^${ENV_KEY}=.*|${SED_REPLACEMENT}|" "${ENV_FILE}"
    fxOK "##${ENV_KEY}## replaced in ##${ENV_FILE}##"

  elif grep -qE "^#[[:space:]]*${ENV_KEY}=" "${ENV_FILE}"; then

    sed -i -E "0,/^#[[:space:]]*${ENV_KEY}=/{s|^#[[:space:]]*${ENV_KEY}=.*|${SED_REPLACEMENT}|}" "${ENV_FILE}"
    fxOK "##${ENV_KEY}## uncommented in ##${ENV_FILE}##"

  else

    ## the file may not end with a newline
    if [ -s "${ENV_FILE}" ] && [ ! -z "$(tail -c1 "${ENV_FILE}")" ]; then
      echo "" >> "${ENV_FILE}"
    fi

    echo "${ENV_LINE}" >> "${ENV_FILE}"
    fxOK "##${ENV_KEY}## appended to ##${ENV_FILE}##"
  fi
}
