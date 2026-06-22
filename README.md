# scut-thumbnailer

A Linux file-manager thumbnailer for Sure Cuts A Lot project files
(`.scut`, `.scut2`, `.scut3`, `.scut4`, `.scut5`, `.scut6`).

Extracts the embedded PNG preview from SCUT files and registers the thumbnail
with your desktop environment so Nautilus, Thunar, Dolphin, and others can
display previews in their icon view.

## Requirements

- **ruby** (>= 3.0, uses stdlib only: rexml, base64, cgi, uri)
- **imagemagick** (provides the `convert` command for resizing)
- A freedesktop-compliant file manager (Thunar 4.18+, Nautilus/GNOME Files, Dolphin, PCManFM, etc.)
- **tumbler** (for XFCE/Thunar — typically installed by default)

## Quick Install

```sh
./install.sh
```

Installs to `~/.local/share/` (no sudo needed). Then restart your file manager:

```sh
pkill -9 thunar          # XFCE / Thunar
# or
nautilus -q              # GNOME / Nautilus
# or
pkill dolphin            # KDE / Dolphin
```

Clear the thumbnail cache if you want immediate results:

```sh
rm -rf ~/.cache/thumbnails/
```

## System-Wide Install

```sh
sudo ./install.sh system
```

## Uninstall

```sh
./install.sh uninstall
```

## How It Works

| File | Purpose |
|------|---------|
| `bin/scut-thumbnailer` | Ruby script that reads a `.scut` file, decodes the base64 PNG from the `<preview>` element, and writes a resized thumbnail |
| `sure-cuts-alot.xml` | freedesktop MIME type definition — registers `application/x-sure-cuts-alot` for `*.scut` through `*.scut6` |
| `scut.thumbnailer` | Tumbler/Nautilus thumbnailer entry — tells the desktop environment how to generate thumbnails for this MIME type |

**Execution flow:**

1. File manager navigates to a directory containing `.scut*` files
2. File manager queries tumbler (or the built-in thumbnailer) for supported MIME types
3. Tumbler reads `~/.local/share/thumbnailers/scut.thumbnailer`, registers the MIME type
4. For each `.scut*` file, tumbler calls `scut-thumbnailer <input> <output> <size>`
5. The script extracts the embedded PNG preview, resizes it, and writes it to the temp output
6. Tumbler saves the result to `~/.cache/thumbnails/`
7. The file manager displays the thumbnail

## Troubleshooting

**No thumbnails appear:**
- Kill the file manager daemon fully: `pkill -9 thunar`
- Clear the thumbnail cache: `rm -rf ~/.cache/thumbnails/`
- Verify MIME type: `xdg-mime query filetype <file.scut6>` should show `application/x-sure-cuts-alot`
- Test the script manually: `scut-thumbnailer file.scut6 output.png 256`
- Check tumblerd is running: `systemctl --user status tumblerd`

**Error "cannot load such file -- mini_magick":**
- Ignore — the script falls back to ImageMagick's `convert` command automatically

**"Image file contains no data" in tumbler logs:**
- Check `journalctl --user -u tumblerd` for the real error
- Ensure `ruby` and `convert` are on PATH for the tumblerd process

## License

GNU General Public License v2.0 or later. See [COPYING](COPYING).
