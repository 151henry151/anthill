# Anthill

A **Luanti** ([Minetest engine](https://www.luanti.org/)) **subgame**: a desert “grain world” and **giant ant** simulation built **only on the engine**—no Minetest Game, no default mod.

- **Scale**: Each **node** is a **grain of sand** in the fiction; **ants** are **~80-node** cubes (smaller collision) so they dominate the landscape.
- **World**: Procedural **dunes** from 2D Perlin noise over **sand** and **stone**, with a **nest** at the origin.
- **Simulation**: **Trail** and **home** pheromone fields on a coarse grid, **wander + trail following + weak nest bias + separation** between ants. An initial **colony** spawns once per world; use **`/spawn_ants`** for more.

### Cursor: agent terminal

If the Cursor agent’s **Shell** tool shows **no output** or **does not create files** here, see **`docs/cursor-agent-shell.md`** (Agent **sandbox** / **Settings → Agent**).

## Anthill engine (`anthill` command)

This repo ships a **patched Luanti 5.10.0** build that installs a client binary named **`anthill`** (window title **Anthill**, same menu tweaks as `luanti_menu_patch/`). Upstream source is **not** vendored in git; `engine/build.sh` clones [luanti-org/luanti](https://github.com/luanti-org/luanti) and applies `engine/patches/0001-anthill-engine.patch`.

```bash
./engine/build.sh
```

That clones Luanti, applies `engine/patches/0001-anthill-engine.patch`, configures with the **`anthill-engine`** CMake user preset (see **`engine/CMakeUserPresets-anthill.json`**, copied into the Luanti tree by the script), installs, links **`anthill_game`** into `$PREFIX/share/luanti/games/`, and may append **`~/.local/bin`** to **`~/.bashrc`** once.

Installs to `$HOME/.local` by default (`ANTHILL_INSTALL_PREFIX` to change). Then ensure **`~/.local/bin`** is on your `PATH` and run:

```bash
anthill
```

Register the subgame for that install:

```bash
ln -sfn /path/to/anthill/anthill_game ~/.local/share/luanti/games/anthill_game
```

Developer build details, dependencies, and troubleshooting: **`docs/building-from-source.md`** and **`engine/README.md`**. Engine license: **LGPL 2.1+** (same as Luanti).

## Requirements (using system Luanti instead)

Alternatively use stock **[Luanti](https://www.luanti.org/)** 5.8+ (`luanti` package) without building the fork.

You do **not** need `minetest_game` or any Content DB game.

## Install the subgame (system Luanti)

Copy or symlink this folder into your user games directory:

```bash
ln -s /path/to/anthill/anthill_game ~/.minetest/games/anthill_game
```

The directory name **`anthill_game`** must match (it is the **game id**). For the **`anthill`** binary, use `~/.local/share/luanti/games/` as above.

## Play

1. Start **`anthill`** or **`luanti`** → **Start Game** → choose **Anthill**.
2. **New world** (recommended) so mapgen and the one-time colony spawn run cleanly.

### Main menu (what we can change)

Luanti’s shell is still the **engine** main menu. For Anthill, `game.conf` does the following:

- **Mapgen**: only **flat** is allowed as a base pass (dunes are built in Lua on top of it).
- **Start Game tab**: **Creative Mode**, **Enable Damage**, and **Host Server** are **hidden**; they are forced off for this subgame.
- **Create World** (via `disallowed_mapgen_settings`): hides **caves / dungeons / decorations**, the **seed** field, **flat** noise knobs that do not apply, and (with the optional patch below) the **mapgen** dropdown when there is only one choice—leaving **world name** as the main input.

**Menu patch:** If you use **stock** `luanti`, you can still install `luanti_menu_patch/dlg_create_world.lua` manually (`./scripts/install-menu-patch.sh`). The **`anthill`** engine build **already includes** that change (`engine/patches/0001-anthill-engine.patch`).

**Game bar icon:** `anthill_game/menu/icon.png` is used as the game icon; `menu/background.png` themes the menu backdrop.

**Hiding “Minetest Game” in the bottom bar:** Luanti lists every installed subgame. On Debian you can remove the default game package: `sudo apt remove luanti-game-minetest` (you only need the `luanti` engine). Alternatively keep both and ignore the extra icon.

With **stock Luanti**, the window title stays **Luanti**. With the **`anthill`** binary from `./engine/build.sh`, the title uses **Anthill**. You will still see engine tabs such as **Join Game**, **Content**, and **About** unless you change the engine further.

### Commands (usually need `server` / singleplayer host)

- **`/spawn_ants [count]`** — spawn up to 48 extra ants near the nest (default 8).
- **`/ant_count`** — print how many ant entities are active.

## Layout

| Path | Role |
|------|------|
| `anthill_game/game.conf` | Subgame metadata, menu/mapgen restrictions |
| `anthill_game/menu/` | Main-menu background and icon |
| `engine/` | `build.sh`, unified Luanti patch → **`anthill`** binary |
| `luanti_menu_patch/` | Same menu Lua as in the engine patch (for stock `luanti` installs) |
| `scripts/install-menu-patch.sh` | Copy menu Lua into system Luanti only |
| `anthill_game/mods/anthill/` | Nodes, dunes mapgen, pheromones, `anthill:ant` entities, player spawn, chat commands |

Tune dunes (`SURFACE_BASE`, `DUNE_AMP`, `SAND_DEPTH`) and ant size (`VIS`, `COLL_HALF` in `ant_entity.lua`) as needed.
