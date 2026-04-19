#!/usr/bin/env bash
# Download Steam CDN art for each non-Steam shortcut and place it in
# ~/.steam/steam/userdata/<id>/config/grid/ keyed by the shortcut appid.
#
# Reads STEAM_USERID3, STEAM_ROOT, and the games list from manifest.py in
# the current directory. Run from your working dir (e.g. ~/Games-migration/).
set -euo pipefail

USERID3=$(python3 -c "from manifest import STEAM_USERID3; print(STEAM_USERID3)")
STEAM_ROOT=$(python3 -c "from manifest import STEAM_ROOT; print(STEAM_ROOT)")
GRID_DIR="$STEAM_ROOT/userdata/$USERID3/config/grid"
mkdir -p "$GRID_DIR"

python3 - <<'PY' > /tmp/games-art.tsv
from build_shortcuts import shortcut_appid
from manifest import GAMES
for g in GAMES:
    aid = shortcut_appid(str(g['exe']), g['name'])
    print(f"{aid}\t{g['steam_appid']}\t{g['name']}")
PY

CDN="https://steamcdn-a.akamaihd.net/steam/apps"
while IFS=$'\t' read -r appid steam_appid name; do
    echo "-- $name (shortcut=$appid steam=$steam_appid) --"

    [ -s "$GRID_DIR/${appid}p.jpg" ] || {
      curl -sfL -o "$GRID_DIR/${appid}p.jpg" "$CDN/$steam_appid/library_600x900.jpg" \
        && echo "  portrait ok" || { echo "  portrait FAIL"; rm -f "$GRID_DIR/${appid}p.jpg"; }
    }

    [ -s "$GRID_DIR/${appid}_hero.jpg" ] || {
      curl -sfL -o "$GRID_DIR/${appid}_hero.jpg" "$CDN/$steam_appid/library_hero.jpg" \
        && echo "  hero ok" || { echo "  hero FAIL"; rm -f "$GRID_DIR/${appid}_hero.jpg"; }
    }

    [ -s "$GRID_DIR/${appid}_logo.png" ] || {
      curl -sfL -o "$GRID_DIR/${appid}_logo.png" "$CDN/$steam_appid/logo.png" \
        && echo "  logo ok" || { echo "  logo FAIL"; rm -f "$GRID_DIR/${appid}_logo.png"; }
    }

    [ -s "$GRID_DIR/${appid}.jpg" ] || {
      curl -sfL -o "$GRID_DIR/${appid}.jpg" "$CDN/$steam_appid/header.jpg" \
        && echo "  grid ok" || { echo "  grid FAIL"; rm -f "$GRID_DIR/${appid}.jpg"; }
    }

    if [ -s "$GRID_DIR/${appid}p.jpg" ] && ! [ -s "$GRID_DIR/${appid}_icon.png" ]; then
      if command -v convert >/dev/null 2>&1; then
        convert "$GRID_DIR/${appid}p.jpg" -gravity center -crop 600x600+0+0 +repage \
                -resize 256x256 "$GRID_DIR/${appid}_icon.png" 2>/dev/null \
          && echo "  icon ok" || echo "  icon FAIL (imagemagick)"
      else
        echo "  icon SKIP (install imagemagick for auto-derive)"
      fi
    fi
done < /tmp/games-art.tsv

echo
echo "Art placed in $GRID_DIR/"
