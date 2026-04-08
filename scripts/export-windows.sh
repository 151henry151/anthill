#!/usr/bin/env bash
# Build a Windows x86_64 release .exe into releases/ (Godot 4.2.x export templates required).
# Cross-export from Linux is supported; set application/modify_resources=false in the preset if rcedit is unavailable.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$REPO_ROOT/game/anthill"
VER="$(grep -m1 'config/version=' "$PROJECT/project.godot" | sed 's/.*"\(.*\)".*/\1/')"
OUT="$REPO_ROOT/releases/anthill-${VER}-windows.exe"
if [[ ! -f "$PROJECT/project.godot" ]]; then
	echo "export-windows.sh: missing $PROJECT/project.godot" >&2
	exit 1
fi
if ! command -v godot4 &>/dev/null && ! command -v godot &>/dev/null; then
	echo "export-windows.sh: need godot4 or godot on PATH (same major.minor as project features)." >&2
	exit 1
fi
GODOT="${GODOT_BIN:-$(command -v godot4 2>/dev/null || command -v godot)}"
exec "$GODOT" --headless --path "$PROJECT" --export-release "Windows" "$OUT"
