# Anthill — Godot simulation project

This directory is the **Godot 4.2+** project for **Anthill**, a **voxel-resolved ant colony simulation** with *Lasius niger*–inspired chemistry and behavior (see the repository root **`README.md`**). One **voxel** corresponds to one **sand grain** in the fiction (~3 mm; **`scripts/constants.gd`**). The world is a **chunked heightmap** (air / loose sand / packed sand / stone); **sand physics** runs each physics tick. The observer views the colony from an **orthographic top-down camera**—there is **no direct control** of individual workers; the interface is for **monitoring**, **inspection**, and **optional data export**.

## Launch sequence

1. Install [Godot 4.2+](https://godotengine.org/download/).
2. Open this folder as a project, or run:

   ```bash
   godot --path /path/to/anthill/game/anthill
   ```

3. **Run Project** (**F5**). The startup sequence is:
   - **`scenes/intro_video.tscn`** — full-screen **Ogg Theora** clip (`assets/intro/intro.ogv`; **any key**, mouse button, gamepad button, or touch to skip);
   - **`scenes/simulation_settings.tscn`** — scrollable form of all **`SimParams`** (mutable mirrors of **`scripts/constants.gd`**); **Reset to defaults** or edit fields, then **Start simulation**;
   - **`scenes/loading_screen.tscn`** — threaded load of **`scenes/main.tscn`** with a progress bar;
   - **`scenes/main.tscn`** — colony, terrain, and UI layers.

Opening **`main.tscn`** directly in the editor still loads the colony scene for inspection without the intro or parameter screen.

## Observation and analysis UI

- **HUD** (top-left): colony stage, **ant-day** clock, queen energy reserve, colony food stores (carbohydrate vs protein mass vs soft targets), worker and brood counts, **simulation tick**, brood stage breakdown, nest entrance coordinates, active food patches, pheromone grid statistics, grain-scale note.
- **[P]**: Toggle **pheromone field** overlay — **recruitment trail**, **CHC footprint**, **alarm** (Dufour-type), and **nest-construction** channels at distinct false-color heights; a **legend** lists channels.
- **Right-click** a worker: **inspector** (bottom-right) — behavioral state, age (ticks and ant-days), caste, metabolic placeholders, crop load, heading, distance to nest, local **trail / footprint / alarm** samples. **Escape** clears selection.
- **Validation export:** When **`VALIDATION_EXPORT_ENABLED`** is set in **`SimParams`** (defaults in **`scripts/constants.gd`**), the simulation appends **`user://validation/colony_ticks.csv`** and **`user://validation/workers_sample.csv`** at **`VALIDATION_EXPORT_INTERVAL_TICKS`** for offline analysis (paths are under Godot’s per-user data directory).
- **[F]**: Cycles **fast-forward** multipliers (`Engine.time_scale`); simulation **ticks** advance **multiple sub-steps per frame** so ant-days remain consistent (see **`main_controller.gd`**).
- **Simulation parameters…** (HUD button) or **F10**: Pauses the game and opens the same scrollable **`SimParams`** form as pre-run (**`simulation_settings.tscn`** in **runtime** mode). Edits apply immediately; **Continue simulation** or **Esc** resumes.

## Layout (selected paths)

| Path | Role |
|------|------|
| `scripts/constants.gd` | Grain fiction, block ids, brood durations, pheromone and foraging parameters |
| `scripts/world/` | Chunk storage, procedural fill, meshing, sand step |
| `scripts/colony_ants.gd` | Worker state machine, tropotaxis, footprint/trail interaction, food memory |
| `scripts/pheromone_field.gd`, `footprint_field.gd`, `alarm_field.gd`, `building_pheromone.gd` | Chemical grids |
| `scripts/queen_ant.gd`, `brood_manager.gd` | Queen lifecycle and brood |
| `scripts/main_controller.gd` | Scene wiring, tick loop, mesh rebuild budget, overlays |
| `scripts/simulation_param_help.gd` | Human-readable lines for each **`SimParams`** key in **`simulation_settings.tscn`** |
| `scripts/nest_builder.gd` | Blueprint galleries (exposed voxels only); used before organic **`nest_manager`** dig scoring |
| `scripts/nest_manager.gd` | Dig front, reservations, spoil, **`get_dig_target`** scoring |
| `scripts/perf_trace.gd` | Optional autoload timing log (**`ANTHILL_PERF_TRACE=0`** to disable) |
| `scenes/intro_video.tscn` | Intro playback; skip → simulation settings |
| `assets/intro/` | **`intro.ogv`** (runtime), **`Isolating_the_Negative_Feedback_Loop_in_Ant_Foraging.mp4`** (source for transcoding) |
| `tools/generate_splash_assets.py` | Regenerate `assets/splash/*.png` (**Pillow** required) |

## Prototype limitations

- **Large colonies:** with many workers and high **[F]** speed, **`main_controller`** may cap simulation sub-steps per frame and batch chemical-field updates so the UI (camera, overlays) stays responsive; tune **`SIM_SUBSTEP_*`** and **`PHEROMONE_MAX_DIFFUSION_PASSES_PER_FRAME`** in **`constants.gd`** if needed.
- **Terrain collision** is not voxel-accurate; a large **floor** collider approximates walkable space.
- **Mesh rebuild** cadence and chunk count should be tuned if you enlarge the world or raise fast-forward tiers.
- **Video:** Only **Ogg Theora** is supported by the stock **`VideoStreamPlayer`**; re-encode MP4 sources with **`ffmpeg`** when replacing **`intro.ogv`**.

For literature, specification text, **`architecture_of_emergence.txt`**, and tables, see **`../../docs/reference/`**. The repository root **`README.md`** includes an **“Architecture of Emergence (reference mapping)”** section that lists which ideas from that document are implemented in code versus omitted or only partially modeled.

## License

Licensed under the **GNU GPL v3 or later** (SPDX **`GPL-3.0-or-later`**). See **`../../LICENSE`** in the repository root.
