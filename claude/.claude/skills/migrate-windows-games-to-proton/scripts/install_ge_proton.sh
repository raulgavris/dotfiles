#!/usr/bin/env bash
# Download and install the latest GE-Proton release into
# ~/.steam/steam/compatibilitytools.d/. Steam picks it up without restart.
#
# Usage:
#   install_ge_proton.sh            # latest
#   install_ge_proton.sh GE-Proton10-34   # pinned version
set -euo pipefail

STEAM="${HOME}/.steam/steam"
[ -d "$STEAM" ] || STEAM="${HOME}/.local/share/Steam"
COMPAT="$STEAM/compatibilitytools.d"
mkdir -p "$COMPAT"

if [ $# -ge 1 ]; then
  TAG="$1"
  URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${TAG}/${TAG}.tar.gz"
else
  URL=$(curl -sSL https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest \
        | grep browser_download_url | grep '\.tar\.gz"' | head -1 | cut -d'"' -f4)
  TAG=$(basename "$URL" .tar.gz)
fi

if [ -d "$COMPAT/$TAG" ]; then
  echo "$TAG already installed at $COMPAT/$TAG"
  exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
echo "Downloading $TAG from $URL ..."
curl -fL --progress-bar -o "$TMP/proton.tar.gz" "$URL"
echo "Extracting ..."
tar -xzf "$TMP/proton.tar.gz" -C "$COMPAT/"
echo "Installed: $COMPAT/$TAG"
echo
echo "Set this as compat tool for your non-Steam shortcuts by using"
echo "  PROTON_NAME = \"$TAG\"  in manifest.py"
