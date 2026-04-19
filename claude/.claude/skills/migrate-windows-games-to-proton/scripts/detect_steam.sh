#!/usr/bin/env bash
# Print discovered Steam state: install path, userid3, config paths,
# currently installed Proton builds. Safe to run while Steam is running.
set -euo pipefail

STEAM="${HOME}/.steam/steam"
if [ ! -d "$STEAM" ]; then
  STEAM="${HOME}/.local/share/Steam"
fi
if [ ! -d "$STEAM" ]; then
  echo "ERROR: could not find Steam install at ~/.steam/steam or ~/.local/share/Steam" >&2
  exit 1
fi

echo "STEAM_ROOT=$STEAM"

USERS=("$STEAM"/userdata/*)
if [ "${USERS[0]}" = "$STEAM/userdata/*" ]; then
  echo "NO_USERDATA=true (log into Steam at least once before migrating)"
  exit 0
fi
for u in "${USERS[@]}"; do
  [ -d "$u" ] || continue
  id=$(basename "$u")
  name=$(grep -A3 '"AccountName"' "$STEAM/config/loginusers.vdf" 2>/dev/null | head -4 | tail -1 || echo)
  echo "USERID3=$id"
done

echo
echo "PROTON_COMPAT_TOOLS (from compatibilitytools.d):"
if [ -d "$STEAM/compatibilitytools.d" ]; then
  ls -1 "$STEAM/compatibilitytools.d" | sed 's/^/  /'
else
  echo "  (none)"
fi

echo
echo "PROTON_INSTALLS (from steamapps/common):"
ls -1 "$STEAM/steamapps/common" 2>/dev/null | grep -iE '^Proton' | sed 's/^/  /' || echo "  (none)"

echo
echo "STEAM_RUNNING=$(pgrep -f 'Steam/ubuntu12_32/steam\b' >/dev/null && echo yes || echo no)"
