#!/usr/bin/env bash
# ubuntu-macos-look installer. Double-click (Run as a Program) or: bash install.sh
# Re-running is safe; it updates everything in place.
set -euo pipefail

REPO_URL=https://github.com/akshitzaveri/ubuntu-macos-look.git

here=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo /nonexistent)
# Run via `curl … | bash`? Fetch the full repo and hand over to its copy of this script.
if [[ ! -f $here/lib/common.sh ]]; then
  command -v git >/dev/null || { echo "Installing git…"; sudo apt-get install -y git </dev/tty; }
  dest=$HOME/.cache/ubuntu-macos-look/repo
  rm -rf "$dest"; git clone -q --depth 1 "$REPO_URL" "$dest"
  exec bash "$dest/install.sh" "$@" </dev/tty
fi

source "$here/lib/common.sh"
ensure_terminal "$@"
trap pause_on_exit EXIT
require_gnome

VERSION_STAMP="$MACTAHOE_GTK_COMMIT $MACTAHOE_ICON_COMMIT $WHITESUR_CURSORS_COMMIT"
if [[ $here == "$HOME/.cache/ubuntu-macos-look/repo" ]]; then   # started via curl | bash
  RERUN="run the same command again:
     curl -fsSL https://raw.githubusercontent.com/akshitzaveri/ubuntu-macos-look/main/install.sh | bash"
  VERIFY="~/.cache/ubuntu-macos-look/repo/verify.sh"
else
  RERUN="right-click install.sh → Run as a Program (or: bash install.sh)"
  VERIFY="right-click verify.sh → Run as a Program (or: bash verify.sh)"
fi

banner() { echo; echo "${2}${B}════════════════════════════════════════════════════════════${N}"; echo "${2}${B}  $1${N}"; echo "${2}${B}════════════════════════════════════════════════════════════${N}"; }

# Second run (after logging back in): turn everything on and check, no re-download.
finish() {
  step "Finishing setup"
  for e in "$USER_THEME" "${EXTENSIONS[@]}"; do gnome-extensions enable "$e" 2>/dev/null || true; done
  for e in ubuntu-dock@ubuntu.com ding@rastersoft.com; do gnome-extensions disable "$e" 2>/dev/null || true; done
  "$HOME/.local/bin/macos-theme-switch" >/dev/null
  systemctl --user restart macos-theme-watch.service
  sleep 1
  if out=$(bash "$here/verify.sh" --inline 2>&1); then
    banner "ALL DONE ✅  Your Mac look is installed." "$G"
    cat <<EOF

  Now confirm it: $VERIFY
  It should say "All checks passed".

  Then set up backups from the app grid:
    • Backups (Déjà Dup): external drive or Google Drive, Back Up Automatically
    • Timeshift: RSYNC, ~5 daily snapshots
  Undo everything any time with uninstall.sh.
EOF
  else
    echo "$out"
    banner "NOT QUITE YET — log out and back in, then run the installer again" "$Y"
    echo; echo "  To run it again, $RERUN"
    echo "  If this keeps happening, open an issue with a screenshot of this window."
  fi
}

if [[ ${1:-} != --reinstall && -f $STATE_DIR/installed && $(cat "$STATE_DIR/installed") == "$VERSION_STAMP" ]]; then
  echo "${B}ubuntu-macos-look${N} is already installed — finishing setup. (Use --reinstall to install again.)"
  finish
  exit 0
fi

cat <<EOF
${B}ubuntu-macos-look${N} — a macOS-style desktop for Ubuntu (GNOME $SHELL_MAJOR)

This will install, for your user only:
  • MacTahoe GTK + top-bar themes, MacTahoe icons, WhiteSur cursor, wallpapers
  • Dash to Dock (locked, macOS-style) and Blur my Shell
  • Window buttons on the left, opaque Quick Settings in light and dark
  • Automatic light (07:00) / dark (18:00) switching that also follows the Dark Style toggle
  • "Toggle Appearance" in app search + Super+Shift+A shortcut
  • Déjà Dup (Backups) and Timeshift — you configure these afterwards
