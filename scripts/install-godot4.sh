#!/usr/bin/env bash
# Install official Godot 4.x editor binary for Linux x86_64 (no apt package on many distros).
set -euo pipefail

PREFIX="${PREFIX:-/usr/local}"
VERSION="${GODOT_VERSION:-4.2.2}"
# Official stable tag: 4.2.2-stable
TAG="${VERSION}-stable"
ZIP_URL="https://github.com/godotengine/godot/releases/download/${TAG}/Godot_v${TAG}_linux.x86_64.zip"
BIN_NAME="Godot_v${TAG}_linux.x86_64"
DEST_DIR="$PREFIX/lib/anthill"
DEST_BIN="$DEST_DIR/godot4"
LINK="$PREFIX/bin/godot4"

if [[ "$(id -u)" -ne 0 ]]; then
	echo "install-godot4.sh: run with sudo (installs under $PREFIX)." >&2
	exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
echo "Downloading $ZIP_URL ..."
curl -fsSL -o godot.zip "$ZIP_URL"
unzip -q godot.zip
if [[ ! -f "$BIN_NAME" ]]; then
	echo "install-godot4.sh: expected $BIN_NAME in zip; check GODOT_VERSION." >&2
	ls -la >&2
	exit 1
fi

install -d "$DEST_DIR"
install -m 755 "$BIN_NAME" "$DEST_BIN"
ln -sfn "$DEST_BIN" "$LINK"
echo "Installed $LINK -> $DEST_BIN"
"$LINK" --version
