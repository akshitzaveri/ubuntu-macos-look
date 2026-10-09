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
- **iPhone photos (HEIC)**: open them in the image viewer, see thumbnails in Files, and convert them with `heif-dec photo.HEIC -o photo.jpg`
- **Backups**: installs Déjà Dup (Time Machine-style file backups) and Timeshift (system snapshots)

**New to Ubuntu from a Mac?** Read the [Guide](GUIDE.md): what each script sets up, how to use Spotlight, Quick Look, screenshots and backups here, and what isn't available (with alternatives).

## Requirements

- Ubuntu 24.04 or newer with the default GNOME desktop (GNOME 46+)
- Tested on Ubuntu 26.04 / GNOME 50

## Install

It takes two runs of the same installer, with a log out in between. The installer tells you what to do at each point.

**Option A: download and click**

1. Click **Code → Download ZIP** on this page, then open the ZIP and extract it.
2. Open the extracted folder in **Files**, right-click **`install.sh`** → **Run as a Program**, and type your password when asked. It also asks whether to add the **extras** (Spotlight, Quick Look, Apple menu…) and **Mac keyboard shortcuts** (Toshy). Both are recommended, and both install in the same run.
3. When it says **STEP 1 OF 2 DONE**, **log out and log back in**. A restart isn't needed.
4. Run **`install.sh`** again. It takes a few seconds the second time.
5. When it says **ALL DONE ✅**, right-click **`verify.sh`** → **Run as a Program** to confirm. It should say *All checks passed*.

**Option B: terminal**

```bash
curl -fsSL https://raw.githubusercontent.com/akshitzaveri/ubuntu-macos-look/main/install.sh | bash
```

When it says **STEP 1 OF 2 DONE**, log out, log back in, and run the same command again. When it says **ALL DONE ✅**, confirm with:

```bash
~/.cache/ubuntu-macos-look/repo/verify.sh
```

If it says **NOT QUITE YET**, log out and back in, then run the installer again. Everything installs for your user only, and running the installer again is always safe. To force a full reinstall, run `install.sh --reinstall`.

### After installing: set up backups

- **Backups** (Déjà Dup): choose an external drive or Google Drive, select your home folder, and turn on *Back Up Automatically*. You can then right-click any file or folder in Files → *Revert to Previous Version*.
- **Timeshift**: choose **RSYNC** and keep about 5 daily snapshots. If an update ever breaks Ubuntu, you can roll back.

## Optional: more macOS

`install.sh` offers both of these when you install. If you skipped them, run them on their own later; each takes two runs with a log out in between, just like `install.sh`.

- **`extras.sh`**: Spotlight on Super+Space, Quick Look (press Space in Files), Apple menu, clock on the right, notifications top-right, Inter font, rounded window corners, ⌘⇧3/4/5 screenshots, two-finger right click
- **`toshy.sh`**: Mac keyboard shortcuts through [Toshy](https://github.com/RedBearAK/toshy). The Alt key acts as ⌘, so ⌘C/V/Q/Tab/Space and ⌘Backspace work. Undo with `bash toshy.sh --undo`.

See the [Guide](GUIDE.md) for how to use everything.

## Optional: macOS-style login screen

Gives the login screen the blurred, darkened MacTahoe wallpaper and MacTahoe styling, and removes the Ubuntu logo. Run it after the main install:

Right-click **`login-screen.sh`** → **Run as a Program**, or:

```bash
bash ~/.cache/ubuntu-macos-look/repo/login-screen.sh
```

This affects every user on the computer, so it's a separate, optional step. It doesn't edit any file Ubuntu ships. It builds the theme in a temporary folder, installs it as a new file, and points Ubuntu's `gdm-theme.gresource` link at it, so Ubuntu updates can't overwrite it. To undo it, run `login-screen.sh --undo`; `uninstall.sh` also undoes it. If the login screen ever looks broken, press **Ctrl+Alt+F3**, log in at the text prompt, run the undo command, then run `sudo systemctl restart gdm3`.

Tip: add a profile picture in **Settings → System → Users**. It shows on the login screen, like on a Mac.

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
- **apt packages:** git, curl, unzip, sassc, libglib2.0-dev-bin, libxml2-utils, python3, gnome-shell-extensions, deja-dup, timeshift, libheif-plugin-libde265, heif-gdk-pixbuf, heif-thumbnailer, libheif-examples
- **Login screen (optional):** `/usr/local/share/ubuntu-macos-look/gdm-theme.gresource`, `/usr/share/gdm/dconf/95-ubuntu-macos-look`, and the `gdm-theme.gresource` alternatives link
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
