function fxHttpMessage()
{
  local URL="$1"
  local HTTP_STATUS="$2"
  local HTTP_LOCATION="$3"
  local STATUS_FIRST=${HTTP_STATUS:0:1}

  if [ "$STATUS_FIRST" = "2" ]; then
    echo "✅ $URL returned $HTTP_STATUS: OK"
  elif [ "$STATUS_FIRST" = "3" ]; then
    echo "↪️  $URL returned $HTTP_STATUS: redirecting to $HTTP_LOCATION"
  elif [ "$STATUS_FIRST" = "4" ]; then
    case "$HTTP_STATUS" in
      400) echo -e "❌ \e[1;31m$URL returned $HTTP_STATUS: Bad Request\e[0m" ;;
      401) echo -e "❌ \e[1;31m$URL returned $HTTP_STATUS: Unauthorized\e[0m" ;;
      403) echo -e "❌ \e[1;31m$URL returned $HTTP_STATUS: Forbidden\e[0m" ;;
      404) echo -e "❌ \e[1;31m$URL returned $HTTP_STATUS: Not Found\e[0m" ;;
      405) echo -e "❌ \e[1;31m$URL returned $HTTP_STATUS: Method Not Allowed\e[0m" ;;
      408) echo -e "❌ \e[1;31m$URL returned $HTTP_STATUS: Request Timeout\e[0m" ;;
      429) echo -e "❌ \e[1;31m$URL returned $HTTP_STATUS: Too Many Requests\e[0m" ;;
      *)   echo -e "❌ \e[1;31m$URL returned $HTTP_STATUS: Client Error\e[0m" ;;
    esac
  elif [ "$STATUS_FIRST" = "5" ]; then
    case "$HTTP_STATUS" in
      500) echo -e "❌ \e[1;31m$URL returned $HTTP_STATUS: Internal Server Error\e[0m" ;;
      502) echo -e "❌ \e[1;31m$URL returned $HTTP_STATUS: Bad Gateway\e[0m" ;;
      503) echo -e "❌ \e[1;31m$URL returned $HTTP_STATUS: Service Unavailable\e[0m" ;;
      504) echo -e "❌ \e[1;31m$URL returned $HTTP_STATUS: Gateway Timeout\e[0m" ;;
      *)   echo -e "❌ \e[1;31m$URL returned $HTTP_STATUS: Server Error\e[0m" ;;
    esac
  fi
}


