#!/usr/bin/env bash

function fxHostnameRename()
{
  local NEW_HOSTNAME=$1
  local OLD_HOSTNAME="$(hostname)"

  if [ -z "$NEW_HOSTNAME" ]; then

    fxTitle "📛 Enter the new hostname"
    fxInfo "For example: appname-prd - avoid dots and real DNS names"
    while [ -z "$NEW_HOSTNAME" ]; do

      echo "🤖 Provide the new hostname"
      read -p ">> " NEW_HOSTNAME < /dev/tty
    done
  fi

  NEW_HOSTNAME="${NEW_HOSTNAME,,}"
  fxTitle "Renaming the system to ##${NEW_HOSTNAME}##..."

  sudo hostnamectl set-hostname "${NEW_HOSTNAME}"

  ## setting ##${NEW_HOSTNAME}## as the first line of /etc/hosts..."
  sudo sed -i -E "/^127\.0\.1\.1[[:space:]]/d; /^127\.0\.0\.1[[:space:]]+${NEW_HOSTNAME}$/d" /etc/hosts

  ## drop the previous name's loopback entry too, but never nuke the real 'localhost' line
  if [ -n "$OLD_HOSTNAME" ] && [ "$OLD_HOSTNAME" != "localhost" ]; then
    sudo sed -i -E "/^127\.0\.0\.1[[:space:]]+${OLD_HOSTNAME}$/d" /etc/hosts
  fi
  sudo sed -i "1i 127.0.0.1\t${NEW_HOSTNAME}" /etc/hosts

  local CURRENT_HOSTNAME="$(hostname)"
  fxOK "Done. The current, updated hostname is: ##${CURRENT_HOSTNAME}##"

  ## a shell caches the hostname in its prompt (\h) at login, so already-open shells stay stale
  fxInfo "Run 'exec bash' (or re-login) to refresh your shell prompt"
}


function fxAptUpdate()
{
  ## refresh the apt cache, but only if it's older than $1 minutes (default: 15)
  ## pass 0 to force it: mandatory right after adding a new repo!
  local MAX_AGE_MINUTES="${1:-15}"

  ## apt has no built-in "update only if stale" option, so we look at the cache's mtime.
  ## pkgcache.bin is rebuilt by apt itself on every successful update
  ## (/var/lib/apt/periodic/update-success-stamp would be stricter, but it's touched by a hook
  ## shipped with update-notifier-common, which is missing on minimal servers and in containers)
  local APT_CACHE_FILE=/var/cache/apt/pkgcache.bin

  if [ "$MAX_AGE_MINUTES" -gt 0 ] && [ -f "$APT_CACHE_FILE" ] &&
     [ -n "$(find "$APT_CACHE_FILE" -maxdepth 0 -mmin "-${MAX_AGE_MINUTES}" 2>/dev/null)" ]; then

    fxInfo "The apt cache is younger than ${MAX_AGE_MINUTES} min: skipping ##apt update##"
    return 0
  fi

  fxTitle "📦 Updating the apt cache..."

  ## -qq: warnings and errors only
  ## short timeouts + 1 retry: an unreachable mirror makes apt retry silently for minutes, which looks like a freeze
  if ! sudo apt-get update -qq -o Acquire::Retries=1 -o Acquire::http::Timeout=20 -o Acquire::https::Timeout=20; then

    fxCatastrophicError "##apt update## failed" 0
    return 255
  fi

  fxOK "apt cache updated"
}


##
## Reboot in $1 seconds (default: 60) without waiting for it: this returns at once, the calling script
## ends normally and the pending reboot outlives it, its terminal and the SSH session which ran it
## (multissh, deploy scripts, ...). To cancel it: sudo kill $(cat /run/bashfx-reboot.pid)
##
## Why not a plain "(sleep N; reboot) &": a background job stays in the process group of the script, and
## that group gets a SIGHUP when the script ends -- it IS the session leader when ssh ran it -- or when its
## terminal goes away. setsid moves the wait into a session of its own, out of reach of both. In the
## foreground and waited for (-w), not "setsid ... &": the detached shell must exist BEFORE this returns,
## or its fork races the exit of the caller and loses (the SIGHUP lands before it detaches). Every stream
## to /dev/null: with no pty (plain ssh, cron, a pipe) the caller's ssh only returns once nothing holds its
## stdout/stderr anymore, so a wait still attached to them would keep it hanging for the whole delay.
##
## Unattended by design: no countdown, no confirmation. That's for the caller, when a human is watching
##
function fxRebootDelayed()
{
  local REBOOT_DELAY_SEC="${1:-60}"
  local REBOOT_PIDFILE=/run/bashfx-reboot.pid

  if ! [[ "$REBOOT_DELAY_SEC" =~ ^[0-9]+$ ]]; then

    fxWarning "The reboot delay must be an integer, got '${REBOOT_DELAY_SEC}': rebooting in 60 seconds"
    REBOOT_DELAY_SEC=60
  fi

  fxTitle "🔌 Rebooting in ${REBOOT_DELAY_SEC} seconds"

  ## $BASHPID is the pid of the detached subshell, the one to kill to call it off ($$ would be its parent, gone at once)
  sudo setsid -w bash -c "( echo \$BASHPID > '${REBOOT_PIDFILE}'; sleep ${REBOOT_DELAY_SEC}; reboot ) > /dev/null 2>&1 < /dev/null &"

  fxInfo "The system will reboot at $(date -d "+${REBOOT_DELAY_SEC} seconds" +'%T'). Not waiting for it: the wait runs in background, this script goes on"
  fxMessage "To cancel it: sudo kill \$(cat ${REBOOT_PIDFILE})"
}


