# Patched Luanti “Create world” dialog

Stock Luanti 5.10 always shows **Mapgen** and (unless hidden via `game.conf`) **seed** and generic **Mapgen flags** (caves / dungeons / decorations). For Anthill, `anthill_game/game.conf` already hides those flags and the seed field via `disallowed_mapgen_settings`.

The same Lua changes are **embedded in** `engine/patches/0001-anthill-engine.patch` for the **`anthill`** binary build. This folder is kept so you can still patch **system** `luanti` without compiling the engine.

This directory contains a **small patch** to `builtin/mainmenu/dlg_create_world.lua` that also **hides the mapgen dropdown** when the game allows **exactly one** mapgen (Anthill sets `allowed_mapgens = flat`).

## Install (Linux, system Luanti)

1. Back up the original file:

   ```bash
   sudo cp /usr/share/luanti/builtin/mainmenu/dlg_create_world.lua \
           /usr/share/luanti/builtin/mainmenu/dlg_create_world.lua.bak
   ```

2. Copy the patched file from this repository:

   ```bash
   sudo cp /path/to/anthill/luanti_menu_patch/dlg_create_world.lua \
           /usr/share/luanti/builtin/mainmenu/dlg_create_world.lua
   ```

3. Restart Luanti.

After an **engine upgrade**, compare your backup with the new upstream `dlg_create_world.lua` and re-apply the same logical changes, or restore the backup and ask upstream to merge equivalent behavior.

## What changes in the patch

- After building the mapgen list, if it contains **one** entry, that name is forced and the **Mapgen** label + dropdown are omitted.
- Left column vertical layout is adjusted when the seed field is hidden.
- On **Create**, `dd_mapgen` may be absent; the handler uses `fields["dd_mapgen"] or this.data.mg`.

## Forking Luanti

You do not need a full engine fork for Anthill gameplay; this single-file menu tweak is enough for the “world name only” flow. A fork would only be justified if you want to remove tabs (**Join Game**, **Content**, **About**) or rebrand the window title—those are compiled into the engine or shared `builtin` UI.
