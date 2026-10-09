#!/usr/bin/env bash
# More macOS: Spotlight, Quick Look, Apple menu, menu-bar clock, Inter font, rounded corners,
# ⌘⇧3/4/5 screenshots, two-finger right click. Run after install.sh (right-click → Run as a Program).
# Like install.sh it takes two runs with a log out in between; re-running is always safe.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
source "$here/lib/common.sh"
ensure_terminal "$@"
trap pause_on_exit EXIT
require_gnome

# Search Light (a Spotlight-style popup) is left out: it crashes GNOME Shell 50 (icedman/search-light#166,#170)
EXTRA_EXTENSIONS=(just-perfection-desktop@just-perfection logomenu@aryan_k rounded-window-corners@fxgn)
EXTRA_PATHS=(/org/gnome/shell/extensions/just-perfection/
             /org/gnome/shell/extensions/Logo-menu/ /org/gnome/shell/extensions/rounded-window-corners-reborn/
             /org/gnome/shell/keybindings/ /org/gnome/desktop/wm/keybindings/ /org/gnome/desktop/peripherals/touchpad/)

[[ -d $HOME/.themes/MacTahoe-Light-blue-fixed ]] || die "Run install.sh first."

step "1/5 Packages (needs your password)"
sudo apt-get install -y gnome-sushi fonts-inter </dev/tty

step "2/5 Backing up settings"
mkdir -p "$STATE_DIR"
if [[ ! -f $STATE_DIR/extras-settings.done ]]; then
  for p in "${EXTRA_PATHS[@]}"; do dconf dump "$p" > "$STATE_DIR/extras$(tr / _ <<<"$p").dconf"; done
  touch "$STATE_DIR/extras-settings.done"
fi

step "3/5 Extensions: menu bar (Just Perfection), Apple menu (Logo Menu), rounded corners"
for e in "${EXTRA_EXTENSIONS[@]}"; do
  url=$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=$e&shell_version=$SHELL_MAJOR" \
        | python3 -c 'import sys,json; print(json.load(sys.stdin)["download_url"])') \
    || die "$e has no release for GNOME $SHELL_MAJOR yet"
  curl -fsSL "https://extensions.gnome.org$url" -o "$CACHE_DIR/$e.zip"
  gnome-extensions install --force "$CACHE_DIR/$e.zip"
  list_edit enabled-extensions add "$e"; list_edit disabled-extensions remove "$e"
  echo "  $e"
done

step "4/5 Settings"
# Apple menu icon: MacTahoe ships white and black Apple logos; macos-theme-switch swaps them per mode
icons=$STATE_DIR/icons; mkdir -p "$icons"
src=$CACHE_DIR/MacTahoe-gtk-theme/src/assets/gnome-shell
cp "$src/activities/activities-apple.svg"       "$icons/apple-white.svg"
cp "$src/activities-black/activities-apple.svg" "$icons/apple-black.svg"
L=/org/gnome/shell/extensions/Logo-menu
dconf write $L/use-custom-icon true
dconf write $L/symbolic-icon false
dconf write $L/menu-button-icon-size 18
dconf write $L/show-activities-button false
dconf write $L/menu-button-terminal "'ptyxis'"
command -v snap-store >/dev/null && dconf write $L/menu-button-software-center "'snap-store'"

J=/org/gnome/shell/extensions/just-perfection
dconf write $J/support-notifier-type 0          # no donation pop-ups
dconf write $J/activities-button false          # the Apple menu replaces it
dconf write $J/clock-menu-position 1            # clock on the right, like the macOS menu bar
dconf write $J/clock-menu-position-offset 20    # …at the far end
dconf write $J/notification-banner-position 2   # notifications top-right
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface clock-show-weekday true

# Spotlight: Super+Space opens GNOME search (only take it from the keyboard-layout switch if there's one layout)
nsrc=$(gsettings get org.gnome.desktop.input-sources sources | grep -o "('" | wc -l)
if (( nsrc <= 1 )); then
  # one layout: no switch shortcut needed (Toshy crashes on XF86Keyboard, RedBearAK/toshy)
  gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[]"
  gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]"
  spot='<Super>space'
else
  warn "You use $nsrc keyboard layouts, so Super+Space stays the layout switch. Spotlight: Super+Alt+Space"
  spot='<Super><Alt>space'
fi
python3 -I - "$spot" <<'EOF'
import ast, subprocess, sys
cur = subprocess.run(['gsettings', 'get', 'org.gnome.shell.keybindings', 'toggle-overview'], capture_output=True, text=True).stdout.strip()
items = [] if cur.startswith('@as') else ast.literal_eval(cur)
if sys.argv[1] not in items: items.append(sys.argv[1])
subprocess.run(['gsettings', 'set', 'org.gnome.shell.keybindings', 'toggle-overview', str(items)], check=True)
EOF

# Inter: the closest free match for Apple's San Francisco
font=Inter
gsettings set org.gnome.desktop.interface font-name "$font 11"
gsettings set org.gnome.desktop.interface document-font-name "$font 11"
gsettings set org.gnome.desktop.wm.preferences titlebar-font "$font Bold 11"

# ⌘⇧3 whole screen, ⌘⇧4 / ⌘⇧5 screenshot tool (area select, window, screen recording)
python3 -I - <<'EOF'
import ast, subprocess
def add(key, *combos):
    cur = subprocess.run(['gsettings', 'get', 'org.gnome.shell.keybindings', key], capture_output=True, text=True).stdout.strip()
    items = [] if cur.startswith('@as') else ast.literal_eval(cur)
    items += [c for c in combos if c not in items]
    subprocess.run(['gsettings', 'set', 'org.gnome.shell.keybindings', key, str(items)], check=True)
add('screenshot', '<Shift><Super>3')
add('show-screenshot-ui', '<Shift><Super>4', '<Shift><Super>5')
EOF

# Trackpad like a Mac: natural scrolling, tap to click, two-finger click = right click
T=org.gnome.desktop.peripherals.touchpad
gsettings set $T natural-scroll true
gsettings set $T tap-to-click true
gsettings set $T click-method 'fingers'

"$HOME/.local/bin/macos-theme-switch" >/dev/null 2>&1 || true   # sets the Apple icon colour

step "5/5 Checking"
all=1
for e in "${EXTRA_EXTENSIONS[@]}"; do
  s=$(ext_state "$e"); [[ $s == ACTIVE ]] || all=0
  printf "  %-45s %s\n" "$e" "${s:-installed, needs log out}"
done
if [[ -n ${UML_CHAINED:-} ]]; then (( all )) && exit 0 || exit 3; fi   # install.sh prints the summary
if (( all )); then
  echo; echo "${G}${B}ALL DONE ✅${N}"
else
  echo; echo "${Y}${B}STEP 1 OF 2 DONE — log out, log back in, and run extras.sh again.${N}"
fi
cat <<EOF

${B}Try it:${N}
  • Super+Space → search (type and press Enter, like Spotlight)
  • In Files, select a file and press Space → Quick Look preview
  • Apple logo (top-left) → About, Settings, Sleep, Restart, Force Quit
  • Super+Shift+3 / 4 / 5 → screenshots
${B}By hand (browsers):${N}
  • Chrome: Settings → Appearance → Mode: GTK
EOF