It asks for your password once, for apt packages. Your current settings are backed up first.
EOF
read -rp "Continue? [Y/n] " ans </dev/tty
[[ ${ans:-Y} =~ ^[Yy]$ ]] || exit 0

step "1/8 Packages (needs your password)"
sudo apt-get update -qq </dev/tty
sudo apt-get install -y git curl unzip sassc libglib2.0-dev-bin libxml2-utils python3 \
  gnome-shell-extensions deja-dup timeshift </dev/tty

step "2/8 Backing up your current settings"
mkdir -p "$STATE_DIR"
if [[ ! -f $STATE_DIR/original-settings.done ]]; then
  for p in "${TOUCHED_PATHS[@]}"; do dconf dump "$p" > "$STATE_DIR/orig$(tr / _ <<<"$p").dconf"; done
  for k in enabled-extensions disabled-extensions; do gsettings get org.gnome.shell $k > "$STATE_DIR/orig-$k"; done
  gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings > "$STATE_DIR/orig-custom-keybindings"
  [[ -e $HOME/.config/gtk-4.0 ]] && cp -a "$HOME/.config/gtk-4.0" "$STATE_DIR/gtk-4.0.orig"
  for e in "${EXTENSIONS[@]}"; do
    [[ -d $HOME/.local/share/gnome-shell/extensions/$e ]] && echo "$e" >> "$STATE_DIR/preexisting-extensions"
  done
  touch "$STATE_DIR/original-settings.done"
  echo "Saved to $STATE_DIR"
else
  echo "Already backed up on first install — keeping that copy."
fi

fetch() {  # fetch <repo> <commit> → $CACHE_DIR/<repo>
  local d=$CACHE_DIR/$1
  if [[ ! -d $d/.git ]]; then rm -rf "$d"; git init -q "$d"; git -C "$d" remote add origin "https://github.com/vinceliuice/$1.git"; fi
  git -C "$d" fetch -q --depth 1 origin "$2" && git -C "$d" checkout -q --force FETCH_HEAD
}

step "3/8 Downloading themes (pinned versions)"
mkdir -p "$CACHE_DIR"
fetch MacTahoe-gtk-theme  "$MACTAHOE_GTK_COMMIT"
fetch MacTahoe-icon-theme "$MACTAHOE_ICON_COMMIT"
fetch WhiteSur-cursors    "$WHITESUR_CURSORS_COMMIT"

step "4/8 Installing themes"
export TERM=${TERM:-xterm-256color}   # MacTahoe's installer silently fails without TERM
cd "$CACHE_DIR/MacTahoe-gtk-theme"
./install.sh -o normal -o solid -t blue -c light -c dark </dev/null >/dev/null \
  || die "MacTahoe GTK theme install failed"
# libadwaita (GTK4) files go to ~/.config/gtk-4.0; send its theme copy to a throwaway dir
tmp=$(mktemp -d); ./install.sh -l -o solid -t blue -c light -c dark -d "$tmp" </dev/null >/dev/null \
  || die "MacTahoe libadwaita install failed"; rm -rf "$tmp"
ln -sfn "$HOME/.config/gtk-4.0/gtk-Dark.css" "$HOME/.config/gtk-4.0/gtk-dark.css"
# it also installs an unrelated "theme switcher" app; remove it to avoid confusion
rm -f "$HOME/.local/share/applications/org.gnome.GTK4ThemeSwitcher.desktop" "$HOME/.local/bin/gnome-theme-switcher"
mkdir -p "$HOME/.local/share/backgrounds/MacTahoe"
cp wallpaper/MacTahoe-{day,night}.jpeg "$HOME/.local/share/backgrounds/MacTahoe/"
python3 -I "$here/lib/make-fixed-shell-theme.py" "$HOME/.themes" Light
python3 -I "$here/lib/make-fixed-shell-theme.py" "$HOME/.themes" Dark
(cd "$CACHE_DIR/MacTahoe-icon-theme" && ./install.sh </dev/null >/dev/null) || die "icon theme install failed"
(cd "$CACHE_DIR/WhiteSur-cursors" && ./install.sh </dev/null >/dev/null) || die "cursor install failed"
echo "Themes, icons, cursor and wallpapers installed."

