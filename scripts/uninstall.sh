#!/usr/bin/env bash
# Removes the symlinks created by install.sh and restores the newest backup of each file.
# Usage: scripts/uninstall.sh [--sddm]     (--sddm also removes the login theme overlay)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
APPS=(hypr fastfetch MangoHud matugen spicetify VSCodium)

UNIT_DIR="$CONF/systemd/user"
UNITS=(spicetify-matugen.path spicetify-matugen.service)
if command -v systemctl >/dev/null; then
  systemctl --user disable --now spicetify-matugen.path >/dev/null 2>&1 || true
fi
for unit in "${UNITS[@]}"; do
  if [ -f "$UNIT_DIR/$unit" ] && cmp -s "$UNIT_DIR/$unit" "$REPO/systemd/user/$unit"; then
    rm "$UNIT_DIR/$unit"
    echo "removed: $UNIT_DIR/$unit"
  fi
done
command -v systemctl >/dev/null && systemctl --user daemon-reload || true

for app in "${APPS[@]}"; do
  while IFS= read -r -d '' src; do
    dst="$CONF/${src#"$REPO"/}"
    if [ -L "$dst" ] && [ "$(realpath -m "$dst")" = "$src" ]; then
      rm "$dst"
      echo "removed: $dst"
      latest="$(ls -1d "$dst".bak-* 2>/dev/null | sort | tail -n1 || true)"
      if [ -n "$latest" ]; then
        mv "$latest" "$dst"
        echo "restored: $dst"
      fi
    fi
  done < <(find "$REPO/$app" -type f -print0)
done

# VSCodium: remove the local Matugen theme extension and its extensions.json entry.
EXT_ID="local.matugen-theme"; EXT_DIR="$HOME/.vscode-oss/extensions/$EXT_ID-1.0.0"
if [ -d "$EXT_DIR" ]; then
  if pgrep -x codium >/dev/null; then
    echo "VSCodium is running: close it and run this script again to remove the Matugen theme." >&2
  else
    rm -rf "$EXT_DIR"
    python3 - "$HOME/.vscode-oss/extensions/extensions.json" "$EXT_ID" <<'PY'
import json, os, sys
path, ext_id = sys.argv[1:3]
if os.path.exists(path):
    data = [e for e in json.load(open(path)) if e["identifier"]["id"] != ext_id]
    json.dump(data, open(path, "w"))
PY
    echo "removed: $EXT_DIR"
  fi
fi

if [ "${1:-}" = "--sddm" ]; then
  sudo -S -p '' rm -f /usr/share/sddm/themes/corners/theme.conf \
             /usr/share/sddm/themes/corners/backgrounds/MIKA.PNG \
             /etc/sddm.conf.d/theme.conf
  echo "SDDM overlay removed (reinstall the base theme package to restore its default theme.conf)."
fi

command -v hyprctl >/dev/null && hyprctl reload >/dev/null 2>&1 && echo "Hyprland reloaded." || true
echo "Done."
