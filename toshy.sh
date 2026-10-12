#!/usr/bin/env bash
# Optional: Mac keyboard shortcuts (⌘C, ⌘V, ⌘Q, ⌘Tab, ⌘Space…) via Toshy (github.com/RedBearAK/toshy).
#   bash toshy.sh          install (two runs, log out in between — like install.sh)
#   bash toshy.sh --keyboards   choose again how each keyboard maps (e.g. after plugging in a new one)
#   bash toshy.sh --undo   uninstall Toshy
# Default on a PC keyboard: by Mac position, Alt (next to the space bar) = ⌘, Windows key = ⌥.
# Per keyboard you can instead follow the printed labels: Windows key = ⌘, Alt = ⌥.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
source "$here/lib/common.sh"
ensure_terminal "$@"
trap pause_on_exit EXIT
require_gnome

TOSHY_DIR=$CACHE_DIR/toshy-src
TOSHY_CFG=$HOME/.config/toshy/toshy_config.py
HELPER=focused-window-dbus@flexagoon.com     # tells Toshy which app is in front on GNOME/Wayland

fetch_toshy() {
  local tag
  tag=$(curl -fsSL https://api.github.com/repos/RedBearAK/toshy/releases/latest \
        | python3 -c 'import sys,json; print(json.load(sys.stdin)["tag_name"])')
  rm -rf "$TOSHY_DIR"; mkdir -p "$TOSHY_DIR"
  curl -fsSL "https://github.com/RedBearAK/toshy/archive/refs/tags/$tag.tar.gz" | tar -xz -C "$TOSHY_DIR" --strip-components=1
  echo "Toshy $tag"
}

LABELS_FILE=$STATE_DIR/toshy-label-keyboards   # keyboards whose printed labels we follow (one name per line)

list_keyboards() {   # physical keyboards with letter keys, one name per line
  python3 -I - <<'EOF'
import re
for block in open('/proc/bus/input/devices').read().split('\n\n'):
    name = re.search(r'^N: Name="(.*)"$', block, re.M)
    keys = re.search(r'^B: KEY=(.*)$', block, re.M)
    if not name or not keys or 'kbd' not in block or 'S: Sysfs=/devices/virtual/' in block:
        continue   # virtual devices (Toshy's own output, dictation helpers…) aren't physical keyboards
    n = name.group(1)
    if re.search(r'(?i)virtual|xwaykeyz|keyszer|mouse|button|video|hotkey|wmi|consumer|system control|hid events', n):
        continue
    bits = int(''.join(w.rjust(16, '0') for w in keys.group(1).split()), 16)
    if bits >> 30 & 1 and bits >> 57 & 1:   # KEY_A and KEY_SPACE
        print(n)
EOF
}

choose_keyboards() {
  mkdir -p "$STATE_DIR"; : > "$LABELS_FILE"
  local kb ans
  echo
  echo "${B}How should each keyboard map?${N} Look at the key right next to the space bar."
  while IFS= read -r kb; do
    echo "  ${B}$kb${N}"
    echo "    1) It says Alt (PC labels): Windows key = ⌘, Alt = ⌥  — keys do what they say"
    echo "    2) It says cmd/⌘, or use Mac key positions: key next to the space bar = ⌘   (default)"
    read -rp "    Choose [1/2]: " ans </dev/tty
    [[ $ans == 1 ]] && echo "$kb" >> "$LABELS_FILE"
  done < <(list_keyboards | sort -u)
}

if [[ ${1:-} == --undo ]]; then
  step "Uninstalling Toshy"
  [[ -x $TOSHY_DIR/setup_toshy.py ]] || fetch_toshy
  (cd "$TOSHY_DIR" && ./setup_toshy.py uninstall </dev/tty)
  gsettings reset org.gnome.mutter overlay-key
  echo "${G}Done.${N} Log out and back in to finish."
  exit 0
fi

# Toshy crashes on startup if a GNOME shortcut uses the XF86Keyboard key (older extras.sh set one)
if gsettings get org.gnome.desktop.wm.keybindings switch-input-source | grep -q XF86Keyboard; then
  gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[]"
  gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]"
fi

# macOS-style ⌘Backspace (delete to start of line). Toshy's default sends Ctrl+Shift+Backspace,
# which Chrome, GTK and Electron ignore. Goes in Toshy's user_apps slice so it survives upgrades.
apply_tweaks() {
  [[ -f $TOSHY_CFG ]] || return 0
  python3 -I - "$TOSHY_CFG" <<'EOF'
import sys
p = sys.argv[1]; s = orig = open(p).read()

# 1. macOS-style ⌘Backspace (delete to start of line). Toshy's default sends Ctrl+Shift+Backspace,
#    which Chrome, GTK and Electron ignore. Goes in the user_apps slice so it survives upgrades.
mark = '###  SLICE_MARK_END: user_apps  ###'
if 'ubuntu-macos-look: Cmd+Backspace' not in s and mark in s:
    s = s.replace(mark, '''# ubuntu-macos-look: Cmd+Backspace deletes to start of line in every text field, like macOS.
# Terminals, file managers (Cmd+Backspace = Move to Trash) and VS Code keep their own mapping.
_uml_not_terminal = matchProps(not_lst=terminals_and_remotes_lod)
_uml_not_vscode   = matchProps(not_lst=vscodes_lod)
keymap("User: Cmd+Backspace deletes line left of cursor", {
    C("RC-Backspace"):         [C("Shift-Home"), C("Backspace")],
}, when = lambda ctx:
    cnfg.screen_has_focus and
    not ctx_app_is_remote and
    _uml_not_terminal(ctx) and
    _uml_not_vscode(ctx) and
    not hmp_is_filemanager(ctx)
)

''' + mark, 1)
    print("Added macOS-style Cmd+Backspace.")

# 2. Hold modifiers until the next key (Toshy defaults to 0 s). Otherwise Option/Cmd combos leak a
#    bare Alt tap, and Chrome/Electron apps open their menu (e.g. Option+Backspace opens File).
old = 'suspend             = 0,        # default: 0 sec'
if old in s:
    s = s.replace(old, 'suspend             = 2,        # ubuntu-macos-look: no bare Alt taps from Option/Cmd combos', 1)
    print("Option/Cmd no longer open app menus.")

if s != orig:
    open(p + '.before-ubuntu-macos-look', 'w').write(orig)
    open(p, 'w').write(s)
EOF
}