step "5/8 GNOME extensions"
for e in "${EXTENSIONS[@]}"; do
  url=$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=$e&shell_version=$SHELL_MAJOR" \
        | python3 -c 'import sys,json; print(json.load(sys.stdin)["download_url"])') \
    || die "$e has no release for GNOME $SHELL_MAJOR yet"
  curl -fsSL "https://extensions.gnome.org$url" -o "$CACHE_DIR/$e.zip"
  gnome-extensions install --force "$CACHE_DIR/$e.zip"
  echo "  $e"
done
for e in "$USER_THEME" "${EXTENSIONS[@]}"; do
  list_edit enabled-extensions add "$e"; list_edit disabled-extensions remove "$e"
done
for e in ubuntu-dock@ubuntu.com ding@rastersoft.com; do   # Ubuntu's own dock and desktop icons
  list_edit enabled-extensions remove "$e"; list_edit disabled-extensions add "$e"
done

step "6/8 Settings"
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors'
D=/org/gnome/shell/extensions/dash-to-dock
dconf write $D/dock-position "'BOTTOM'";     dconf write $D/extend-height false
dconf write $D/dock-fixed true;              dconf write $D/autohide false
dconf write $D/intellihide false;            dconf write $D/dash-max-icon-size 48
dconf write $D/running-indicator-style "'DOTS'"; dconf write $D/custom-theme-shrink true
dconf write $D/show-mounts false;            dconf write $D/show-apps-at-top true
BL=/org/gnome/shell/extensions/blur-my-shell
dconf write $BL/applications/blur false   # blurs a square behind rounded menus
dconf write $BL/popup/blur false          # themes draw opaque popups; blur leaves gray corners

step "7/8 Light/dark automation, Toggle Appearance, Super+Shift+A"
install -Dm755 -t "$HOME/.local/bin" "$here"/bin/macos-theme-{switch,watch,toggle}
install -Dm644 -t "$HOME/.config/systemd/user" "$here"/systemd/*
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/macos-theme-toggle.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Toggle Appearance
Comment=Switch between light and dark mode
Keywords=dark;light;mode;theme;appearance;
Exec=$HOME/.local/bin/macos-theme-toggle
Icon=preferences-desktop-theme
EOF
MK=org.gnome.settings-daemon.plugins.media-keys
python3 -I - "$KEYBINDING" <<'EOF'
import ast, subprocess, sys
key = 'org.gnome.settings-daemon.plugins.media-keys'
cur = subprocess.run(['gsettings', 'get', key, 'custom-keybindings'], capture_output=True, text=True).stdout.strip()
items = [] if cur.startswith('@as') else ast.literal_eval(cur)
if sys.argv[1] not in items: items.append(sys.argv[1])
subprocess.run(['gsettings', 'set', key, 'custom-keybindings', str(items)], check=True)
EOF
gsettings set $MK.custom-keybinding:$KEYBINDING name 'Toggle Appearance'
gsettings set $MK.custom-keybinding:$KEYBINDING command "$HOME/.local/bin/macos-theme-toggle"
gsettings set $MK.custom-keybinding:$KEYBINDING binding '<Super><Shift>a'
systemctl --user daemon-reload
systemctl --user enable --now macos-theme-switch.timer
systemctl --user enable macos-theme-watch.service
"$HOME/.local/bin/macos-theme-switch"
systemctl --user restart macos-theme-watch.service

echo "$VERSION_STAMP" > "$STATE_DIR/installed"

step "8/8 Checking"
all_active=1
for e in "$USER_THEME" "${EXTENSIONS[@]}"; do [[ $(ext_state "$e") == ACTIVE ]] || all_active=0; done
if (( all_active )); then
  finish          # extensions were already loaded (e.g. a reinstall) — no logout needed
else
  banner "STEP 1 OF 2 DONE — now log out and log back in" "$Y"
  cat <<EOF

  GNOME only turns on new extensions (the dock, blur) when you log in.
  A restart is not needed.

  1. Log out:   top-right menu → ⏻ → Log Out
  2. Log back in
  3. Run the installer again — it only takes a few seconds the second time:
     $RERUN

  It will say ${B}ALL DONE ✅${N} when everything is ready.
EOF
fi