function fxCheckHttpsCert()
{
  local HOST=$(echo "$1" | sed -E 's|^https?://||; s|/$||')

  fxTitle "Running fxCheckHttpsCert against $HOST"

  ## DNS resolution
  local DNS_IP=$(dig +short "$HOST" @8.8.8.8 | tail -n1)
  local IP=$(getent hosts "$HOST" | head -n1 | awk '{print $1}')

  if [ -z "$DNS_IP" ] && [ -z "$IP" ]; then
    fxCatastrophicError "Resolution failed" 0
    return
  fi

  if [ -n "$DNS_IP" ]; then
    echo "✅ Public DNS resolution: $DNS_IP"
  else
    fxWarning "Public DNS resolution: FAIL - this domain doesn't appear to be in public DNS"
  fi
  [ -n "$IP" ] && echo "✅ /etc/hosts resolution: $IP"

  echo ""

  ## Certificate check: insecure curl (always completes handshake, gives cert details)
  local CURL_OUT_K
  CURL_OUT_K=$(curl -sS --max-time 10 -k -vvI "https://$HOST" 2>&1)

  ## Certificate check: strict curl (for pass/fail exit code + error reason)
  local CURL_OUT_STRICT CURL_RC
  CURL_OUT_STRICT=$(curl -sS --max-time 10 -vvI "https://$HOST" 2>&1)
  CURL_RC=$?

  ## Parse expiration date from insecure curl output
  local EXPIRE_RAW=$(echo "$CURL_OUT_K" | grep -i 'expire date:' | head -n1 | sed 's/.*expire date: *//')

  if [ -z "$EXPIRE_RAW" ]; then

    ## No cert data at all
    local CURL_REASON=$(echo "$CURL_OUT_K" | grep -oP '^curl: \(\d+\) \K.*' | head -n1)
    echo -e "❌ \e[1;31mThe certificate is INVALID. No certificate data received\e[0m"
    [ -n "$CURL_REASON" ] && echo -e "❌ \e[1;31m$CURL_REASON\e[0m"

  else

    local EXPIRE_DATE=$(LC_ALL=en_US.UTF-8 date -d "$EXPIRE_RAW" '+%B %d, %Y' 2>/dev/null || echo "$EXPIRE_RAW")

    if echo "$CURL_OUT_K" | grep -qi 'self-signed certificate'; then

      ## Self-signed
      echo -e "❌ \e[1;31mThe certificate is self-signed. Expiration date: 📅 $EXPIRE_DATE\e[0m"
      local CERT_SANS=$(echo | openssl s_client -connect "$HOST:443" -servername "$HOST" 2>/dev/null | openssl x509 -noout -ext subjectAltName 2>/dev/null | grep -oP 'DNS:\K[^ ,]+' | paste -sd',' | sed 's/,/, /g')
      [ -n "$CERT_SANS" ] && echo -e "❌ \e[1;31mThe certificate is valid for: $CERT_SANS\e[0m"

    elif [ "$CURL_RC" -eq 0 ]; then

      ## Valid
      echo "✅ HTTPS certificate is good until 📅 $EXPIRE_DATE"
      local CERT_SANS=$(echo | openssl s_client -connect "$HOST:443" -servername "$HOST" 2>/dev/null | openssl x509 -noout -ext subjectAltName 2>/dev/null | grep -oP 'DNS:\K[^ ,]+' | paste -sd',' | sed 's/,/, /g')
      [ -n "$CERT_SANS" ] && echo "✅ The certificate is valid for: $CERT_SANS"

    else

      ## Invalid (SAN mismatch, expired, untrusted CA, etc.)
      local CURL_REASON=$(echo "$CURL_OUT_STRICT" | grep -oP '^curl: \(\d+\) \K.*' | head -n1)
      echo -e "❌ \e[1;31mThe certificate is INVALID. Expiration date: 📅 $EXPIRE_DATE\e[0m"
      [ -n "$CURL_REASON" ] && echo -e "❌ \e[1;31m$CURL_REASON\e[0m"
      local CERT_SANS=$(echo | openssl s_client -connect "$HOST:443" -servername "$HOST" 2>/dev/null | openssl x509 -noout -ext subjectAltName 2>/dev/null | grep -oP 'DNS:\K[^ ,]+' | paste -sd',' | sed 's/,/, /g')
      [ -n "$CERT_SANS" ] && echo -e "❌ \e[1;31mThe certificate is valid for: $CERT_SANS\e[0m"

    fi
  fi

  ## HTTP status code check
  echo ""
  local HTTP_RESPONSE HTTP_STATUS HTTP_LOCATION
  HTTP_RESPONSE=$(curl -sS -k -o /dev/null -w '%{http_code} %{redirect_url}' --max-time 10 "https://$HOST" 2>/dev/null)
  HTTP_STATUS=${HTTP_RESPONSE%% *}
  HTTP_LOCATION=${HTTP_RESPONSE#* }

  if [ -n "$HTTP_STATUS" ] && [ "$HTTP_STATUS" != "000" ]; then
    fxHttpMessage "https://$HOST" "$HTTP_STATUS" "$HTTP_LOCATION"
  fi

  ## HTTP (non-SSL) status code check
  echo ""
  local HTTP_RESPONSE_PLAIN HTTP_STATUS_PLAIN HTTP_LOCATION_PLAIN
  HTTP_RESPONSE_PLAIN=$(curl -sS -o /dev/null -w '%{http_code} %{redirect_url}' --max-time 10 "http://$HOST" 2>/dev/null)
  HTTP_STATUS_PLAIN=${HTTP_RESPONSE_PLAIN%% *}
  HTTP_LOCATION_PLAIN=${HTTP_RESPONSE_PLAIN#* }

  if [ -n "$HTTP_STATUS_PLAIN" ] && [ "$HTTP_STATUS_PLAIN" != "000" ]; then

    local STATUS_FIRST_PLAIN=${HTTP_STATUS_PLAIN:0:1}

    if [ "$STATUS_FIRST_PLAIN" = "2" ]; then
      echo -e "❌ \e[1;31mhttp://$HOST $HTTP_STATUS_PLAIN: serving over plain HTTP without redirecting to HTTPS\e[0m"
    elif [ "$STATUS_FIRST_PLAIN" = "3" ]; then
      if echo "$HTTP_LOCATION_PLAIN" | grep -qi '^https://'; then
        fxHttpMessage "http://$HOST" "$HTTP_STATUS_PLAIN" "$HTTP_LOCATION_PLAIN"
      else
        echo -e "❌ \e[1;31mhttp://$HOST $HTTP_STATUS_PLAIN: redirecting to $HTTP_LOCATION_PLAIN (not HTTPS!)\e[0m"
      fi
    else
      fxHttpMessage "http://$HOST" "$HTTP_STATUS_PLAIN" "$HTTP_LOCATION_PLAIN"
    fi

  fi
}


function fxCheckHttpsCertMulti()
{
  local INPUT=$(echo "$1" | sed -E 's|^https?://||; s|/$||')
  local DOMAIN=$(echo "$INPUT" | sed -E 's|^www\.||')
  local DOT_COUNT=$(echo "$DOMAIN" | tr -cd '.' | wc -c)

  if [ "$DOT_COUNT" -gt 1 ]; then

    fxCheckHttpsCert "$DOMAIN"

  elif echo "$INPUT" | grep -q '^www\.'; then

    fxCheckHttpsCert "www.$DOMAIN"
    fxCheckHttpsCert "$DOMAIN"

  else

    fxCheckHttpsCert "$DOMAIN"
    fxCheckHttpsCert "www.$DOMAIN"

  fi
}


function fxTestHttpRedirect()
{
  local SOURCE_URL="$1"
  local TARGET_URL="${2:-}"
  local HTTP_CODE="${3:-301}"

  fxTitle "Running fxTestHttpRedirect against $SOURCE_URL"

  local HTTP_RESPONSE HTTP_STATUS HTTP_LOCATION
  HTTP_RESPONSE=$(curl -sS -k -o /dev/null -w '%{http_code} %{redirect_url}' --max-time 10 "$SOURCE_URL" 2>/dev/null)
  HTTP_STATUS=${HTTP_RESPONSE%% *}
  HTTP_LOCATION=${HTTP_RESPONSE#* }

  if [ -z "$HTTP_STATUS" ] || [ "$HTTP_STATUS" = "000" ]; then
    echo -e "❌ \e[1;31m$SOURCE_URL: no response\e[0m"
    return
  fi

  if [ "$HTTP_STATUS" = "$HTTP_CODE" ]; then
    echo "✅ $SOURCE_URL returned $HTTP_STATUS as expected"
  else
    echo -e "❌ \e[1;31m$SOURCE_URL returned $HTTP_STATUS, expected $HTTP_CODE\e[0m"
  fi

  if [ -n "$TARGET_URL" ]; then
    if [ "$HTTP_LOCATION" = "$TARGET_URL" ]; then
      echo "✅ Location matches: $HTTP_LOCATION"
    else
      echo -e "❌ \e[1;31mLocation mismatch: got '$HTTP_LOCATION', expected '$TARGET_URL'\e[0m"
    fi
  fi
}
