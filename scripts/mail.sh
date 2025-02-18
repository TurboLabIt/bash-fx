if [ -f "/etc/mailname" ]; then

  WSU_MAILNAME=$(cat /etc/mailname)
  WSU_MAILNAME="${WSU_MAILNAME//[[:space:]]/}"

  DOT_COUNT=$(awk -F'.' '{print NF-1}' <<< "$WSU_MAILNAME")

  if [ "$DOT_COUNT" -eq 1 ]; then
      # Exactly one dot => second-level domain
      WSU_MAILDOMAIN="$WSU_MAILNAME"
  else
      # More than one dot => third-level (or higher)
      # Remove everything up to the first dot
      WSU_MAILDOMAIN="${WSU_MAILNAME#*.}"
  fi

  WSU_MAIL_DEFAULT_TEST_ADDRESS=test@${WSU_MAILDOMAIN}
  WSU_MAIL_DEFAULT_ADDRESS=info@${WSU_MAILDOMAIN}

else

  WSU_MAIL_DEFAULT_TEST_ADDRESS=test@example.com
  WSU_MAIL_DEFAULT_ADDRESS=info@example.com
fi


function fxMailNameWarning()
{
  if [ -z "WSU_MAILNAME" ]; then
    fxWarning "Mailname doesn't exist. User discretion is advised"
  else
    fxInfo "Your mailname is ##${WSU_MAILNAME}##"
  fi
}
