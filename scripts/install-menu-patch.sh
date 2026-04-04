#!/usr/bin/env sh
# Install Anthill's patched dlg_create_world.lua (see ../luanti_menu_patch/README.md).
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/luanti_menu_patch/dlg_create_world.lua"
DST="${LUANTI_BUILTIN:-/usr/share/luanti/builtin/mainmenu}/dlg_create_world.lua"

if [ ! -f "$SRC" ]; then
	echo "Missing: $SRC" >&2
	exit 1
fi
if [ ! -f "$DST" ]; then
	echo "Luanti dialog not found at: $DST" >&2
	echo "Set LUANTI_BUILTIN to the directory containing dlg_create_world.lua" >&2
	exit 1
fi

echo "Source: $SRC"
echo "Target: $DST"
echo "A backup will be created next to the target (.bak)."
printf "Continue? [y/N] "
read -r ans
case "$ans" in
	y|Y|yes|YES) ;;
	*) echo "Aborted."; exit 1 ;;
esac

sudo cp "$DST" "$DST.bak"
sudo cp "$SRC" "$DST"
echo "Installed. Restart Luanti."
