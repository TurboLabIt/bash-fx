#!/usr/bin/env bash

## fxStringToArray <array-name> <string>
## Explodes a whitespace-separated list (spaces, tabs, newlines - runs of them included, so the
## backslash-newline continued strings of the config files work too) into the named array, skipping the blanks.
## The array is (re)created from scratch: an empty or blank string leaves it empty.
##   fxStringToArray MY_ARRAY "${MY_LIST}"
function fxStringToArray()
{
  if [[ ! "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    fxCatastrophicError "fxStringToArray: ##$1## is not a valid array name!"
  fi

  local -n FX_STRING_TO_ARRAY_REF=$1

  ## `-d ''` reads up to a NUL, i.e. the whole here-string (newlines included): it "fails" with 1 at the
  ## end of the input, but the words are assigned anyway
  read -r -d '' -a FX_STRING_TO_ARRAY_REF <<< "$2"

  return 0
}


## fxInArray <needle> <item>...
## Exact-match search of a value in a list, typically an expanded array. An empty list never matches.
##   if fxInArray "${ITEM}" "${MY_ARRAY[@]}"; then ...
function fxInArray()
{
  local NEEDLE=$1
  shift

  local ITEM
  for ITEM in "$@"; do
    if [ "${ITEM}" = "${NEEDLE}" ]; then
      return 0
    fi
  done

  return 1
}
