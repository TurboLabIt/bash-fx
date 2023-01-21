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
