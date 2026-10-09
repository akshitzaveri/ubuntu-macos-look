#!/usr/bin/env bash
# Optional: make the Ubuntu login screen look like macOS (blurred MacTahoe wallpaper, no Ubuntu logo).
#   bash login-screen.sh          install   (right-click → Run as a Program works too)
#   bash login-screen.sh --undo   back to Ubuntu's login screen
#
# Nothing Ubuntu ships is edited: the theme is built in a temp folder, installed as a new file,
# and Ubuntu's own `gdm-theme.gresource` alternatives link is pointed at it. Ubuntu updates
# can't overwrite it, and --undo restores the original link.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
source "$here/lib/common.sh"
ensure_terminal "$@"
trap pause_on_exit EXIT

GDM_THEME=/usr/local/share/ubuntu-macos-look/gdm-theme.gresource
GDM_LINK=/usr/share/gnome-shell/gdm-theme.gresource
GDM_LOGO_OFF=/usr/share/gdm/dconf/95-ubuntu-macos-look   # read by Ubuntu's GDM on every start

undo() {
  step "Restoring Ubuntu's login screen"
  sudo update-alternatives --remove gdm-theme.gresource "$GDM_THEME" 2>/dev/null || true
  sudo update-alternatives --auto gdm-theme.gresource
  sudo rm -f "$GDM_THEME" "$GDM_LOGO_OFF"
  sudo /usr/share/gdm/generate-config 2>/dev/null || true
  echo "${G}Done.${N} Log out to see Ubuntu's login screen again."
}

[[ $EUID -ne 0 ]] || die "Run as your normal user; it asks for your password when needed."
if [[ ${1:-} == --undo ]]; then undo; exit 0; fi

update-alternatives --query gdm-theme.gresource >/dev/null 2>&1 \
  || die "This Ubuntu's login screen doesn't use the gdm-theme.gresource link; not supported."

cat <<EOF
${B}macOS-style login screen${N}
  • Blurred, darkened MacTahoe wallpaper and MacTahoe styling
  • Ubuntu logo removed from the bottom
This changes the login screen for every user on this computer. Undo any time:
  bash login-screen.sh --undo
If the login screen ever looks broken: press Ctrl+Alt+F3, log in as text, run the undo
command above, then: sudo systemctl restart gdm3
EOF
read -rp "Continue? [Y/n] " ans </dev/tty
[[ ${ans:-Y} =~ ^[Yy]$ ]] || exit 0

step "1/3 Packages (needs your password)"
sudo apt-get install -y git imagemagick sassc libglib2.0-dev-bin libxml2-utils </dev/tty

step "2/3 Building the login theme (in a temp folder, no system changes)"
src=$CACHE_DIR/MacTahoe-gtk-theme
if [[ ! -d $src/.git ]]; then
  rm -rf "$src"; git init -q "$src"
  git -C "$src" remote add origin https://github.com/vinceliuice/MacTahoe-gtk-theme.git
fi
git -C "$src" fetch -q --depth 1 origin "$MACTAHOE_GTK_COMMIT" && git -C "$src" checkout -q --force FETCH_HEAD

work=$(mktemp -d); trap 'rm -rf "$work"; pause_on_exit' EXIT
cp -r "$src" "$work/repo"; mkdir -p "$work/out"
# MacTahoe's GDM tweak overwrites Ubuntu's Yaru theme file in place. Point every system path
# it uses at the temp folder instead, and let it run without root.
cp /usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource "$work/out/target.gresource"
sed -i -E \
  -e "s#^(COMMON_CSS_FILE|UBUNTU_CSS_FILE|ZORIN_CSS_FILE|ETC_CSS_FILE|ETC_GR_FILE|POP_OS_GR_FILE|MISC_GR_FILE|ZORIN_GR_LIGHT_FILE|ZORIN_GR_DARK_FILE)=.*#\1=\"$work/none/\1\"#" \
  -e "s#^YARU_GR_FILE=.*#YARU_GR_FILE=\"$work/out/target.gresource\"#" \
  -e "s#^MACTAHOE_GS_DIR=.*#MACTAHOE_GS_DIR=\"$work/gsdir\"#" \
  "$work/repo/libs/lib-core.sh"
python3 -I - "$work/repo/libs/lib-core.sh" <<'EOF'
import sys; p = sys.argv[1]; s = open(p).read()
s = s.replace('full_sudo() {\n  if [[ ! -w "/root" ]]; then', 'full_sudo() {\n  if false; then')
open(p, 'w').write(s)
EOF
(cd "$work/repo" && TERM=${TERM:-xterm-256color} ./tweaks.sh -g </dev/null >"$work/build.log" 2>&1) \
  || { tail -20 "$work/build.log"; die "Building the login theme failed."; }
[[ -f $work/out/target.gresource.bak ]] && gresource list "$work/out/target.gresource" | grep -q gdm \
  || die "Build finished but produced no login theme."
echo "Built."

step "3/3 Installing (needs your password)"
sudo install -Dm644 "$work/out/target.gresource" "$GDM_THEME"
sudo update-alternatives --install "$GDM_LINK" gdm-theme.gresource "$GDM_THEME" 100
sudo update-alternatives --set gdm-theme.gresource "$GDM_THEME"
printf "[org/gnome/login-screen]\nlogo=''\n" | sudo tee "$GDM_LOGO_OFF" >/dev/null
sudo /usr/share/gdm/generate-config 2>/dev/null || true

echo
echo "${G}${B}Done.${N} Log out to see the new login screen."
echo "Tip: add a profile picture in Settings → System → Users — it shows on the login screen."
