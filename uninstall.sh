#!/usr/bin/env bash
# Undo ubuntu-macos-look and restore the settings saved at first install.
# Leaves apt packages (Déjà Dup, Timeshift, …) installed.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
source "$here/lib/common.sh"
ensure_terminal "$@"
trap pause_on_exit EXIT

[[ -f $STATE_DIR/original-settings.done ]] || die "No install backup found in $STATE_DIR — nothing to restore."
read -rp "Remove the macOS look and restore your previous settings? [y/N] " ans </dev/tty
[[ $ans =~ ^[Yy]$ ]] || exit 0

step "Stopping light/dark automation"
systemctl --user disable --now macos-theme-switch.timer macos-theme-watch.service 2>/dev/null
rm -f ~/.config/systemd/user/macos-theme-{switch.service,switch.timer,watch.service}
rm -f ~/.local/bin/macos-theme-{switch,watch,toggle} ~/.local/share/applications/macos-theme-toggle.desktop
systemctl --user daemon-reload

step "Restoring settings"
for p in "${TOUCHED_PATHS[@]}"; do
  f=$STATE_DIR/orig$(tr / _ <<<"$p").dconf
  dconf reset -f "$p"; [[ -s $f ]] && dconf load "$p" < "$f"
done
for k in enabled-extensions disabled-extensions; do gsettings set org.gnome.shell $k "$(cat "$STATE_DIR/orig-$k")"; done
MK=org.gnome.settings-daemon.plugins.media-keys
gsettings set $MK custom-keybindings "$(cat "$STATE_DIR/orig-custom-keybindings")"
dconf reset -f "$KEYBINDING"

step "Removing themes, icons, cursor, wallpapers"
rm -rf ~/.themes/MacTahoe-* ~/.local/share/icons/{MacTahoe,MacTahoe-dark,MacTahoe-light,WhiteSur-cursors} \
       ~/.local/share/backgrounds/MacTahoe
rm -rf ~/.config/gtk-4.0
[[ -d $STATE_DIR/gtk-4.0.orig ]] && cp -a "$STATE_DIR/gtk-4.0.orig" ~/.config/gtk-4.0

step "Removing extensions this project installed"
for e in "${EXTENSIONS[@]}"; do
  grep -qx "$e" "$STATE_DIR/preexisting-extensions" 2>/dev/null && { echo "  keeping $e (you had it before)"; continue; }
  gnome-extensions uninstall "$e" 2>/dev/null || rm -rf ~/.local/share/gnome-shell/extensions/"$e"
  echo "  removed $e"
done

if [[ -f $STATE_DIR/extras-settings.done ]]; then
  step "Removing extras (Spotlight, Apple menu, menu bar, rounded corners)"
  for f in "$STATE_DIR"/extras_*.dconf; do
    p=$(basename "$f" .dconf); p=${p#extras}; p=${p//_//}
    dconf reset -f "$p"; [[ -s $f ]] && dconf load "$p" < "$f"
  done
  for e in just-perfection-desktop@just-perfection logomenu@aryan_k rounded-window-corners@fxgn; do
    gnome-extensions uninstall "$e" 2>/dev/null || rm -rf ~/.local/share/gnome-shell/extensions/"$e"
  done
  gsettings reset org.gnome.desktop.interface font-name
  gsettings reset org.gnome.desktop.interface document-font-name
  gsettings reset org.gnome.desktop.wm.preferences titlebar-font
fi

if [[ $(readlink -f /usr/share/gnome-shell/gdm-theme.gresource) == /usr/local/share/ubuntu-macos-look/* ]]; then
  UML_IN_TERM= bash "$here/login-screen.sh" --undo
fi

rm -rf "$STATE_DIR" "$CACHE_DIR"
echo; echo "${G}Done.${N} Log out and back in to finish."