# Keyboards chosen to follow their printed labels → Toshy "Apple" type (Windows key = ⌘, Alt = ⌥).
# Written into Toshy's kbtype_override slice, which survives upgrades.
apply_keyboards() {
  [[ -f $TOSHY_CFG ]] || return 0
  python3 -I - "$TOSHY_CFG" "$LABELS_FILE" <<'EOF'
import os, re, sys
p, labels = sys.argv[1], sys.argv[2]
names = [l.strip() for l in open(labels)] if os.path.exists(labels) else []
s = open(p).read()
tag = '  # ubuntu-macos-look: follow printed labels'
s = '\n'.join(l for l in s.split('\n') if not l.endswith(tag))
start = s.find('keyboards_UserCustom_dct = {')
end = s.find('\n}', start)
if start < 0 or end < 0:
    sys.exit("kbtype_override slice not found; skipping keyboard labels")
add = ''.join(f"\n    {n!r}: 'Apple',{tag}" for n in names if n)
s = s[:end] + add + s[end:]
open(p, 'w').write(s)
for n in names: print(f"  {n}: follows its printed labels")
EOF
}

if [[ ${1:-} == --keyboards ]]; then
  [[ -f $TOSHY_CFG ]] || die "Install Toshy first: bash toshy.sh"
  choose_keyboards; apply_keyboards
  systemctl --user restart toshy-config.service
  echo "${G}Done.${N} Takes effect now."; exit 0
fi

tests() {
  cat <<EOF

${B}Try it${N} (on a PC keyboard ⌘ is the Alt key next to the space bar):
  • ⌘C / ⌘V copy and paste    • ⌘Q quit    • ⌘Tab switch apps    • ⌘Space search
  • ⌘Backspace clears the line    • In the terminal ⌘C/⌘V copy/paste, Ctrl+C still stops a command
${B}Multi-OS keyboard${N} (Logitech, Keychron…)? Put it in Windows/PC mode, not Mac mode.
${B}A key stuck?${N} Press F16, or run toshy-services-stop (from Ctrl+Alt+F3 if needed).
EOF
}

# Second run, after logging back in
if [[ -f $TOSHY_CFG ]] && id -nG | grep -qw input; then
  step "Finishing Toshy setup"
  apply_tweaks
  systemctl --user restart toshy-config.service 2>/dev/null || true
  sleep 5
  if systemctl --user is-active -q toshy-config.service && [[ $(ext_state "$HELPER") == ACTIVE ]]; then
    [[ -n ${UML_CHAINED:-} ]] && exit 0
    banner_ok="ALL DONE ✅  Mac keyboard shortcuts are on."
    echo; echo "${G}${B}$banner_ok${N}"; tests
  else
    [[ -n ${UML_CHAINED:-} ]] && { echo "  Toshy isn't running yet."; exit 3; }
    echo "${Y}${B}Toshy isn't running yet.${N} Log out and back in, then run toshy.sh again."
    echo "Log: journalctl --user -u toshy-config.service -n 30"
  fi
  exit 0
fi

cat <<EOF
${B}Mac keyboard shortcuts (Toshy)${N}
Toshy runs in the background and remaps keys per app so ⌘ shortcuts work like on a Mac.
It adds you to the 'input' group, enables the uinput module, installs a few packages, and turns
off "Super key opens the overview" (⌘Space does that instead). Undo any time: bash toshy.sh --undo
EOF
if [[ -z ${UML_CHAINED:-} ]]; then
  read -rp "Continue? [Y/n] " ans </dev/tty
  [[ ${ans:-Y} =~ ^[Yy]$ ]] || exit 0
fi

choose_keyboards

step "1/3 GNOME helper extension"
url=$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=$HELPER&shell_version=$SHELL_MAJOR" \
      | python3 -c 'import sys,json; print(json.load(sys.stdin)["download_url"])') \
  || die "$HELPER has no release for GNOME $SHELL_MAJOR yet"
mkdir -p "$CACHE_DIR"; curl -fsSL "https://extensions.gnome.org$url" -o "$CACHE_DIR/$HELPER.zip"
gnome-extensions install --force "$CACHE_DIR/$HELPER.zip"
list_edit enabled-extensions add "$HELPER"; list_edit disabled-extensions remove "$HELPER"

step "2/3 Toshy's own installer (answer its questions; it asks for your password)"
fetch_toshy
(cd "$TOSHY_DIR" && ./setup_toshy.py install </dev/tty)

step "3/3 macOS-style ⌘Backspace, menu fix, keyboard labels"
apply_tweaks
apply_keyboards
[[ -n ${UML_CHAINED:-} ]] && exit 3   # needs a log out; install.sh shows the banner

cat <<EOF

${Y}${B}STEP 1 OF 2 DONE — now log out and log back in${N}
  Toshy needs the new 'input' group, which only applies after logging in again.
  Then run toshy.sh again — it checks everything and says ALL DONE.
EOF
