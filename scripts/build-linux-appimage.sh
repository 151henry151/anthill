#!/usr/bin/env bash
# Build a portable Linux AppImage wrapping the Godot export (engine + embedded PCK in usr/bin/anthill).
# Requires: curl or wget (to fetch appimagetool if missing), FUSE only to *run* AppImages (not to build).
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$REPO_ROOT/game/anthill"
VER="$(grep -m1 'config/version=' "$PROJECT/project.godot" | sed 's/.*"\(.*\)".*/\1/')"
LINUX_BIN="$REPO_ROOT/releases/anthill-${VER}-linux.x86_64"
OUT="$REPO_ROOT/releases/anthill-${VER}-x86_64.AppImage"
APPDIR="$REPO_ROOT/.cache/anthill-appimage/Anthill.AppDir"
ICON_SRC="$REPO_ROOT/game/anthill/assets/splash/anthill_boot.png"

# Set SKIP_LINUX_EXPORT=1 if **`export-linux.sh`** already ran (e.g. from **`build-release-binaries.sh`**).
if [[ "${SKIP_LINUX_EXPORT:-0}" != "1" ]]; then
	"$REPO_ROOT/scripts/export-linux.sh"
fi
if [[ ! -f "$LINUX_BIN" ]]; then
	echo "build-linux-appimage.sh: missing export $LINUX_BIN" >&2
	exit 1
fi
if [[ ! -f "$ICON_SRC" ]]; then
	echo "build-linux-appimage.sh: missing icon $ICON_SRC" >&2
	exit 1
fi

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
cp -a "$LINUX_BIN" "$APPDIR/usr/bin/anthill"
chmod +x "$APPDIR/usr/bin/anthill"
cp -a "$ICON_SRC" "$APPDIR/anthill.png"

cat >"$APPDIR/anthill.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Anthill
Comment=Grain-scale Lasius niger-inspired ant colony simulation (Godot 4.2)
Exec=anthill
Icon=anthill
Categories=Simulation;
Terminal=false
Keywords=simulation;ants;science;
EOF

cat >"$APPDIR/AppRun" <<'APPRUN'
#!/usr/bin/env bash
# AppImage entry: run packaged Godot export (self-contained engine + PCK).
set -euo pipefail
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="$HERE/usr/bin:$PATH"
exec "$HERE/usr/bin/anthill" "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

resolve_appimagetool() {
	if [[ -n "${APPIMAGETOOL:-}" ]]; then
		echo "$APPIMAGETOOL"
		return
	fi
	if command -v appimagetool &>/dev/null; then
		command -v appimagetool
		return
	fi
	local cached="$REPO_ROOT/.cache/anthill-build/appimagetool-x86_64.AppImage"
	mkdir -p "$(dirname "$cached")"
	if [[ ! -f "$cached" ]]; then
		echo "build-linux-appimage.sh: downloading appimagetool to $cached" >&2
		if command -v curl &>/dev/null; then
			curl -fsSL -o "$cached" "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
		elif command -v wget &>/dev/null; then
			wget -q -O "$cached" "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
		else
			echo "build-linux-appimage.sh: need curl or wget to fetch appimagetool, or install appimagetool and set APPIMAGETOOL" >&2
			exit 1
		fi
	fi
	chmod +x "$cached"
	echo "$cached"
}

TOOL="$(resolve_appimagetool)"
echo "Using appimagetool: $TOOL"
rm -f "$OUT"
ARCH=x86_64 "$TOOL" "$APPDIR" "$OUT"
echo "Wrote $OUT"
ls -lh "$OUT"
