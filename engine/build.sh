#!/usr/bin/env bash
# Build the Anthill-patched Luanti engine and install the `anthill` binary.
# Uses CMake Presets (CMake 3.22+): see ../CMakePresets.json, preset "anthill-engine".
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/third_party/luanti-src"
INSTALL_PREFIX="${ANTHILL_INSTALL_PREFIX:-$HOME/.local}"
export ANTHILL_INSTALL_PREFIX="$INSTALL_PREFIX"
LUANTI_TAG="${LUANTI_TAG:-5.10.0}"
PATCH="$ROOT/engine/patches/0001-anthill-engine.patch"

if [ ! -f "$PATCH" ]; then
	echo "Missing patch: $PATCH" >&2
	exit 1
fi

mkdir -p "$ROOT/third_party"

if [ ! -d "$SRC/.git" ]; then
	echo "Cloning Luanti $LUANTI_TAG (this may take a few minutes)..."
	git clone --recursive --depth 1 --branch "$LUANTI_TAG" \
		https://github.com/luanti-org/luanti.git "$SRC"
else
	echo "Using existing $SRC (delete it to re-clone)."
fi

cd "$SRC"
git reset --hard
git clean -fd
git submodule update --init --recursive
echo "Applying Anthill patch..."
git apply "$PATCH"

cd "$ROOT"

if cmake --help 2>/dev/null | grep -q "preset"; then
	echo "Configuring with CMake preset 'anthill-engine'..."
	cmake --preset anthill-engine
	echo "Building..."
	cmake --build --preset anthill-engine
	echo "Installing to $INSTALL_PREFIX ..."
	cmake --install --preset anthill-engine
else
	echo "CMake presets not available; using manual configure (install CMake 3.22+ for presets)."
	mkdir -p "$ROOT/engine/out/build"
	cd "$ROOT/engine/out/build"
	cmake "$SRC" \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
		-DBUILD_CLIENT=ON \
		-DBUILD_SERVER=OFF \
		-DRUN_IN_PLACE=FALSE
	cmake --build . -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"
	cmake --install .
fi

GAMES_DIR="$INSTALL_PREFIX/share/luanti/games"
mkdir -p "$GAMES_DIR"
ln -sfn "$ROOT/anthill_game" "$GAMES_DIR/anthill_game"
echo "Linked subgame: $GAMES_DIR/anthill_game -> $ROOT/anthill_game"

BIN_DIR="$INSTALL_PREFIX/bin"
if [[ ":$PATH:" != *":$BIN_DIR:"* ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
	PROFILE=""
	for try in "$HOME/.bashrc" "$HOME/.profile"; do
		if [ -f "$try" ] && ! grep -qF '.local/bin' "$try" 2>/dev/null; then
			echo "" >>"$try"
			echo "# Anthill engine (Luanti fork)" >>"$try"
			echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >>"$try"
			echo "Appended PATH to $try"
			PROFILE=1
			break
		fi
	done
	if [ -z "${PROFILE:-}" ]; then
		echo "Note: add to PATH:  export PATH=\"\$HOME/.local/bin:\$PATH\""
	fi
fi

echo ""
echo "Done. Run:  $BIN_DIR/anthill"
echo "(Open a new terminal if you updated PATH.)"