##
## Pin a third-party APT repo: its packages always win over the distribution's, and Ubuntu's own builds of the same
## packages can never be installed. Both halves matter:
##   - when the repo's signing key expires, "apt update" keeps serving its last good index, frozen: the positive pin
##     keeps those versions ahead of the newer ones Ubuntu keeps publishing
##   - when that index is gone (lists wiped, suite dropped by the vendor, sources rewritten, fresh server), only the
##     negative pin stops "apt dist-upgrade" from swapping the vendor's mysql-server/nginx/varnish/... for Ubuntu's
##     build (different packaging, config layout, data dir: a mess)
##
## $1: name      => the pin file is 99<name> in /etc/apt/preferences.d/
## $2: repo URI  => the URIs: of its .sources file (or the URL of its deb line). glob(7) allowed, trailing slash ignored:
##                  "http*://packagecloud.io/varnishcache/varnish*/ubuntu/" matches any version configured
## $3: optional  => space-separated names/globs of Ubuntu packages to block even if the repo doesn't ship them: the
##                  distro-only pieces of the same product (i.e. "mysql-* default-mysql-*"). They are the whole list
##                  when there is no index to read the repo's own package names from
## $4: optional  => priority of the repo's packages (default: 900)
##
## Call it after "fxAptUpdate 0", with the repo configured: the package names come from the repo's index. No index
## right now => a pin already written by this function is kept as it is, otherwise one is written with the $3 list.
## Returns 0 only when the pin comes from the index AND every package of the repo resolves to the repo itself
##
## Only for vendor repos shipping their own product (MySQL, nginx, Redis, ...). NOT for a PPA which also backports
## shared libraries (i.e. ondrej/php: libzip, libpcre2, ...): Ubuntu's security updates of those would be blocked
##
## Why not the "Pin: origin X" + "Pin: release o=Y" stanza from the vendors' docs: apt keeps the last Pin: line only,
## and Y must be the Origin: the vendor writes in its Release file (Elastic: "elastic", not "elasticsearch") or the
## pin silently does nothing. "Pin: origin" matches the host of our own URI instead, and the Package: list keeps it
## off the unrelated repos of a shared host (packagecloud.io). "o=Ubuntu*" is a case-insensitive glob (Ubuntu,
## UbuntuESM, UbuntuESMApps, ...): a negative priority forbids those versions, whatever else is available
##
function fxAptPinRepo()
{
  local PIN_NAME="$1"
  local REPO_URI="${2%/}"
  local PIN_EXTRA="$3"
  local PIN_PRIORITY="${4:-900}"

  if [ -z "$PIN_NAME" ] || [ -z "$REPO_URI" ]; then

    fxCatastrophicError "Usage: fxAptPinRepo <name> <repo URI> [<Ubuntu packages to block>] [<priority>]" 0
    return 1
  fi

  ## wherever this apt reads its preferences from (APT_CONFIG is honored: a test setup never touches the system)
  local PIN_DIR
  eval "$(apt-config shell PIN_DIR Dir::Etc::PreferencesParts/d)"
  local PIN_FILE="${PIN_DIR%/}/99${PIN_NAME}"
  local PIN_SIGNATURE="## Generated by bash-fx fxAptPinRepo"

  ## "Pin: origin" wants the bare host: no scheme, credentials, port or path
  local REPO_HOST=$(echo "$REPO_URI" | sed -E 's|^[^:]+://([^@/]*@)?([^/:]+).*|\2|')

  fxTitle "📌 Pinning ##${REPO_HOST}## over Ubuntu's packages..."

  if ! fxAptRepoIsConfigured "$REPO_URI"; then

    fxWarning "##${REPO_URI}## is not configured in APT: no pin written"
    return 1
  fi

  ## every package the repo ships, from its index files on disk (compressed or not)
  local REPO_PACKAGES=$(
    fxAptRepoIndexFiles "$REPO_URI" | while read -r INDEX_FILE; do
      /usr/lib/apt/apt-helper cat-file "$INDEX_FILE"
    done | awk '/^Package:/ { print $2 }' | sort -u | tr '\n' ' '
  )

  ## the installed packages matched by $3, as "package source-package". read -a: the globs must not expand here
  local -a PIN_GLOBS
  read -ra PIN_GLOBS <<< "$PIN_EXTRA"
  local INSTALLED_PACKAGES=$(fxAptInstalledPackages)
  local INSTALLED_MATCHING=$(
    while read -r INSTALLED_NAME INSTALLED_SOURCE; do
      for PIN_GLOB in "${PIN_GLOBS[@]}"; do

        if [[ "$INSTALLED_NAME" == $PIN_GLOB ]]; then

          echo "$INSTALLED_NAME $INSTALLED_SOURCE"
          break
        fi
      done
    done <<< "$INSTALLED_PACKAGES"
  )

  if [ -z "${REPO_PACKAGES// }" ]; then

    fxWarning "##${REPO_URI}## has no index: its last ##apt update## never succeeded (unreachable? signing key?)"

    if grep -qs "^${PIN_SIGNATURE}" "$PIN_FILE"; then

      fxInfo "Keeping ${PIN_FILE} as it is: Ubuntu's packages stay blocked"
      return 1
    fi

    if [ -z "${PIN_EXTRA// }" ]; then

      fxWarning "No package names to block: ${PIN_FILE} not written"
      return 1
    fi

    ## $3 can't list every package of the repo (i.e. the vendor's libmysqlclient24): add the installed ones built from
    ## the same source packages as the installed ones $3 matches (all the MySQL ones come from "mysql-community")
    PIN_EXTRA="$PIN_EXTRA $(awk 'NR == FNR { SOURCES[$2]; next } ($2 in SOURCES) { print $1 }' \
      <(echo "$INSTALLED_MATCHING") <(echo "$INSTALLED_PACKAGES") | tr '\n' ' ')"

    fxInfo "Writing ${PIN_FILE} from the fallback list and the installed packages"
  fi

  ## one line, no duplicates. Never unquoted: a glob like mysql-* must reach apt, not the shell
  local PIN_PACKAGES=$(echo "$REPO_PACKAGES $PIN_EXTRA" | tr -s '[:space:]' '\n' | awk 'NF && !SEEN[$0]++' | tr '\n' ' ')
  PIN_PACKAGES="${PIN_PACKAGES% }"

  local PIN_TMP_FILE=$(mktemp)
  local PIN_TMP_DIR=$(mktemp -d)

  cat > "$PIN_TMP_FILE" <<PINEOF
${PIN_SIGNATURE} for ${REPO_URI}
## Don't edit, it gets regenerated: https://github.com/TurboLabIt/bash-fx/blob/main/scripts/system.sh

## the repo's packages always win over the distribution's
Package: ${PIN_PACKAGES}
Pin: origin ${REPO_HOST}
Pin-Priority: ${PIN_PRIORITY}

## Ubuntu's builds of the same packages can never be installed, not even when the repo is broken
Package: ${PIN_PACKAGES}
Pin: release o=Ubuntu*
Pin-Priority: -1
PINEOF

  ## one malformed preferences file breaks every apt command on the system: apt must parse it first
  if ! apt-cache -o Dir::Etc::Preferences="$PIN_TMP_FILE" -o Dir::Etc::PreferencesParts="$PIN_TMP_DIR" policy > /dev/null; then

    rm -rf "$PIN_TMP_FILE" "$PIN_TMP_DIR"
    fxCatastrophicError "apt rejects the generated pin (see above): ${PIN_FILE} not touched" 0
    return 1
  fi

  local PIN_SUDO=
  if [ ! -w "$PIN_DIR" ]; then
    PIN_SUDO=sudo
  fi

  if cmp -s "$PIN_TMP_FILE" "$PIN_FILE"; then

    fxOK "${PIN_FILE} is already up to date"

  elif $PIN_SUDO install -m 644 "$PIN_TMP_FILE" "$PIN_FILE"; then

    fxOK "${PIN_FILE} written"

  else

    rm -rf "$PIN_TMP_FILE" "$PIN_TMP_DIR"
    fxCatastrophicError "Can't write ${PIN_FILE}" 0
    return 1
  fi

  rm -rf "$PIN_TMP_FILE" "$PIN_TMP_DIR"
  cat "$PIN_FILE"

  if [ -z "${REPO_PACKAGES// }" ]; then
    return 1
  fi

  ## the proof: the repo's packages, and the installed ones matched by $3, must now resolve to the repo. No candidate,
  ## or one at another priority, means an Ubuntu build is installed already (or a newer version apt won't downgrade)
  local PIN_CHECK=$(echo "$REPO_PACKAGES $(echo "$INSTALLED_MATCHING" | awk '{ print $1 }')" | tr -s '[:space:]' '\n' | sort -u | tr '\n' ' ')
  local PIN_MISSES=$(LC_ALL=C apt-cache policy $PIN_CHECK 2>/dev/null | awk -v PRIO="$PIN_PRIORITY" '
    /^[^ ]/                                  { PKG = $1; sub(/:$/, "", PKG); next }
    /^  Candidate:/                           { CAND = $2; if (CAND == "(none)") print PKG; next }
    /^ \*\*\* / && $2 == CAND && $3 != PRIO   { print PKG; next }
    /^     [^ ]/ && $1 == CAND && $2 != PRIO  { print PKG }
  ' | sort -u | tr '\n' ' ')

  if [ -n "${PIN_MISSES// }" ]; then

    fxWarning "Not resolving to ##${REPO_HOST}## (an Ubuntu build installed already? see ##apt-cache policy##): ${PIN_MISSES}"
    return 1
  fi

  fxOK "All $(echo $PIN_CHECK | wc -w) packages resolve to ##${REPO_HOST}##"
}


##
## Installed packages, one "package source-package" per line. Reads Dir::State::status: APT_CONFIG is honored
##
function fxAptInstalledPackages()
{
  local DPKG_STATUS
  eval "$(apt-config shell DPKG_STATUS Dir::State::status/f)"

  awk 'BEGIN { RS = ""; FS = "\n" } {
    NAME = ""; SOURCE = ""; INSTALLED = 0
    for (i = 1; i <= NF; i++) {
      if ($i ~ /^Package: /) { NAME = substr($i, 10) }
      else if ($i ~ /^Source: /) { SOURCE = substr($i, 9); sub(/ .*/, "", SOURCE) }
      else if ($i ~ /^Status: .* installed$/) { INSTALLED = 1 }
    }
    if (INSTALLED) { print NAME, (SOURCE == "" ? NAME : SOURCE) }
  }' "$DPKG_STATUS"
}


