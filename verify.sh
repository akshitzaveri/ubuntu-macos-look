#!/usr/bin/env bash
# Check that ubuntu-macos-look is fully installed. Double-click (Run as a Program) or: bash verify.sh
here=$(cd "$(dirname "$0")" && pwd)
source "$here/lib/common.sh"
if [[ ${1:-} != --inline ]]; then
  ensure_terminal "$@"
  # Files may already launch us in a terminal; hold that window open too.
  UML_IN_TERM=1
  trap pause_on_exit EXIT
fi

pass=0; fail=0; relog=0
ok()  { echo "  ${G}✔${N} $1"; pass=$((pass+1)); }
bad() { echo "  ${R}✘${N} $1"; fail=$((fail+1)); }
chk() { if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }
gs()  { gsettings get "$@" 2>/dev/null; }

C=Light; icons=MacTahoe
[[ $(gs org.gnome.desktop.interface color-scheme) == "'prefer-dark'" ]] && { C=Dark; icons=MacTahoe-dark; }

echo "${B}Files${N}"
for d in ~/.themes/MacTahoe-{Light,Dark}-blue{,-fixed} ~/.local/share/icons/{MacTahoe,MacTahoe-dark,WhiteSur-cursors}; do
  chk "$(basename "$d")" "[[ -d '$d' ]]"
done
chk "GTK4 (libadwaita) theme"  "[[ -f ~/.config/gtk-4.0/gtk-Light.css && -f ~/.config/gtk-4.0/gtk-Dark.css ]]"
chk "wallpapers"               "[[ -f ~/.local/share/backgrounds/MacTahoe/MacTahoe-day.jpeg ]]"
chk "light/dark scripts"       "[[ -x ~/.local/bin/macos-theme-switch && -x ~/.local/bin/macos-theme-watch && -x ~/.local/bin/macos-theme-toggle ]]"

echo "${B}Appearance${N} (currently ${C,,} mode)"
chk "app theme MacTahoe-$C-blue"           "[[ \$(gs org.gnome.desktop.interface gtk-theme) == \"'MacTahoe-$C-blue'\" ]]"
chk "top bar theme MacTahoe-$C-blue-fixed" "[[ \$(dconf read /org/gnome/shell/extensions/user-theme/name) == \"'MacTahoe-$C-blue-fixed'\" ]]"
chk "icons $icons"                         "[[ \$(gs org.gnome.desktop.interface icon-theme) == \"'$icons'\" ]]"
chk "WhiteSur cursor"                      "[[ \$(gs org.gnome.desktop.interface cursor-theme) == \"'WhiteSur-cursors'\" ]]"
chk "window buttons on the left"          "[[ \$(gs org.gnome.desktop.wm.preferences button-layout) == \"'close,minimize,maximize:'\" ]]"
chk "dock locked"                         "[[ \$(dconf read /org/gnome/shell/extensions/dash-to-dock/dock-fixed) == true ]]"
chk "popup blur off"                      "[[ \$(dconf read /org/gnome/shell/extensions/blur-my-shell/popup/blur) == false ]]"

echo "${B}Extensions${N}"
for e in "$USER_THEME" "${EXTENSIONS[@]}"; do
  s=$(ext_state "$e")
  if [[ $s == ACTIVE ]]; then ok "${e%%@*} active"; else bad "${e%%@*} not active (${s:-not loaded})"; relog=1; fi
done
if [[ $(ext_state ubuntu-dock@ubuntu.com) != ACTIVE ]]; then ok "Ubuntu Dock off"; else bad "Ubuntu Dock still on"; relog=1; fi

echo "${B}Automation${N}"
chk "07:00/18:00 schedule"          "systemctl --user is-enabled macos-theme-switch.timer"
chk "Dark Style watcher running"    "systemctl --user is-active macos-theme-watch.service"
chk "Super+Shift+A"                 "[[ \$(dconf read ${KEYBINDING}binding) == \"'<Super><Shift>a'\" ]]"
chk "Toggle Appearance in search"   "[[ -f ~/.local/share/applications/macos-theme-toggle.desktop ]]"

echo "${B}Backups${N}"
chk "Déjà Dup installed"  "command -v deja-dup"
chk "Timeshift installed" "command -v timeshift"

echo
if (( fail == 0 )); then echo "${G}${B}All $pass checks passed.${N}"
elif (( relog )); then echo "${Y}${B}$pass passed, $fail not yet.${N} Log out and back in, then run verify.sh again."
else echo "${R}${B}$pass passed, $fail failed.${N} Re-run install.sh, or open an issue with a screenshot of this window."; fi

cat <<EOF

${B}Check by eye:${N}
  1. Dock at the bottom, always visible, dots under running apps
  2. Close/minimize/maximize on the left of windows
  3. Super+Shift+A flips the whole look light ⇄ dark (wallpaper too)
  4. Super, type "appearance" → Toggle Appearance
  5. Quick Settings (top-right) in both modes: solid panel, readable, no gray corners
EOF
(( fail == 0 ))
