#!/usr/bin/env bash

## fxStringToArray <array-name> <string> [separator]
## Explodes a whitespace-separated list (spaces, tabs, newlines - runs of them included, so the
## backslash-newline continued strings of the config files work too) into the named array, skipping the blanks.
## The array is (re)created from scratch: an empty or blank string leaves it empty.
## A separator (one character, i.e. ",") splits on that alone instead, taking every item as it is - a path with
## a space in it survives - and skipping only the empty ones: "a,,b," gives two items.
##   fxStringToArray MY_ARRAY "${MY_LIST}"
##   fxStringToArray MY_ARRAY "test,staging,prod" ","
function fxStringToArray()
{
  if [[ ! "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    fxCatastrophicError "fxStringToArray: ##$1## is not a valid array name!"
  fi

  local -n FX_STRING_TO_ARRAY_REF=$1

  if [ -z "$3" ]; then

    ## `-d ''` reads up to a NUL, i.e. the whole here-string (newlines included): it "fails" with 1 at the
    ## end of the input, but the words are assigned anyway
    read -r -d '' -a FX_STRING_TO_ARRAY_REF <<< "$2"
    return 0
  fi

  ## one read per item: the separator appended to the string ends the last item too, while the newline the
  ## here-string adds after it ends nothing, and is left unread
  local FX_STRING_TO_ARRAY_ITEM
  FX_STRING_TO_ARRAY_REF=()

  while IFS= read -r -d "$3" FX_STRING_TO_ARRAY_ITEM; do

    if [ -n "${FX_STRING_TO_ARRAY_ITEM}" ]; then
      FX_STRING_TO_ARRAY_REF+=("${FX_STRING_TO_ARRAY_ITEM}")
    fi

  done <<< "$2$3"

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
