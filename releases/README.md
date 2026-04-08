# Releases

This directory holds **distribution helpers** for the current tree. The game is a **Godot 4** project under **`../game/anthill/`**; there is no single self-contained engine export in the repo (that would be produced with an export preset and **`godot --export-release`**).

## `anthill` (launcher)

Executable shell launcher (same role as **`/usr/local/bin/anthill`** from **`scripts/install-anthill.sh`**): it runs Godot with **`--path`** pointing at **`game/anthill`** relative to the repository root.

**Version** matches **`game/anthill/project.godot`** **`config/version`** (currently **0.7.10**).

**Usage** (from repository root, after `chmod +x releases/anthill` if needed):

```bash
./releases/anthill
```

Override engine binary:

```bash
GODOT_BIN=/path/to/Godot_v4.x_linux.x86_64 ./releases/anthill
```

Requires **Godot 4** on `PATH` as **`godot4`** or **`godot`**, or set **`GODOT_BIN`**. See the root **`README.md`** for **`scripts/install-godot4.sh`**.
