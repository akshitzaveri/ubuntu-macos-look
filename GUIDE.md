# Guide: your Mac habits on Ubuntu

What the scripts set up, how to use each macOS feature on Ubuntu, and what doesn't exist yet (with the closest alternative).

## What each script does

| Script | What it sets up | Needs |
|---|---|---|
| `install.sh` | MacTahoe themes, icons, cursor and wallpapers. Dock at the bottom, window buttons on the left, readable Quick Settings, automatic light/dark switching, Toggle Appearance, Déjà Dup and Timeshift backups, iPhone photo (HEIC) support | Password once; log out and back in; run it again |
| `extras.sh` | Spotlight, Quick Look, Apple menu, menu-bar clock on the right, notifications top-right, Inter font, rounded window corners, ⌘⇧3/4/5 screenshots, two-finger right click | Password once; log out and back in; run it again |
| `toshy.sh` | Mac keyboard shortcuts (⌘C/V/Q/Tab/Space, ⌘Backspace) through [Toshy](https://github.com/RedBearAK/toshy) | Password; log out and back in; run it again |
| `login-screen.sh` | macOS-style login screen (blurred wallpaper, no Ubuntu logo) for every user on the computer | Password; log out to see it |
| `verify.sh` | Checks everything is installed and working | Nothing |
| `uninstall.sh` | Removes everything and restores the settings you had before | Password if the login screen was changed |

Everything except `login-screen.sh` only affects your own user account. Each script backs up your settings before changing anything.

## macOS features you have

### Look

| On a Mac | On Ubuntu | How to use it |
|---|---|---|
| macOS look | MacTahoe theme, icons and cursor | Already applied |
| Dock | Dash to Dock, always visible at the bottom | Click to open, right-click for options. The grid icon on the left is Launchpad. |
| Traffic-light window buttons on the left | Same | Close, minimize and zoom on the left of GNOME apps |
| Light / Dark / Auto appearance | Automatic light 07:00–18:00, dark otherwise | Switch by hand with **Super+Shift+A**, Quick Settings → **Dark Style**, or Super → type "appearance". Everything switches together: themes, icons, wallpaper, Apple menu icon. |
| Menu bar | Top bar: Apple menu on the left; status icons, then clock on the right | Click the Apple logo for About, Settings, Sleep, Restart, Force Quit |
| Control Center | Quick Settings (top-right) | Wi-Fi, Bluetooth, volume, brightness, Do Not Disturb, Night Light (= Night Shift) |
| Notification Center | Click the clock | Notifications and calendar; banners appear top-right |
| Login screen | `login-screen.sh` (optional) | Add a profile picture in Settings → System → Users |

### Finding things

| On a Mac | On Ubuntu | How to use it |
|---|---|---|
| Spotlight (⌘Space) | GNOME search | **Super+Space** (or ⌘Space with Toshy), type, press Enter. It finds apps, files, settings, and does calculations. It opens full-screen rather than as a small box. |
| Launchpad | App grid | Grid icon on the dock, or press Super twice |
| Mission Control | Activities overview | Press **Super**, or swipe up with three fingers |
| Spaces | Workspaces | Three-finger swipe left/right, or Super+Page Up/Down |
| Finder | Files | Sidebar, tabs (Ctrl+T), and search work like Finder |
| Quick Look | Sushi | In Files, select a file and press **Space**. Press Space again to close. |

### Doing things

| On a Mac | On Ubuntu | How to use it |
|---|---|---|
| ⌘⇧3 screenshot | Super+Shift+3 | Whole screen, saved to Pictures/Screenshots |
| ⌘⇧4 / ⌘⇧5 | Super+Shift+4 or 5 | Screenshot tool: area, window, or screen recording |
| Time Machine | Backups (Déjà Dup) | Open **Backups** once and choose a drive or Google Drive. After that, right-click any file or folder → *Revert to Previous Version*. |
| Restore after a bad update | Timeshift | Open Timeshift, choose a snapshot → Restore |
| Software Update | Software Updater + automatic updates | Security updates install by themselves; you get a notice when a restart is needed |
| App Store | App Center | Install and update apps |
| Preview for iPhone photos | Image Viewer opens HEIC | Double-click. To convert: `heif-dec photo.HEIC -o photo.jpg` |
| Trackpad | Natural scrolling, tap to click, two-finger click = right click | Settings → Mouse & Touchpad to adjust speed |
| Activity Monitor | System Monitor | Apple menu → System Monitor |
| Force Quit (⌥⌘Esc) | Apple menu → Force Quit | Or System Monitor → right-click the app → Kill |

## Mac keyboard (`toshy.sh`, optional)

[Toshy](https://github.com/RedBearAK/toshy) remaps keys per app so your Mac shortcuts work. On a PC keyboard:

| Mac key | Press |
|---|---|
| ⌘ Command | **Alt** (next to the space bar, same spot as on a Mac) |
| ⌥ Option | **Windows / Super** |
| ⌃ Control | **Ctrl** |

- ⌘C/V/X/Z, ⌘Q, ⌘W, ⌘T, ⌘Tab and ⌘Space work as on macOS. ⌘⇧3/4/5 take screenshots.
- ⌘Backspace clears to the start of the line. `toshy.sh` adds this; Toshy's default doesn't work in Chrome or GTK apps.
- In terminals, ⌘C/⌘V copy and paste, and Ctrl+C still stops a command.
- **Multi-OS keyboards** (Logitech, Keychron, Rapoo): use **Windows/PC mode**, not Mac mode. Follow the Mac labels: the key marked **cmd** (next to the space bar) is ⌘, and the one marked **alt/option** is ⌥.
- ⌥⌫ (Option+Backspace) deletes a word, and ⌘⌫ deletes the line. `toshy.sh` also stops Option and Cmd from opening app menus (a stray Alt tap Toshy sends by default).
- The Super key alone no longer opens the overview. Use ⌘Space or a three-finger swipe up.
- **A key stuck?** Press **F16**, or run `toshy-services-stop` (from **Ctrl+Alt+F3** if needed). `toshy-services-restart` turns it back on.
- Change mappings from Toshy's tray icon or `toshy-gui`. Undo it all with `bash toshy.sh --undo`.

## Not available, and the closest alternative

| On a Mac | Status on Ubuntu | Closest alternative |
|---|---|---|
| Global menu bar (File, Edit, View at the top of the screen) | Not possible on GNOME/Wayland; apps keep menus in their own windows | None reliable |
| Dock magnification | Not available for GNOME 50 | None |
| Small Spotlight-style search box | The Search Light extension crashes GNOME 50 | GNOME's full-screen search on Super+Space |
| San Francisco font | Apple's license doesn't allow it on non-Apple systems | **Inter**, already set by `extras.sh` |
| Apple apps (Safari, Mail, Notes, iMessage, FaceTime) | Not available | Chrome or Firefox; Thunderbird or Geary; web versions of iCloud Notes, Mail and Calendar at icloud.com |
| AirDrop, Handoff, Continuity | Not available | **GSConnect** extension + KDE Connect app on your phone (Android). For iPhone, use **LocalSend** on both. |
| iCloud Drive sync | No official client | iCloud web at icloud.com, or use Google Drive (Settings → Online Accounts) |
| Siri | Not available | None built in |
| Touch ID | Fingerprint login works only on supported readers | Settings → System → Users → Fingerprint Login |
| Mac-style buttons in every app | Some apps (Electron or custom-drawn) use their own Windows-style buttons | No fix from the system side; ask the app's developer |
| Apple startup chime and sounds | Apple's sounds can't be redistributed | Settings → Sound → Alert Sound |

## If something looks wrong

1. Run `verify.sh`. It lists anything that isn't working.
2. After a major Ubuntu upgrade, run `install.sh` (and `extras.sh`) again.
3. To go back to stock Ubuntu, run `uninstall.sh`.
4. Still stuck? Open an issue with a screenshot of `verify.sh`.
