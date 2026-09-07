#!/usr/bin/env bash
source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"

fxHeader "🧪 test/array.sh"

## the format of the list-in-a-string config values (MAGENTO_MODULE_DISABLE, COMPATIBLE_OS_VERSIONS, ...):
## backslash-newline continuations, runs of spaces, leading and trailing blanks
LIST=" \
  Mod_A \
  Mod_B Mod_C   Mod_D \
"

fxTitle "fxStringToArray: explode a backslash-continued, multi-space list..."
fxStringToArray LIST_ARRAY "${LIST}"

if [ "${#LIST_ARRAY[@]}" = 4 ] && [ "${LIST_ARRAY[0]}" = "Mod_A" ] && [ "${LIST_ARRAY[3]}" = "Mod_D" ]; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


fxTitle "fxStringToArray: newlines and tabs are separators too..."
fxStringToArray LIST_ARRAY $'Mod_B\n\tMod_D\n'

if [ "${#LIST_ARRAY[@]}" = 2 ] && [ "${LIST_ARRAY[0]}" = "Mod_B" ] && [ "${LIST_ARRAY[1]}" = "Mod_D" ]; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


fxTitle "fxStringToArray: an empty string empties a previously filled array..."
fxStringToArray LIST_ARRAY ""

if [ "${#LIST_ARRAY[@]}" = 0 ]; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


fxTitle "fxStringToArray: an unset variable gives an empty array..."
fxStringToArray LIST_ARRAY "${UNSET_LIST_VAR}"

if [ "${#LIST_ARRAY[@]}" = 0 ]; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


fxTitle "fxStringToArray: fills a caller-local array, without leaking it globally..."
function testLocalArray()
{
  local LOCAL_ARRAY
  fxStringToArray LOCAL_ARRAY "x y z"
  echo "${#LOCAL_ARRAY[@]}"
}

if [ "$(testLocalArray)" = 3 ] && [ "${#LOCAL_ARRAY[@]}" = 0 ]; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


fxTitle "fxStringToArray: reject an invalid array name..."
if ( fxStringToArray "BAD NAME" "x y" > /dev/null 2>&1 ); then
  fxWarning "FAIL"
else
  fxOK "PASS"
fi


fxStringToArray LIST_ARRAY "${LIST}"

fxTitle "fxInArray: finds an item..."
if fxInArray "Mod_C" "${LIST_ARRAY[@]}"; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


fxTitle "fxInArray: no partial matches..."
if fxInArray "Mod_" "${LIST_ARRAY[@]}" || fxInArray "Mod_AB" "${LIST_ARRAY[@]}"; then
  fxWarning "FAIL"
else
  fxOK "PASS"
fi


fxTitle "fxInArray: an empty list never matches..."
EMPTY_ARRAY=()
if fxInArray "Mod_A" "${EMPTY_ARRAY[@]}" || fxInArray "" "${EMPTY_ARRAY[@]}"; then
  fxWarning "FAIL"
else
  fxOK "PASS"
fi


fxTitle "fxRequireCompatbileUbuntuVersion: the current OS is in the list..."
if ( fxRequireCompatbileUbuntuVersion "22.04 $(fxGetUbuntuVersion) 24.04" > /dev/null 2>&1 ); then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


fxTitle "fxRequireCompatbileUbuntuVersion: the current OS is NOT in the list..."
if ( fxRequireCompatbileUbuntuVersion "22.04 24.04" > /dev/null 2>&1 ); then
  fxWarning "FAIL"
else
  fxOK "PASS"
fi

fxEndFooter
