#!/usr/bin/env bash
source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"

fxHeader "🧪 test/replace.sh"

TEST_FILE=$(mktemp)
printf '%s\n' \
  '###> symfony/mailer ###' \
  'MAILER_DSN=null://null' \
  'MAILER_DSN_BACKUP=null://null' \
  '###< symfony/mailer ###' \
  '###> doctrine/doctrine-bundle ###' \
  '# DATABASE_URL="sqlite:///%kernel.project_dir%/var/data.db"' \
  '# DATABASE_URL="mysql://app:!ChangeMe!@127.0.0.1:3306/app"' \
  '###< doctrine/doctrine-bundle ###' > "${TEST_FILE}"
printf 'NO_NEWLINE=1' >> "${TEST_FILE}"


fxTitle "fxDotEnvSet: replace an active key (value with / ? & | \\)..."
fxDotEnvSet "${TEST_FILE}" MAILER_DSN 'smtp://localhost?verify_peer=false&x=a|b\c'

if grep -qxF 'MAILER_DSN=smtp://localhost?verify_peer=false&x=a|b\c' "${TEST_FILE}" && \
   [ "$(grep -c '^MAILER_DSN=' "${TEST_FILE}")" = 1 ] && grep -qxF 'MAILER_DSN_BACKUP=null://null' "${TEST_FILE}"; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


fxTitle "fxDotEnvSet: uncomment the first commented-out key only..."
fxDotEnvSet "${TEST_FILE}" DATABASE_URL '"mysql://app:pass@127.0.0.1:3306/app"'

if grep -qxF 'DATABASE_URL="mysql://app:pass@127.0.0.1:3306/app"' "${TEST_FILE}" && \
   [ "$(grep -c '^DATABASE_URL=' "${TEST_FILE}")" = 1 ] && \
   grep -qxF '# DATABASE_URL="mysql://app:!ChangeMe!@127.0.0.1:3306/app"' "${TEST_FILE}"; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


fxTitle "fxDotEnvSet: append a missing key to a file without a trailing newline..."
fxDotEnvSet "${TEST_FILE}" NEW_KEY "new value"

if grep -qxF 'NO_NEWLINE=1' "${TEST_FILE}" && [ "$(tail -n1 "${TEST_FILE}")" = "NEW_KEY=new value" ]; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


fxTitle "fxDotEnvSet: set an empty value..."
fxDotEnvSet "${TEST_FILE}" NEW_KEY ""

if grep -qxF 'NEW_KEY=' "${TEST_FILE}" && [ "$(grep -c '^NEW_KEY=' "${TEST_FILE}")" = 1 ]; then
  fxOK "PASS"
else
  fxWarning "FAIL"
fi


fxTitle "fxDotEnvSet: reject an invalid variable name..."
BEFORE=$(md5sum < "${TEST_FILE}")

if ( fxDotEnvSet "${TEST_FILE}" 'BAD KEY' x > /dev/null 2>&1 ) || [ "$(md5sum < "${TEST_FILE}")" != "${BEFORE}" ]; then
  fxWarning "FAIL"
else
  fxOK "PASS"
fi


fxTitle "fxDotEnvSet: reject a missing file..."
if ( fxDotEnvSet "${TEST_FILE}.nope" KEY x > /dev/null 2>&1 ); then
  fxWarning "FAIL"
else
  fxOK "PASS"
fi


fxTitle "Resulting file:"
cat "${TEST_FILE}"
rm -f "${TEST_FILE}"

fxEndFooter
