function fxCheckHttpsCert()
{
  local HOST=$(echo "$1" | sed -E 's|^https?://||; s|/$||')
  local TITLE="$2"

  fxTitle "$TITLE"

  ## DNS resolution
  local DNS_IP=$(dig +short "$HOST" @8.8.8.8 | tail -n1)
  local IP=$(getent hosts "$HOST" | head -n1 | awk '{print $1}')

  if [ -z "$DNS_IP" ] && [ -z "$IP" ]; then
    fxCatastrophicError "Resolution failed" 0
    return
  fi

  if [ -n "$DNS_IP" ]; then
    echo "  ✅ Public DNS resolution: $DNS_IP"
  else
    fxWarning "Public DNS resolution: FAIL - this domain doesn't appear to be in public DNS"
  fi
  [ -n "$IP" ] && echo "  ✅ /etc/hosts resolution: $IP"

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
    fxWarning "The certificate is INVALID. No certificate data received"
    [ -n "$CURL_REASON" ] && fxWarning "$CURL_REASON"

  else

    local EXPIRE_DATE=$(LC_ALL=en_US.UTF-8 date -d "$EXPIRE_RAW" '+%B %d, %Y' 2>/dev/null || echo "$EXPIRE_RAW")

    if echo "$CURL_OUT_K" | grep -qi 'self-signed certificate'; then

      ## Self-signed
      fxWarning "The certificate is self-signed. Expiration date: 📅 $EXPIRE_DATE 📅"
      local CERT_SANS=$(echo | openssl s_client -connect "$HOST:443" -servername "$HOST" 2>/dev/null | openssl x509 -noout -ext subjectAltName 2>/dev/null | grep -oP 'DNS:\K[^ ,]+' | paste -sd',' | sed 's/,/, /g')
      [ -n "$CERT_SANS" ] && fxWarning "The certificate is valid for: $CERT_SANS"

    elif [ "$CURL_RC" -eq 0 ]; then

      ## Valid
      echo "  ✅ HTTPS certificate is good until 📅 $EXPIRE_DATE 📅"
      local CERT_SANS=$(echo | openssl s_client -connect "$HOST:443" -servername "$HOST" 2>/dev/null | openssl x509 -noout -ext subjectAltName 2>/dev/null | grep -oP 'DNS:\K[^ ,]+' | paste -sd',' | sed 's/,/, /g')
      [ -n "$CERT_SANS" ] && echo "  ✅ The certificate is valid for: $CERT_SANS"

    else

      ## Invalid (SAN mismatch, expired, untrusted CA, etc.)
      local CURL_REASON=$(echo "$CURL_OUT_STRICT" | grep -oP '^curl: \(\d+\) \K.*' | head -n1)
      fxWarning "The certificate is INVALID. Expiration date: 📅 $EXPIRE_DATE 📅"
      [ -n "$CURL_REASON" ] && fxWarning "$CURL_REASON"
      local CERT_SANS=$(echo | openssl s_client -connect "$HOST:443" -servername "$HOST" 2>/dev/null | openssl x509 -noout -ext subjectAltName 2>/dev/null | grep -oP 'DNS:\K[^ ,]+' | paste -sd',' | sed 's/,/, /g')
      [ -n "$CERT_SANS" ] && fxWarning "The certificate is valid for: $CERT_SANS"

    fi
  fi

  ## HTTP status code check
  local HTTP_RESPONSE HTTP_STATUS HTTP_LOCATION
  HTTP_RESPONSE=$(curl -sS -k -o /dev/null -w '%{http_code} %{redirect_url}' --max-time 10 "https://$HOST" 2>/dev/null)
  HTTP_STATUS=${HTTP_RESPONSE%% *}
  HTTP_LOCATION=${HTTP_RESPONSE#* }

  if [ -n "$HTTP_STATUS" ] && [ "$HTTP_STATUS" != "000" ]; then

    local STATUS_FIRST=${HTTP_STATUS:0:1}

    if [ "$STATUS_FIRST" = "2" ]; then
      echo "  ✅ HTTP status: $HTTP_STATUS OK"
    elif [ "$STATUS_FIRST" = "3" ]; then
      echo "  ↪️  $HTTP_STATUS: redirecting to $HTTP_LOCATION"
    elif [ "$STATUS_FIRST" = "4" ]; then
      case "$HTTP_STATUS" in
        400) fxWarning "$HTTP_STATUS: Bad Request" ;;
        401) fxWarning "$HTTP_STATUS: Unauthorized" ;;
        403) fxWarning "$HTTP_STATUS: Forbidden" ;;
        404) fxWarning "$HTTP_STATUS: Not Found" ;;
        405) fxWarning "$HTTP_STATUS: Method Not Allowed" ;;
        408) fxWarning "$HTTP_STATUS: Request Timeout" ;;
        429) fxWarning "$HTTP_STATUS: Too Many Requests" ;;
        *)   fxWarning "$HTTP_STATUS: Client Error" ;;
      esac
    elif [ "$STATUS_FIRST" = "5" ]; then
      case "$HTTP_STATUS" in
        500) fxWarning "$HTTP_STATUS: Internal Server Error" ;;
        502) fxWarning "$HTTP_STATUS: Bad Gateway" ;;
        503) fxWarning "$HTTP_STATUS: Service Unavailable" ;;
        504) fxWarning "$HTTP_STATUS: Gateway Timeout" ;;
        *)   fxWarning "$HTTP_STATUS: Server Error" ;;
      esac
    fi

  fi
}
