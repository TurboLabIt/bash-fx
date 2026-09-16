#!/usr/bin/env bash
source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"

fxHeader "🧪 test/system.sh"

## the jobs run as root (sudo): their files too, hence the sudo rm at the end
TEST_DIR=$(mktemp -d)


fxTitle "fxRunDetached: returns at once, then the job writes its output and its exit code..."
TEST_STARTED=$(date +%s)
fxRunDetached "${TEST_DIR}/normal" "echo hello; sleep 3; bash -c 'exit 3'"
TEST_RC=$?
TEST_ELAPSED=$(( $(date +%s) - TEST_STARTED ))

if [ "${TEST_RC}" = 0 ] && [ "${TEST_ELAPSED}" -lt 3 ] && [ ! -e "${TEST_DIR}/normal.exit-code" ]; then
  fxOK "PASS"
else
  fxWarning "FAIL: rc ${TEST_RC}, returned after ${TEST_ELAPSED}s"
fi

sleep 4

if [ "$(cat "${TEST_DIR}/normal.log")" = "hello" ] && [ "$(cat "${TEST_DIR}/normal.exit-code")" = 3 ]; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


fxTitle "fxRunDetached: a new run of the same job wipes the exit code of the previous one..."
fxRunDetached "${TEST_DIR}/normal" "sleep 3"

if [ ! -e "${TEST_DIR}/normal.exit-code" ]; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


fxTitle "fxRunDetached: kill <pid> while it sleeps, what comes after never runs..."
fxRunDetached "${TEST_DIR}/cancel" "sleep 3; touch ${TEST_DIR}/cancel.fired"
sudo kill "$(cat "${TEST_DIR}/cancel.pid")"
sleep 4

if [ ! -e "${TEST_DIR}/cancel.fired" ] && [ ! -e "${TEST_DIR}/cancel.exit-code" ]; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


fxTitle "fxRunDetached: kill -- -<pid> stops whatever the job started too..."
fxRunDetached "${TEST_DIR}/group" "bash -c 'sleep 300 | cat'"
TEST_PGID=$(cat "${TEST_DIR}/group.pid")
sleep 1
sudo kill -- -"${TEST_PGID}"
sleep 1

if [ -z "$(ps -e -o pgid= | awk -v p="${TEST_PGID}" '$1 == p')" ] && [ ! -e "${TEST_DIR}/group.exit-code" ]; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


fxTitle "fxRunDetached: no command line, no job..."
fxRunDetached "${TEST_DIR}/empty" ""

if [ "$?" = 1 ] && [ ! -e "${TEST_DIR}/empty.pid" ]; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


sudo rm -rf "${TEST_DIR}"
fxEndFooter
