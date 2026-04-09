# Releases

This directory holds **distribution artifacts** for the repository tree.

All **Godot release exports** below embed the **engine runtime and game data** in one file (`binary_format/embed_pck=true`). Users do **not** install a separate Godot build; the artifact is the full runnable game.

## Windows (`anthill-<version>-windows.exe`)

**x86_64** Windows PE, built from the **`Windows`** export preset. Can be produced **from Linux** with matching export templates (no **rcedit** in preset).

```bash
./scripts/export-windows.sh
```

## Linux x86_64 binary (`anthill-<version>-linux.x86_64`)

Single self-contained ELF (Godot **4.2** Linux export template + embedded PCK). Requires typical desktop GL stack (X11/Wayland).

```bash
./scripts/export-linux.sh
```

## Linux AppImage (`anthill-<version>-x86_64.AppImage`)

Same embedded export as the `.x86_64` binary, packaged as a **portable AppImage** (desktop entry + icon + `AppRun`). Suitable for publishing on GitHub Releases; users `chmod +x` and run. Building uses **`appimagetool`** from `PATH`, **`APPIMAGETOOL`** to a local binary, or a one-time download to **`.cache/anthill-build/`** (see script).

```bash
./scripts/build-linux-appimage.sh
```

## Build everything (current `config/version`)

```bash
./scripts/build-release-binaries.sh
```

Requires **Godot 4.2.x** on `PATH` (`godot4` or `godot`) and **export templates** for that exact engine version under `~/.local/share/godot/export_templates/<version>/`.

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
