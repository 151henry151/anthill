# Anthill (Minetest)

The browser/Expo prototype is removed. This repository is a **Minetest** mod set: a clean **desert sand** world (no trees or map decorations) and a **giant ant** placeholder sized so that **one node reads like one grain of sand** and an ant spans on the order of **~100 nodes** (tunable in `minetest_mods/anthill_ant/init.lua`).

## Requirements

- [Minetest](https://www.minetest.net/) 5.x (desktop; Linux is the primary target).
- The **Minetest Game** (`minetest_game`) subgame, usually included with official builds or installable from the Content DB.

## Install mods

Copy (or symlink) each folder under `minetest_mods/` into your Minetest user mods directory, for example:

- `~/.minetest/mods/anthill_desert`
- `~/.minetest/mods/anthill_ant`

Names must match the directory names above so `mod.conf` is picked up correctly.

## New world

1. Start Minetest → **Start Game** → select **Minetest Game**.
2. **Select Mods** → enable **anthill_desert** and **anthill_ant** → save.
3. **New** world → create it (mapgen is forced to flat desert by `anthill_desert`; use a **new** world so settings apply cleanly).

You should see flat **desert sand** with **desert stone** below; no trees or plants.

## Try the ant placeholder

In singleplayer you normally have the `server` privilege. Run:

```text
/spawn_ant
```

A ~100-node cube entity appears above you as a stand-in for future ant models and AI.

## Layout

| Mod             | Role |
|-----------------|------|
| `anthill_desert` | Flat mapgen + chunk fill: `default:desert_sand` / `default:desert_stone`, air above surface. |
| `anthill_ant`    | `anthill_ant:giant` entity and `/spawn_ant`. |

## Scale notes

- Block size is fixed by the engine (~1 m). The design intent is **narrative scale**: ants are huge relative to nodes so gameplay treats nodes like sand grains.
- Adjust `visual_size`, `collisionbox`, and `HALF` in `anthill_ant` if you want a different length in nodes.
