#!/usr/bin/env bash
# Links this repo's configs into ~/.config (symlinks), backing up whatever was there.
# Usage: scripts/install.sh [--sddm]     (--sddm also installs the login theme; asks for sudo)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d-%H%M%S)"
APPS=(hypr fastfetch MangoHud matugen spicetify VSCodium)

for app in "${APPS[@]}"; do
  while IFS= read -r -d '' src; do
    rel="${src#"$REPO"/}"
    dst="$CONF/$rel"
    mkdir -p "$(dirname "$dst")"
    if [ -L "$dst" ] && [ "$(realpath -m "$dst")" = "$src" ]; then
      continue                                   # already linked
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
      mv "$dst" "$dst.bak-$STAMP"
      echo "backup: $dst.bak-$STAMP"
    fi
    link_target="$(realpath --relative-to="$(dirname "$dst")" "$src")"
    ln -s "$link_target" "$dst"
    echo "link:   $dst -> $link_target"
  done < <(find "$REPO/$app" -type f -print0)
done

# systemd refuses to enable symlinked unit files, so units are copied instead of linked.
UNIT_DIR="$CONF/systemd/user"
UNITS=(spicetify-matugen.path spicetify-matugen.service)
if command -v systemctl >/dev/null && command -v spicetify >/dev/null; then
  mkdir -p "$UNIT_DIR"
  for unit in "${UNITS[@]}"; do
    install -m644 "$REPO/systemd/user/$unit" "$UNIT_DIR/$unit"
    echo "copy:   $UNIT_DIR/$unit"
  done
  systemctl --user daemon-reload
  systemctl --user enable --now spicetify-matugen.path >/dev/null 2>&1 && echo "enabled: spicetify-matugen.path"
  spicetify config current_theme Matugen color_scheme Matugen >/dev/null && echo "spicetify: theme set to Matugen (run 'spicetify apply' once)"
fi

# VSCodium: the Matugen color theme is a tiny local extension. Matugen writes its two theme files;
# here we copy package.json (not a link, VSCodium rewrites extensions.json) and register it.
EXT_ID="local.matugen-theme"; EXT_DIR="$HOME/.vscode-oss/extensions/$EXT_ID-1.0.0"
if command -v codium >/dev/null || command -v vscodium >/dev/null; then
  if pgrep -x codium >/dev/null; then
    echo "VSCodium is running: close it and run this script again to register the Matugen theme." >&2
  else
    mkdir -p "$EXT_DIR/themes"
    install -m644 "$REPO/vscodium-extension/package.json" "$EXT_DIR/package.json"
    python3 - "$HOME/.vscode-oss/extensions/extensions.json" "$EXT_DIR" "$EXT_ID" <<'PY'
import json, os, sys, time
path, loc, ext_id = sys.argv[1:4]
data = json.load(open(path)) if os.path.exists(path) else []
data = [e for e in data if e["identifier"]["id"] != ext_id]
data.append({"identifier": {"id": ext_id}, "version": "1.0.0",
  "location": {"$mid": 1, "fsPath": loc, "external": "file://" + loc, "path": loc, "scheme": "file"},
  "relativeLocation": os.path.basename(loc),
  "metadata": {"isApplicationScoped": False, "isMachineScoped": False, "isBuiltin": False,
               "installedTimestamp": int(time.time() * 1000), "pinned": False, "source": "resource",
               "updated": False, "private": False, "isPreReleaseVersion": False,
               "hasPreReleaseVersion": False, "preRelease": False}})
os.makedirs(os.path.dirname(path), exist_ok=True)
json.dump(data, open(path, "w"))
PY
    echo "vscodium: Matugen theme registered (change the wallpaper once so Matugen writes the theme files)"
  fi
fi

if [ "${1:-}" = "--sddm" ]; then
  theme_src="$REPO/sddm/themes/corners"
  echo "Installing SDDM theme overlay (needs sudo)..."
  if [ ! -d /usr/share/sddm/themes/corners ]; then
    echo "Base theme missing. Install 'sddm-theme-corners' first (https://github.com/aczw/sddm-theme-corners)." >&2
    exit 1
  fi
  sudo -S -p '' install -Dm644 "$theme_src/theme.conf" /usr/share/sddm/themes/corners/theme.conf
  sudo -S -p '' install -Dm644 "$theme_src/backgrounds/MIKA.PNG" /usr/share/sddm/themes/corners/backgrounds/MIKA.PNG
  printf '[Theme]\nCurrent=corners\n' | sudo -S -p '' tee /etc/sddm.conf.d/theme.conf >/dev/null
fi

command -v hyprctl >/dev/null && hyprctl reload >/dev/null 2>&1 && echo "Hyprland reloaded." || true
echo "Done."
