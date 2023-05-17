#!/usr/bin/env bash
source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"

fxHeader "🧪 test/user.sh"

fxTitle "Test if existing user exists..."
USER_EXISTS=$(fxUserExists "zane")

if [ "$USER_EXISTS" ]; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi

if [ ! "$USER_EXISTS" ]; then
  fxWarning "FAIL"
else
  fxOK "PASS"
fi


fxTitle "Test if NOT existing user exists..."
USER_EXISTS=$(fxUserExists "zaneeee")

if [ ! "$USER_EXISTS" ]; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi

if [ "$USER_EXISTS" ]; then
  fxWarning "FAIL"
else
  fxOK "PASS"
fi

fxEndFooter



fxTitle "Get home of an existing user..."
USER_HOME=$(fxGetUserHomePath "webstackup")
fxInfo "${USER_HOME}"

if [ "${USER_HOME}" = "/home/webstackup/" ]; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


fxTitle "Get home of a non-existing user..."
USER_HOME=$(fxGetUserHomePath "zaneeee")

if [ "${USER_HOME}" = "" ]; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


fxEndFooter
