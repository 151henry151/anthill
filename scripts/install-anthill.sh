#!/usr/bin/env bash
# Install Anthill Godot project and a /usr/local/bin/anthill launcher (requires Godot 4 on PATH).
set -euo pipefail

PREFIX="${PREFIX:-/usr/local}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/game/anthill"
DEST="$PREFIX/share/anthill/game/anthill"
BIN="$PREFIX/bin/anthill"
TEMPLATE="$REPO_ROOT/scripts/anthill-launcher.sh.in"

if [[ ! -f "$SRC/project.godot" ]]; then
	echo "install-anthill.sh: expected $SRC/project.godot (run from repo clone)." >&2
	exit 1
fi
if [[ ! -f "$TEMPLATE" ]]; then
	echo "install-anthill.sh: missing $TEMPLATE" >&2
	exit 1
fi

if [[ "$(id -u)" -ne 0 ]] && { [[ ! -w "$PREFIX/bin" ]] || [[ ! -w "$PREFIX/share" ]]; }; then
	echo "install-anthill.sh: need write access to $PREFIX; re-run with: sudo $0" >&2
	exit 1
fi

install -d "$DEST"
cp -a "$SRC/." "$DEST/"

sed "s|@@DATADIR@@|$DEST|g" "$TEMPLATE" >"$BIN"
chmod 755 "$BIN"

echo "Installed:"
echo "  $BIN"
echo "  $DEST"
echo "Run: anthill   (requires godot4 or godot on PATH)"
