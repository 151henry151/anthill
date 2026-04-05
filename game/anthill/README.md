# Anthill (Godot)

Godot **4.2+** game: **one voxel = one sand grain** in fiction (~3 mm; see `scripts/constants.gd`). The world is a **chunked heightmap** (Minecraft-like layers: air / sand / stone) with **falling sand** each physics tick. You watch from a **top-down colony camera** (not direct ant control); later: food, queen, and colony priorities.

## Run

1. Install [Godot 4.2+](https://godotengine.org/download/).
2. **Import** this folder (`game/anthill`) as a project, or run from a terminal:

   ```bash
   godot --path /path/to/anthill/game/anthill
   ```

3. Press **F5** (or **Run Project**). The game starts at **`scenes/loading_screen.tscn`** (Anthill title, art, load bar), then enters **`scenes/main.tscn`**. You can still open **`main.tscn`** directly in the editor to inspect the colony scene.

## Layout

| Path | Role |
|------|------|
| `scripts/constants.gd` | Grain size fiction, block type ids |
| `scripts/world/` | Chunk storage, procedural fill, meshing, sand step |
| `scripts/colony_camera.gd` | Orthographic top-down pan/zoom |
| `scripts/main_controller.gd` | Chunk mesh instances; spreads first full mesh build across frames (`initial_mesh_chunks_per_frame`) |
| `scripts/entities/ant.gd` | Reserved for future AI ant mesh (not used as player) |
| `scenes/loading_screen.tscn` | Boot UI: threaded load of `main.tscn` with a progress bar |
| `scenes/main.tscn` | World, lights, floor collision, UI hint |
| `scenes/ant.tscn` | Unused prototype scene (kept for a future AI ant asset) |
| `tools/generate_splash_assets.py` | Regenerate `assets/splash/*.png` (requires **Pillow**: `pip install pillow`) |

## Limits (prototype)

- **Voxel–collision** for terrain is not implemented; a large **floor** collider is a stand-in. Mesh or heightfield collision per chunk is a natural next step.
- **Mesh rebuild** runs every physics frame after sand settles; fine for `3×3` chunks, optimize later.
