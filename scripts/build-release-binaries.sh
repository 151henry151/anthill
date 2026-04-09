#!/usr/bin/env bash
# Build all distributable desktop artifacts: Linux x86_64 export, Windows x86_64 .exe, Linux x86_64 AppImage.
# Godot export templates for 4.2.2 (or matching godot --version) must be installed.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
echo "=== export-linux.sh ==="
./scripts/export-linux.sh
echo "=== export-windows.sh ==="
./scripts/export-windows.sh
echo "=== build-linux-appimage.sh (reuse Linux export) ==="
SKIP_LINUX_EXPORT=1 ./scripts/build-linux-appimage.sh
echo "Done. Artifacts under releases/ (see releases/README.md)."
