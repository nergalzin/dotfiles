# dotfiles

My Arch / CachyOS desktop setup. One wallpaper decides the colors of the whole system: Hyprland, Spotify, Discord, Feishin, Obsidian, VSCodium and Hermes all repaint when it changes.

Maintained by [@nergalzin](https://github.com/nergalzin).

## Quick start

```bash
git clone https://github.com/nergalzin/dotfiles.git ~/dotfiles
cd ~/dotfiles
scripts/install.sh
```

Then change the wallpaper once so the colors are generated, and follow [Turn the themes on](#turn-the-themes-on).

Before you run it, read [Requirements](#requirements) and [What the installer does](#what-the-installer-does).

---

## Requirements

Required:

- Hyprland **with the Lua config** (tested on 0.57).
- A shell based on [illogical-impulse](https://github.com/end-4/dots-hyprland) already installed in `~/.config/hypr/`. `hypr/hyprland.lua` loads its `hyprland.*` modules.
- [Matugen](https://github.com/InioX/matugen), which creates every color file.

Optional, install only what you use:

| For | Packages |
|---|---|
| Fastfetch layout | `fastfetch` |
| Game HUD | `mangohud` |
| Music | `feishin`, `spotify-launcher` + `spicetify-cli` |
| Login screen | `sddm` + [`sddm-theme-corners`](https://github.com/aczw/sddm-theme-corners), font Atkinson Hyperlegible |
| Rebuilding the MangoHud font | `ttf-jetbrains-mono-nerd` |

---

## What the installer does

`scripts/install.sh` walks through `hypr`, `fastfetch`, `MangoHud`, `matugen`, `spicetify` and `VSCodium` and, for every file inside:

1. Moves anything already at the destination to `<file>.bak-<date>`.
2. Creates a **relative symlink** in `~/.config` that points back to this repo (no username is written into the link).
3. Skips files that are already linked, so you can run it again at any time.

Then it:

- **Copies** (not links) the two `systemd/user/spicetify-matugen.*` units, because systemd refuses to enable symlinked units, and enables the path unit.
- Selects the `Matugen` theme in Spicetify.
- Registers the Matugen color theme as a small local VSCodium extension (`vscodium-extension/package.json` is **copied** to `~/.vscode-oss/extensions/local.matugen-theme-1.0.0/` and added to `extensions.json`). Close VSCodium first; the script asks you to re-run it if it is open.
- Runs `hyprctl reload`.

With `--sddm` it also uses `sudo` to copy the SDDM theme settings and wallpaper into `/usr/share/sddm/themes/corners/` and to write `/etc/sddm.conf.d/theme.conf`. Skip that flag if you don't use SDDM.

Because the files are links, editing `~/.config/hypr/custom/keybinds.lua` edits the copy in this repo. **Do not move or delete the repo folder** while the links are in use.

---

## How the colors work

```
wallpaper changes
      │
      ▼
   Matugen  ── reads ~/.config/matugen/config.toml
      │
      ├─► matugen/templates/feishin/          → Feishin: Matugen Dark / Light
      ├─► matugen/templates/spicetify/        → Spotify color scheme ─► systemd path unit ─► spicetify refresh
      ├─► matugen/templates/vesktop/          → Discord (Vesktop) theme
      ├─► matugen/templates/obsidian/         → Obsidian CSS snippet
      ├─► matugen/templates/vscodium/         → VSCodium: Matugen Dark / Light color themes
      └─► matugen/templates/hermes/           → Hermes skin
```

`matugen/config.toml` also keeps the shell's own templates (colors, Hyprland, hyprlock, fuzzel, GTK, KDE), so replacing the file does not break the shell.

| Template | Written to |
|---|---|
| `feishin/*` | `~/.config/feishin/Themes/` |
| `spicetify/color.ini` | `~/.config/spicetify/Themes/Matugen/color.ini` |
| `vesktop/matugen.theme.css` | `~/.config/vesktop/themes/matugen.theme.css` |
| `obsidian/matugen.css` | `~/Documents/Obsidian/.obsidian/snippets/matugen.css` |
| `vscodium/matugen-{dark,light}-color-theme.json` | `~/.vscode-oss/extensions/local.matugen-theme-1.0.0/themes/` |
| `hermes/matugen.yaml` | `~/.hermes/skins/matugen.yaml` |

The generated files are **not** tracked in this repo; Matugen recreates them on every change. The same goes for the rest of each app's folder: `~/.config/feishin` holds server logins and `config-xpui.ini` holds machine paths, so only templates and theme files live here.

### Turn the themes on

Each app needs a one-time switch:

| App | What to do |
|---|---|
| Feishin | Settings → Appearance → pick **Matugen Dark** and **Matugen Light**, turn on **Use theme accent color** |
| Discord (Vesktop) | Settings → Themes → turn on **Matugen** |
| Obsidian | Settings → Appearance → CSS snippets → turn on **matugen** (made for the [Primary](https://github.com/ceciliamay/primary) theme) |
| VSCodium | Already selected by `VSCodium/User/settings.json`: **Matugen Dark** or **Matugen Light**, following the system dark/light mode. After a wallpaper change, reload the window (`Ctrl+Shift+P` → *Developer: Reload Window*) if the colors do not update by themselves. |
| Hermes | `hermes config set display.skin matugen` |
| Spotify | Close it and run `spicetify apply` once. After a Spotify update: `spicetify restore backup apply` |

---

## Repository layout

```
dotfiles/
├── hypr/
│   ├── hyprland.lua            entry point of the Lua config
│   └── custom/
│       ├── general.lua         mouse and keyboard layout
│       └── keybinds.lua        personal keybinds
├── matugen/
│   ├── config.toml
│   └── templates/              one folder per themed app
├── fastfetch/config.jsonc
├── MangoHud/                   HUD theme + brand-logo font (fonts/build_font.py rebuilds it)
├── spicetify/Themes/Matugen/   Spotify theme CSS
├── systemd/user/               spicetify-matugen.path / .service
├── VSCodium/User/settings.json selects the Matugen themes in VSCodium
├── vscodium-extension/         package.json of the local Matugen theme extension
├── sddm/themes/corners/        login screen settings and wallpaper
└── scripts/                    install.sh and uninstall.sh
```

---

## Configuration details

### Hyprland

- `hyprland.lua` loads the shell modules first and `custom/` last, so your files win. It also binds `Super + I` to the shell settings and sets the layouts `us,br`.
- `custom/general.lua`: mouse without acceleration (`flat` profile) and `Alt + Shift` to switch layout.

### Keybinds

| Shortcut | Action |
|---|---|
| `Ctrl + Super + H` | Hermes |
| `Ctrl + Super + C` | Helium browser |
| `Ctrl + Super + L` | LibreWolf |
| `Ctrl + Super + O` | Obsidian |
| `Ctrl + Super + G` | Gamerdeck |
| `Ctrl + Shift + A` | Armada (Flatpak) |
| `Ctrl + Shift + D` | Vesktop |
| `Super + Shift + D` | Duck.ai quick window |
| `Super + Shift + T` | System info and temperatures |
| `Super + I` | Shell settings |
| `Ctrl + Super + Alt + Slash` | Edit `custom/keybinds.lua` |

`Super + Shift + D` and `Super + Shift + T` call features of the [Void](https://github.com/nergalzin/Void) shell. On another shell they do nothing.

Check that a key is free before binding it: `hyprctl binds | grep -B4 -A6 "key: H$"`.

### Spotify refresh

The systemd path unit watches the Spotify color file. When Matugen rewrites it, the service runs `spicetify -q -n refresh`. The `-n` means Spotify is **not** restarted; the new colors appear the next time it opens. To restart it automatically, remove `-n` from `systemd/user/spicetify-matugen.service` and run `scripts/install.sh` again.

---

## Update

```bash
cd ~/dotfiles
git pull
hyprctl reload
```

## Uninstall

```bash
cd ~/dotfiles
scripts/uninstall.sh            # remove the links and restore the newest .bak-* of each file
scripts/uninstall.sh --sddm     # also remove the SDDM overlay (asks for sudo)
rm -rf ~/dotfiles               # only after the script finished
```

It also disables and removes the systemd units. After `--sddm`, reinstall the `sddm-theme-corners` package to get its default `theme.conf` back.

---

## Troubleshooting

| Problem | What to try |
|---|---|
| Hyprland shows errors after the install | `hyprctl configerrors`. A shell update may have changed `hyprland.lua`; the old file is saved as `hyprland.lua.bak-<date>`, merge the differences by hand. |
| Colors did not change | Matugen only writes when the wallpaper or palette changes. Pick the wallpaper again in the shell. |
| Obsidian vault is somewhere else | Edit `output_path` of `[templates.obsidian]` in `matugen/config.toml`, then change the wallpaper. |
| Spotify keeps the old colors | Reopen it, or see [Spotify refresh](#spotify-refresh). |
| A keybind does nothing | Check the key is free (command above) and that the app is installed. |

---

## Credits

- [@end-4](https://github.com/end-4): [dots-hyprland](https://github.com/end-4/dots-hyprland) (illogical-impulse)
- [InioX/matugen](https://github.com/InioX/matugen)
- [@aczw](https://github.com/aczw): [sddm-theme-corners](https://github.com/aczw/sddm-theme-corners)
- [@ceciliamay](https://github.com/ceciliamay): [Primary](https://github.com/ceciliamay/primary) theme for Obsidian