##
## Is this APT repo configured? $1: repo URI, glob(7) allowed, trailing slash ignored
## (--no-release-info: list the repo even if its last "apt update" never succeeded)
##
function fxAptRepoIsConfigured()
{
  local REPO_URI="${1%/}"
  local TARGET_URI

  while read -r TARGET_URI; do

    if [[ "${TARGET_URI%/}" == ${REPO_URI} ]]; then
      return 0
    fi

  done < <(apt-get indextargets --no-release-info --format '$(REPO_URI)' 'Created-By: Packages' 2>/dev/null)

  return 1
}


##
## The Packages index files of an APT repo which are on disk, one per line. They may be compressed: read them with
## "/usr/lib/apt/apt-helper cat-file". A failed "apt update" keeps the previous ones, so none = it never succeeded
## $1: repo URI, glob(7) allowed, trailing slash ignored
##
function fxAptRepoIndexFiles()
{
  local REPO_URI="${1%/}"
  local TARGET_URI TARGET_FILE

  while IFS='|' read -r TARGET_URI TARGET_FILE; do

    if [[ "${TARGET_URI%/}" == ${REPO_URI} ]] && [ -f "$TARGET_FILE" ]; then
      echo "$TARGET_FILE"
    fi

  done < <(apt-get indextargets --format '$(REPO_URI)|$(FILENAME)' 'Created-By: Packages' 2>/dev/null)
}


##
## Remove the pin written by fxAptPinRepo, i.e. along with the repo: Ubuntu's packages become installable again
## $1: name => 99<name> in /etc/apt/preferences.d/
##
function fxAptUnpinRepo()
{
  if [ -z "$1" ]; then

    fxCatastrophicError "Usage: fxAptUnpinRepo <name>" 0
    return 1
  fi

  local PIN_DIR
  eval "$(apt-config shell PIN_DIR Dir::Etc::PreferencesParts/d)"
  local PIN_FILE="${PIN_DIR%/}/99${1}"

  if [ ! -f "$PIN_FILE" ]; then

    fxInfo "${PIN_FILE} not found, nothing to unpin"
    return 0
  fi

  local PIN_SUDO=
  if [ ! -w "$PIN_DIR" ]; then
    PIN_SUDO=sudo
  fi

  $PIN_SUDO rm -f "$PIN_FILE"
  fxOK "${PIN_FILE} removed: Ubuntu's packages are installable again"
}
