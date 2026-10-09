#!/usr/bin/env bash
# Optional: Mac keyboard shortcuts (⌘C, ⌘V, ⌘Q, ⌘Tab, ⌘Space…) via Toshy (github.com/RedBearAK/toshy).
#   bash toshy.sh          install (two runs, log out in between — like install.sh)
#   bash toshy.sh --undo   uninstall Toshy
# On a PC keyboard: Alt (next to the space bar) = ⌘, Windows key = ⌥, Ctrl = ⌃.
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
p = sys.argv[1]; s = open(p).read()
mark = '###  SLICE_MARK_END: user_apps  ###'
if 'ubuntu-macos-look: Cmd+Backspace' in s or mark not in s:
    sys.exit(0)
add = '''# ubuntu-macos-look: Cmd+Backspace deletes to start of line in every text field, like macOS.
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

'''
open(p + '.before-ubuntu-macos-look', 'w').write(s)
open(p, 'w').write(s.replace(mark, add + mark, 1))
print("Added macOS-style Cmd+Backspace.")
EOF
}

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

step "3/3 macOS-style ⌘Backspace"
apply_tweaks
[[ -n ${UML_CHAINED:-} ]] && exit 3   # needs a log out; install.sh shows the banner

cat <<EOF

${Y}${B}STEP 1 OF 2 DONE — now log out and log back in${N}
  Toshy needs the new 'input' group, which only applies after logging in again.
  Then run toshy.sh again — it checks everything and says ALL DONE.
EOF
