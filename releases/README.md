# Releases

This directory holds **distribution artifacts** for the repository tree.

## Linux binary (`anthill-<version>-linux.x86_64`)

Self-contained **Godot 4.2** export (game data embedded in the executable with default preset settings). **x86_64** GNU/Linux (glibc); requires a normal desktop stack (X11/Wayland, OpenGL).

**Run:**

```bash
chmod +x anthill-0.7.10-linux.x86_64
./anthill-0.7.10-linux.x86_64
```

**Rebuild** (from repository root; requires **Godot 4.2.x** matching the project and **export templates** installed for that exact version, e.g. under `~/.local/share/godot/export_templates/<version>/`):

```bash
./scripts/export-linux.sh
```

The output path is derived from **`game/anthill/project.godot`** **`config/version`**. Export preset: **`game/anthill/export_presets.cfg`** (preset name **`Linux`**).

## `anthill` (shell launcher)

Executable shell launcher (same role as **`/usr/local/bin/anthill`** from **`scripts/install-anthill.sh`**): it runs an existing **Godot editor** with **`--path`** pointing at **`game/anthill`** relative to the repository root. Use this when you develop from a clone and do not need a packaged binary.

**Usage** (from repository root):

```bash
./releases/anthill
```

Override engine binary:

```bash
GODOT_BIN=/path/to/Godot_v4.x_linux.x86_64 ./releases/anthill
```

Requires **Godot 4** on `PATH` as **`godot4`** or **`godot`**, or set **`GODOT_BIN`**. See the root **`README.md`** for **`scripts/install-godot4.sh`**.
