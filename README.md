# ubuntu-macos-look

Make Ubuntu look and feel like macOS in one step. No YouTube tutorial, no 30 terminal commands.

<!-- Add screenshots: docs/light.png and docs/dark.png -->

## What you get

- **MacTahoe** app and top-bar themes, **MacTahoe** icons, **WhiteSur** cursor, and the day/night wallpapers
- **Dock** at the bottom: always visible, macOS-style dots under running apps (Ubuntu's side dock is turned off)
- **Window buttons on the left**: close, minimize, maximize
- **Readable Quick Settings** in both light and dark. The stock glass theme turns washed-out and gray-cornered on Ubuntu, so this ships a fixed version.
- **Automatic appearance**: light at 07:00, dark at 18:00
- **One switch for everything**: the Quick Settings *Dark Style* toggle, *Toggle Appearance* in app search, and **Super+Shift+A** each flip the whole look (themes, icons and wallpaper), like Raycast's appearance toggle
- **Backups**: installs Déjà Dup (Time Machine-style file backups) and Timeshift (system snapshots)

## Requirements

- Ubuntu 24.04 or newer with the default GNOME desktop (GNOME 46+)
- Tested on Ubuntu 26.04 / GNOME 50

## Install

1. Click **Code → Download ZIP** on this page, then open the ZIP and extract it.
2. Open the extracted folder in **Files**, right-click **`install.sh`** → **Run as a Program**.
3. Type your password when asked. The installer needs it once to install packages.
4. **Log out and back in.**
5. Right-click **`verify.sh`** → **Run as a Program**. It should say *All checks passed*.

Or from a terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/akshitzaveri/ubuntu-macos-look/main/install.sh | bash
```

Everything installs for your user only. Running `install.sh` again is safe.

### After installing: set up backups

- **Backups** (Déjà Dup): choose an external drive or Google Drive, select your home folder, and turn on *Back Up Automatically*. You can then right-click any file or folder in Files → *Revert to Previous Version*.
- **Timeshift**: choose **RSYNC** and keep about 5 daily snapshots. If an update ever breaks Ubuntu, you can roll back.

## Everyday use

| Want to… | Do this |
|---|---|
| Switch light ⇄ dark | Super+Shift+A, or Quick Settings → Dark Style, or Super → "appearance" |
| Change the 07:00/18:00 times | Edit `~/.config/systemd/user/macos-theme-switch.timer` and the hour check in `~/.local/bin/macos-theme-switch` |
| Turn off the schedule | `systemctl --user disable --now macos-theme-switch.timer` |
| Check everything is working | Run `verify.sh` |

## Uninstall

Right-click **`uninstall.sh`** → **Run as a Program**. It removes the themes, icons, cursor, extensions it added, and scripts, then restores the settings saved when you first installed. Déjà Dup and Timeshift stay installed.

## What it changes

- **Files:** `~/.themes/MacTahoe-*`, `~/.local/share/icons/{MacTahoe*,WhiteSur-cursors}`, `~/.local/share/backgrounds/MacTahoe`, `~/.config/gtk-4.0`, `~/.local/bin/macos-theme-*`, `~/.config/systemd/user/macos-theme-*`
- **Extensions:** Dash to Dock and Blur my Shell (from extensions.gnome.org), plus User Themes (Ubuntu package). Ubuntu Dock and Desktop Icons are disabled, not removed.
- **apt packages:** git, curl, unzip, sassc, libglib2.0-dev-bin, libxml2-utils, python3, gnome-shell-extensions, deja-dup, timeshift
- **Backup:** your previous settings are saved in `~/.local/share/ubuntu-macos-look/`

## Known limitations

- Some Electron apps draw their own Windows-style title bar buttons and ignore the left-side layout. A theme can't change that.
- GNOME treats libadwaita (GTK4) theming as unsupported. A few GTK4 apps may look slightly off.
- After a major Ubuntu upgrade, run `install.sh` again.

## Credits

This project only installs and configures other people's work:

- [MacTahoe GTK theme](https://github.com/vinceliuice/MacTahoe-gtk-theme), [MacTahoe icon theme](https://github.com/vinceliuice/MacTahoe-icon-theme), [WhiteSur cursors](https://github.com/vinceliuice/WhiteSur-cursors) by **vinceliuice** (GPL-3.0)
- [Dash to Dock](https://extensions.gnome.org/extension/307/dash-to-dock/), [Blur my Shell](https://extensions.gnome.org/extension/3193/blur-my-shell/)

Upstream versions are pinned in `lib/common.sh` and downloaded from their original sources at install time. Nothing is bundled.

macOS is a trademark of Apple Inc. This project is not affiliated with or endorsed by Apple.

## License

[GPL-3.0](LICENSE), the same license as the themes it builds on.
