#!/usr/bin/env bash


function fxSetBackgroundColorByHostAndEnv()
{
  if [ "$(hostname -s)" != "$1" ]; then
    return 255;
  fi

  case "$2" in
    prod)
      # very dark red
      fxSetBackgroundColor "#F2F2F2" "#240000"
      ;;
    next|staging)
      # very dark orange
      fxSetBackgroundColor "#F2F2F2" "#241600"
      ;;
  esac
}


function fxSetBackgroundColor()
{
  if [[ $- == *i* && -n "$SSH_CONNECTION" ]]; then

    local fg="$1" bg="$2"
    # If inside tmux/screen, wrap the sequences so they pass through
    if [[ -n "$TMUX" ]]; then
      printf '\ePtmux;\e\e]10;%s\a\e\\' "$fg"
      printf '\ePtmux;\e\e]11;%s\a\e\\' "$bg"
    elif [[ "$TERM" == screen* ]]; then
      printf '\eP\e]10;%s\a\e\\' "$fg"
      printf '\eP\e]11;%s\a\e\\' "$bg"
    else
      printf '\e]10;%s\a' "$fg"   # foreground
      printf '\e]11;%s\a' "$bg"   # background
    fi

  fi
}


function fxResetBackgroundColor()
{
  if [[ $- == *i* && -n "$SSH_CONNECTION" ]]; then

    # Reset to terminal defaults (OSC 110/111/112)
    if [[ -n "$TMUX" ]]; then
      printf '\ePtmux;\e\e]110\a\e\\'
      printf '\ePtmux;\e\e]111\a\e\\'
      printf '\ePtmux;\e\e]112\a\e\\'
    elif [[ "$TERM" == screen* ]]; then
      printf '\eP\e]110\a\e\\'
      printf '\eP\e]111\a\e\\'
      printf '\eP\e]112\a\e\\'
    else
      printf '\e]110\a\e]111\a\e]112\a'
    fi

  fi
}
