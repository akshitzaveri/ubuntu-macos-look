#!/usr/bin/env python3
"""Build MacTahoe-<Color>-blue-fixed: the glass shell theme with Quick Settings rules
taken from the solid variant, so the panel is opaque and readable without Blur my Shell.

usage: make-fixed-shell-theme.py <themes_dir> Light|Dark
"""
import re, shutil, sys
from pathlib import Path

themes, color = Path(sys.argv[1]), sys.argv[2]
glass, solid = themes / f"MacTahoe-{color}-blue", themes / f"MacTahoe-{color}-solid-blue"
out = themes / f"MacTahoe-{color}-blue-fixed"

shutil.rmtree(out, ignore_errors=True)
out.mkdir()
shutil.copytree(glass / "gnome-shell", out / "gnome-shell")
(out / "index.theme").write_text(
    (glass / "index.theme").read_text().replace(glass.name, out.name))

css = re.sub(r"/\*.*?\*/", "", (solid / "gnome-shell/gnome-shell.css").read_text(), flags=re.S)
rules = [f"{sel.strip()} {{{body}}}" for sel, body in re.findall(r"([^{}]+)\{([^{}]*)\}", css)
         if not sel.strip().startswith("@") and re.search(r"quick-(settings|toggle|slider|menu)", sel)]
if not rules:
    sys.exit(f"no Quick Settings rules found in {solid}")

panel, text, slider = (("rgba(245,245,245,0.97)", "#242424", "rgba(0,0,0,0.05)") if color == "Light"
                       else ("rgba(22,22,22,0.97)", "white", "rgba(255,255,255,0.06)"))
with open(out / "gnome-shell/gnome-shell.css", "a") as f:
    f.write("\n/* ubuntu-macos-look: opaque Quick Settings from the solid variant */\n")
    f.write("\n".join(rules) + "\n")
    f.write(f".quick-settings {{ background-color: {panel} !important; color: {text}; }}\n")
    f.write(f".quick-slider {{ background-color: {slider} !important; box-shadow: none !important; }}\n")
print(f"{out.name}: {len(rules)} rules")
