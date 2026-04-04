# Anthill (Godot)

Godot **4.2+** game: **one voxel = one sand grain** in fiction (~3 mm; see `scripts/constants.gd`). The world is a **chunked heightmap** (Minecraft-like layers: air / sand / stone) with **falling sand** each physics tick and an **ant** that can **grab** one sand block and **place** it elsewhere.

## Run

1. Install [Godot 4.2+](https://godotengine.org/download/).
2. **Import** this folder (`game/anthill`) as a project, or run from a terminal:

   ```bash
   godot --path /path/to/anthill/game/anthill
   ```

3. Press **F5** or open `scenes/main.tscn` and run.

## Layout

| Path | Role |
|------|------|
| `scripts/constants.gd` | Grain size fiction, block type ids |
| `scripts/world/` | Chunk storage, procedural fill, meshing, sand step |
| `scripts/entities/ant.gd` | Player ant: move, ray pick sand, place |
| `scenes/main.tscn` | World, lights, floor collision, UI hint |
| `scenes/ant.tscn` | Ant body + camera |

## Limits (prototype)

- **Voxel–collision** for terrain is not implemented; a large **floor** collider plus rough Y clamp keeps the ant from falling forever. Mesh or heightfield collision per chunk is a natural next step.
- **Mesh rebuild** runs every physics frame after sand settles; fine for `3×3` chunks, optimize later.
