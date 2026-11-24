#!/usr/bin/env bash
# Links this repo's configs into ~/.config (symlinks), backing up whatever was there.
# Usage: scripts/install.sh [--sddm]     (--sddm also installs the login theme; asks for sudo)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d-%H%M%S)"
APPS=(hypr fastfetch MangoHud matugen spicetify)

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
