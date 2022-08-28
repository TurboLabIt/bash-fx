#!/usr/bin/env bash

function fxCheckNotEmptyInput()
{
  if [ -z "$1" ]; then
    fxCatastrophicError "🔤 No input provided!"
  fi
}
