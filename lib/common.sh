# Shared helpers for install.sh / verify.sh / uninstall.sh. Sourced, not executed.

# Pinned upstream versions — bump deliberately after testing.
MACTAHOE_GTK_COMMIT=1e45e19f510edb8cde18fa84d6cd5319f60b086b
MACTAHOE_ICON_COMMIT=839848b9a8a38a92a6936e30c4abe35cc6f2546d
WHITESUR_CURSORS_COMMIT=e190baf618ed95ee217d2fd45589bd309b37672b
EXTENSIONS=(dash-to-dock@micxgx.gmail.com blur-my-shell@aunetx)
USER_THEME=user-theme@gnome-shell-extensions.gcampax.github.com

STATE_DIR=$HOME/.local/share/ubuntu-macos-look     # backups + install manifest
CACHE_DIR=$HOME/.cache/ubuntu-macos-look            # upstream sources
KEYBINDING=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ubuntu-macos-look-toggle/
# dconf paths this project changes; backed up before install, restored on uninstall
TOUCHED_PATHS=(
  /org/gnome/desktop/interface/ /org/gnome/desktop/wm/preferences/ /org/gnome/desktop/background/
  /org/gnome/shell/extensions/dash-to-dock/ /org/gnome/shell/extensions/blur-my-shell/
  /org/gnome/shell/extensions/user-theme/
)

G=$'\e[32m'; R=$'\e[31m'; Y=$'\e[33m'; B=$'\e[1m'; N=$'\e[0m'
step() { echo; echo "${B}==> $*${N}"; }
warn() { echo "${Y}!${N} $*"; }
die()  { echo "${R}✘ $*${N}"; exit 1; }

# Opened by double-click (no terminal)? Re-open inside a terminal window so the user sees progress.
ensure_terminal() {
  [[ -t 1 || -n ${UML_IN_TERM:-} ]] && return
  export UML_IN_TERM=1
  local t
  for t in ptyxis gnome-terminal kgx x-terminal-emulator; do
    command -v "$t" >/dev/null || continue
    case $t in
      ptyxis)         exec ptyxis --new-window -- bash "$0" "$@" ;;
      gnome-terminal) exec gnome-terminal -- bash "$0" "$@" ;;
      *)              exec "$t" -e bash "$0" "$@" ;;
    esac
  done
}

pause_on_exit() { [[ -n ${UML_IN_TERM:-} ]] && { echo; read -rp "Press Enter to close this window." _ </dev/tty; }; }

require_gnome() {
  [[ $EUID -ne 0 ]] || die "Run as your normal user, not with sudo. It will ask for your password when needed."
  [[ ${XDG_CURRENT_DESKTOP:-} == *GNOME* ]] || die "This needs a GNOME desktop session (Ubuntu's default desktop)."
  command -v gnome-shell >/dev/null || die "gnome-shell not found."
  SHELL_MAJOR=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)
  (( SHELL_MAJOR >= 46 )) || die "GNOME $SHELL_MAJOR is too old; needs GNOME 46+ (Ubuntu 24.04 or newer)."
}

ext_state() { gnome-extensions info "$1" 2>/dev/null | awk -F': ' '/State/{print $2}'; }

# Add/remove a uuid in the org.gnome.shell string-list keys
list_edit() {  # list_edit <key> add|remove <uuid>
  python3 -I - "$@" <<'EOF'
import ast, subprocess, sys
key, op, uuid = sys.argv[1:]
cur = subprocess.run(['gsettings', 'get', 'org.gnome.shell', key], capture_output=True, text=True).stdout.strip()
items = [] if cur.startswith('@as') else ast.literal_eval(cur)
if op == 'add' and uuid not in items: items.append(uuid)
if op == 'remove': items = [i for i in items if i != uuid]
subprocess.run(['gsettings', 'set', 'org.gnome.shell', key, str(items)], check=True)
EOF
}
