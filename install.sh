#!/usr/bin/env bash
# Copyright (C) 2026 Paul Philippov <paul@themactep.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINDIR="${HOME}/.local/bin"
MIME_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/mime/packages"
THUMB_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/thumbnailers"

usage() {
  cat <<EOF
Usage: $0 [install|uninstall|system]

  install     Install to ~/.local/share (user only, default)
  system      Install system-wide (requires sudo)
  uninstall   Remove user installation
EOF
  exit 1
}

system_install() {
  BINDIR="/usr/local/bin"
  MIME_DIR=/usr/share/mime/packages
  THUMB_DIR=/usr/share/thumbnailers
  echo "Installing system-wide..."
  [ "$(id -u)" -eq 0 ] || exec sudo "$0" system
}

install_files() {
  echo "  Install dir: $BINDIR"
  echo "  MIME dir:    $MIME_DIR"
  echo "  Thumb dir:   $THUMB_DIR"
  echo

  mkdir -p "$BINDIR" "$MIME_DIR" "$THUMB_DIR"

  echo "Installing scut-thumbnailer binary..."
  cp "$SCRIPT_DIR/bin/scut-thumbnailer" "$BINDIR/scut-thumbnailer"
  chmod +x "$BINDIR/scut-thumbnailer"

  echo "Installing MIME type definition..."
  cp "$SCRIPT_DIR/sure-cuts-alot.xml" "$MIME_DIR/"

  echo "Installing tumbler thumbnailer definition..."
  sed "s|@BINDIR@|$BINDIR|" "$SCRIPT_DIR/scut.thumbnailer" > "$THUMB_DIR/scut.thumbnailer"

  echo "Updating MIME database..."
  update-mime-database "${XDG_DATA_HOME:-$HOME/.local/share}/mime" 2>/dev/null || true

  echo
  echo "=== Installation complete ==="
  echo
  check_deps

  cat <<EOF
To see thumbnails in your file manager:
  1. Fully restart the file manager:  pkill -9 thunar   (or nautilus / dolphin)
  2. Clear thumbnail cache:           rm -rf ~/.cache/thumbnails/
  3. Open a folder with .scut files

Files installed:
  $BINDIR/scut-thumbnailer
  $MIME_DIR/sure-cuts-alot.xml
  $THUMB_DIR/scut.thumbnailer
EOF
}

uninstall_files() {
  echo "Removing user installation..."
  rm -f "$BINDIR/scut-thumbnailer"
  rm -f "$MIME_DIR/sure-cuts-alot.xml"
  rm -f "$THUMB_DIR/scut.thumbnailer"
  update-mime-database "${XDG_DATA_HOME:-$HOME/.local/share}/mime" 2>/dev/null || true
  echo "Uninstall complete."
}

check_deps() {
  local missing=()
  command -v ruby    >/dev/null 2>&1 || missing+=(ruby)
  command -v convert >/dev/null 2>&1 || missing+=(imagemagick)

  if [ ${#missing[@]} -gt 0 ]; then
    echo "WARNING: Missing dependencies: ${missing[*]}"
    echo "Thumbnailing may not work. Install them with your package manager."
  else
    echo "Dependencies: OK (ruby, imagemagick)"
  fi
}

case "${1:-install}" in
  install)  install_files ;;
  system)   system_install; install_files ;;
  uninstall) uninstall_files ;;
  *)        usage ;;
esac
