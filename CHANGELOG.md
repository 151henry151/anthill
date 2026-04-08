# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Pheromone field view [P]**: overlay shows **recruitment trail** (green), **footprint / CHC** (magenta), and **nest construction** pheromone (amber) at distinct heights; **legend** panel lists channels and colors.
- **Worker inspector**: **right-click** a worker for ID, behavioral state, age (ticks and ant-days), caste, health / metabolic placeholders, crop load, heading, distance to nest, and local **trail / footprint** samples; **Escape** clears selection; torus highlight on selected worker.
- **Scientific HUD**: simulation tick, brood breakdown (eggs / larvae / pupae), nest coordinates, active food patches, pheromone grid cell counts, grain-scale note; colony food stores as **mass vs target** with percent.
- **`scripts/footprint_field.gd`**: passive **cuticular hydrocarbon** footprint grid (slow decay, same resolution as recruitment trail).
- **`briefing.txt`**: synthesis of **Lasius niger** foraging feedback (attractive trail vs footprint hydrocarbon negative feedback).
- **`Ant Foraging and Communication Simulation Data - Table 1.csv`**: reference table of pheromone types and behaviors for **L. niger** and comparison species.

### Changed

- **`scripts/constants.gd`**: add **`FOOTPRINT_*`**, **`TRAIL_SATURATION_*`**, and related scout/tropotaxis tuning.
- **`scripts/main_controller.gd`**: create **`FootprintField`**, assign **`colony_ants.footprint_field`**, tick footprint each sim tick.
- **`scripts/colony_ants.gd`**: deposit footprint each successful step; **FORAGING_SCOUT** uses footprint- and trail-weighted Moore roulette; **FORAGING_RECRUIT** tropotaxis adds repulsion from higher neighbor footprint; scale **fed-worker** recruitment deposits by trail saturation; document recruitment-only deposits.

## [0.6.2] - 2026-04-08

### Changed

- **`scripts/constants.gd`**: add **`PHEROMONE_DIFFUSION_LAMBDA`** and **`PHEROMONE_TROPOTAXIS_FLOOR`**.
- **`scripts/pheromone_field.gd`**: **4-neighbor Laplacian diffusion** on the trail grid each evaporation interval, then evaporation (spatial spreading of pheromone).
- **`scripts/colony_ants.gd`**: **FORAGING_SCOUT** uses a **shuffled uniform Moore** step each move until a trail is sensed; **FORAGING_RECRUIT** uses **tropotaxis** (roulette weighted by **`floor + max(0, c_neighbor − c_here)`** on walkable Moore neighbors).

## [0.6.1] - 2026-04-07

### Fixed

- **`scripts/colony_ants.gd`**: when a move hits the map edge or bad terrain, try wall slides (for diagonals) then a random valid neighbor instead of staying put — reduces worker clustering in world corners.

### Changed

- **`scripts/colony_ants.gd`**: **FORAGING_SCOUT** uses an unbiased random walk instead of a strong outward bias from the nest.

## [0.6.0] - 2026-04-06

### Fixed

- **`scripts/nest_manager.gd`**: replace unbounded linear `DEPTH_WEIGHT` dig scoring with capped entry-shaft pull (`DEPTH_WEIGHT_ENTRY` × min(depth, `SHAFT_TARGET_DEPTH`)), horizontal expansion bias (`HORIZONTAL_WEIGHT` × normalized distance from shaft), and depth-triggered branching (horizontal mode activates once shaft reaches `SHAFT_TARGET_DEPTH` instead of waiting for `CHAMBER_THRESHOLD` volume). Nests now form a short vertical shaft then branch into horizontal galleries instead of diving to maximum depth.
- **`scripts/nest_manager.gd`**: initialize `_rng` in `bind_world()` so `get_path_to_surface()` does not crash when called before `setup()`.
- **`scripts/colony_ants.gd`**: deposit trail pheromone every movement step while in RETURNING state with food (was only deposited in `_step_random_walk` which RETURNING never called). Deposit amount scales with proximity to food source (`PHEROMONE_BASE_DEPOSIT` + `PHEROMONE_DISTANCE_BONUS` × food_proximity).
- **`scripts/colony_ants.gd`**: add scout-to-recruit transition — departing and scouting ants sample pheromone in a `PHEROMONE_SENSE_RADIUS`-voxel area and switch to FORAGING_RECRUIT when concentration exceeds `PHEROMONE_RECRUIT_THRESHOLD`. Recruits revert to scout when trail concentration drops below half threshold.
- **`scripts/colony_ants.gd`**: replace pure random walk in FORAGING_SCOUT with correlated random walk biased 40% outward from nest, producing realistic fan-out search pattern.
- **`scripts/colony_ants.gd`**: replace fixed 50%/60% dig/forage probability in task assignment with food-aware ratios — `food_urgency` (0–1) based on deficit from `FOOD_STORE_TARGET_SUGAR`/`FOOD_STORE_TARGET_PROTEIN` drives forager fraction from 15% (stores full) to 65% (stores empty); digging capped at 15% when food is urgent.

### Changed

- **`scripts/constants.gd`**: replace `DEPTH_WEIGHT` (0.8) with `SHAFT_TARGET_DEPTH` (14), `DEPTH_WEIGHT_ENTRY` (1.2), `DEPTH_WEIGHT_CHAMBER` (2.0), `DEPTH_ATTRACTION_FALLOFF` (0.15), `MAX_GALLERY_RADIUS` (20), `HORIZONTAL_WEIGHT` (1.8). Add `PHEROMONE_BASE_DEPOSIT` (0.08), `PHEROMONE_DISTANCE_BONUS` (0.12), `PHEROMONE_RECRUIT_THRESHOLD` (0.02), `PHEROMONE_SENSE_RADIUS` (4), `FOOD_STORE_TARGET_SUGAR` (200), `FOOD_STORE_TARGET_PROTEIN` (150), `MIN_FORAGER_FRACTION` (0.15), `SCOUT_MAX_TURN_DEG_PER_STEP` (25), `SCOUT_MIN_SEARCH_RADIUS` (15). Reduce `PHEROMONE_EVAPORATION_INTERVAL_TICKS` from 60 to 30. Increase `TUNNEL_CONTINUE_BONUS` to 2.5, `NOISE_AMPLITUDE` to 0.5, `TUNNEL_EXTEND_BIAS` to 3.0.

## [0.5.26] - 2026-04-06

### Added

- **`scripts/constants.gd`**: **`FOOD_*`** tuning for random food spawns, spoil durations, nest clearance, and visual scale limits; **`QUEEN_TROPHALLAXIS_*`** parameters for worker-to-queen feeding from colony stores.
- **`scripts/main_controller.gd`**: spawn food sources at random intervals and positions; prune depleted or spoiled sources; respect **`FOOD_MAX_ACTIVE_SOURCES`**; call queen trophallaxis once per simulation tick.
- **`scripts/food_source.gd`**: finite supply per patch, linear spoil decay and hard expiry, visuals that shrink and brown as food rots or is collected.
- **`scripts/queen_ant.gd`**: **`apply_worker_trophallaxis`** — established queens gain **`energy_reserve`** from **`colony_food_store`** when workers are present (modeled on **stomodeal trophallaxis**).

## [0.5.25] - 2026-04-04

### Changed

- **`scripts/constants.gd`**: remove **500×** and **1000×** from **`FAST_FORWARD_SPEEDS`**; set **`FAST_FORWARD_SIM_STEPS_CAP`** to **120** to match the maximum **[F]** tier.
- **`scenes/main.tscn`**: shorten the on-screen **[F]** hint to match the fast-forward cycle.

## [0.5.24] - 2026-04-04

### Fixed

- **`scripts/queen_ant.gd`**: run **flying-in**, **wing shedding**, **searching**, and **digging** once per fast-forward sub-step so nest excavation keeps pace with the game clock.
- **`scripts/colony_ants.gd`**: advance worker move timers per sub-step and allow **multiple** move steps per frame when the interval is exceeded.

## [0.5.23] - 2026-04-05

### Fixed

- **`scripts/main_controller.gd`**: advance **`round(Engine.time_scale)`** simulation sub-steps per physics frame so **[F]** fast-forward changes ant-days and colony ticks ( **`Engine.time_scale`** alone only scaled **`delta`**, not tick-based sim).
- **`scripts/queen_ant.gd`**: run **claustral** / **established** egg and energy logic once per sub-step to match **`main_controller`**.
- **`scripts/constants.gd`**: add **`FAST_FORWARD_SIM_STEPS_CAP`** to bound sub-steps per frame.

### Changed

- **`project.godot`**: enable **4× MSAA** for 3D (**`anti_aliasing/quality/msaa_3d`**).

## [0.5.22] - 2026-04-05

### Changed

- **`scripts/constants.gd`**: replace stuck-step **instant** excavation with **`WORKER_ENTRANCE_CLEAR_ENGAGE_DIST`** only.
- **`scripts/colony_ants.gd`**: detect **sand / packed sand** in the founding **shaft footprint** and route workers through **dig** states (duration, `on_voxel_removed`) until the shaft no longer needs clearing; **returning**, **brood care** (near nest), and **resting** (near nest) can engage; resume **`post_entrance_state`** when done.

## [0.5.21] - 2026-04-05

### Changed

- **`scripts/constants.gd`**, **`scenes/main.tscn`**: append **1000×** to **`FAST_FORWARD_SPEEDS`** and the on-screen **[F]** hint (testing).

## [0.5.20] - 2026-04-05

### Changed

- **`scripts/constants.gd`**: add **`NEST_SPILL_LATERAL_EXCLUDE_RADIUS`**, **`WORKER_NEST_ARRIVAL_MAX_DIST`**, and **`WORKER_ENTRANCE_DIG_*`** for nest mouth / returning behavior.
- **`scripts/main_controller.gd`**: set **`world.nest_spill_exclude_xz`** when the founding chamber is ready for sand spill exclusion.
- **`scripts/world/sand_step.gd`**: skip lateral-spill **destinations** inside the nest exclusion disk so spill sand does not land in the shaft mouth ring.
- **`scripts/colony_ants.gd`**: widen **returning** completion distance; after prolonged stuck near the nest, remove one **loose sand** voxel in a small grid around the entrance to unplug.

## [0.5.19] - 2026-04-05

### Changed

- **`scripts/constants.gd`**: add **`SAND_LATERAL_SPILL_STACK_LIMIT`** for loose-sand column height.
- **`scripts/world/sand_step.gd`**: after gravity, spill one top grain per column to the **lowest** valid lateral neighbor at or below the current top when contiguous **loose sand** exceeds the limit (reduces vertical **1×1** towers).

## [0.5.18] - 2026-04-05

### Changed

- **`scripts/constants.gd`**, **`scenes/main.tscn`**: append **500×** to **`FAST_FORWARD_SPEEDS`** and the on-screen **[F]** hint.
- **`scripts/constants.gd`**: quadruple **food source** spawn range (**12–24** instead of **3–6**).
- **`scripts/constants.gd`**: widen spoil **annulus** (**`SPOIL_DEPOSIT_RADIUS`** **24**, **`SPOIL_DEPOSIT_INNER_CLEAR`** **3.5**) for a broader surface ring around the entrance.
- **`scripts/nest_manager.gd`**: choose worker spoil deposits by **lowest surface height** among random disk samples (remove **maximize building-pheromone** scoring that stacked sand on single columns).
- **`scripts/queen_ant.gd`**: choose queen spoil deposits with the same **lowest-surface** rule and **`MAX_SPOIL_HEIGHT`** filtering.

## [0.5.16] - 2026-04-05

### Changed

- **`scripts/constants.gd`**: set **`QUEEN_LARVA_FEED_ENERGY_PER_LARVA_PER_TICK`** to **0** so larva provisioning is not double-charged against reserves (the previous non-zero value drained the queen orders of magnitude faster than **`QUEEN_CLAUSTRAL_ENERGY_DRAIN`** when many larvae existed).
- **`scripts/constants.gd`**: extend **claustral** survival budget from **~40** to **~55 ant-days** so the queen can survive until the first **egg → larva → pupa → eclosion** window (~34 ant-days after the first worker-destined eggs).

## [0.5.15] - 2026-04-05

### Fixed

- **`scripts/brood_manager.gd`**, **`scripts/queen_ant.gd`**, **`scripts/main_controller.gd`**, **`scripts/constants.gd`**: provision **larvae** during **claustral** and **established-without-workers** (queen **energy** + optional **trophic-egg** consumption); apply **worker trophallaxis** when **`worker_count > 0`** so larvae survive to **pupation** and workers can bootstrap the colony.

## [0.5.14] - 2026-04-05

### Changed

- **`scripts/world/mesh_builder.gd`**: build chunk meshes only over a **tight bounding box** of non-air voxels in the mesh band (skip empty chunks; fewer face checks when the chunk is mostly air).
- **`scripts/constants.gd`**: add **`QUEEN_BFS_AIR_MAX_NODES`**, **`PATH_TO_SURFACE_MAX_STEPS`**, **`QUEEN_SPOIL_DEPOSIT_SAMPLES`** for queen / path limits.
- **`scripts/queen_ant.gd`**: cap **air BFS** when approaching a dig voxel; reduce spoil **deposit** search iterations.
- **`scripts/nest_manager.gd`**: use **`PATH_TO_SURFACE_MAX_STEPS`** for **`get_path_to_surface`** (same default count as before).
- **`scripts/main_controller.gd`**: lower **chunk mesh rebuilds per physics frame** when **`Engine.time_scale`** is high (**≤2** at **≥20×**, **1** at **≥60×**) to shorten worst frames under fast-forward.
- **`scripts/perf_trace.gd`**: read **`VmRSS`** from **`/proc/<pid>/status`** via **`OS.get_process_id()`** (more reliable than **`/proc/self`** in some builds).

## [0.5.13] - 2026-04-05

### Changed

- **`scripts/constants.gd`**: replace single **`FAST_FORWARD_SCALE`** with **`FAST_FORWARD_SPEEDS`** (**10**, **30**, **60**, **120**).
- **`scripts/main_controller.gd`**: map **[F]** to a **1× → 10× → 30× → 60× → 120× → 1×** cycle via **`Engine.time_scale`**.
- **`scripts/colony_hud.gd`**: drive the mode line from **`fast_forward_multiplier`** instead of a fixed constant.
- **`scenes/main.tscn`**: update hint text for the multi-step fast-forward cycle.

## [0.5.12] - 2026-04-05

### Added

- **`scripts/perf_trace.gd`**: autoload **`PerfTrace`** — per-physics-frame timings (**sand**, mesh queue, **chunk rebuild**, colony **systems**, **workers**, **queen**), dictionary size hints (**pending mesh**, **sand column** backlog, **surface** cache, trail / building **pheromone** cells), **`VmRSS`** (Linux) and **`Performance.MEMORY_STATIC`**; logs to **`user://anthill_perf.log`** and prints **`WARN`** lines when total traced time exceeds **20 ms**; periodic lines every **30** ticks (override with env **`ANTHILL_PERF_TRACE_PERIOD`**). Disable with **`ANTHILL_PERF_TRACE=0`**.
- **`project.godot`**: register **`PerfTrace`** autoload.
- **`scripts/world/world_manager.gd`**: add **`debug_sand_column_count`** and **`debug_surface_cache_size`** for tracing.
- **`scripts/pheromone_field.gd`**: add **`debug_trail_cell_count`**.
- **`scripts/building_pheromone.gd`**: add **`debug_build_cell_count`**.

### Changed

- **`scripts/main_controller.gd`**: call **`PerfTrace`** around **`_physics_process`** sections and snapshot context after colony ticks.
- **`scripts/colony_ants.gd`**, **`scripts/queen_ant.gd`**: record **`_physics_process`** duration for **`PerfTrace`**.

## [0.5.11] - 2026-04-05

### Fixed

- **`scripts/colony_ant_model.gd`**: expand **`ARRAY_INDEX`** when merging primitive parts into one **`ArrayMesh`** (the **`85ec603`** merge walked vertex arrays in storage order, but **SphereMesh** / **CylinderMesh** use indexed triangles, so merged geometry and normals were wrong and ants could render invisible).

## [0.5.10] - 2026-04-05

### Changed

- **`scripts/spoil_deposit.gd`**, **`scripts/nest_manager.gd`**, **`scripts/queen_ant.gd`**: sample spoil / mound deposit offsets on a **uniform disk** (polar + **r = sqrt(u) × radius**) with a circular inner clearance, instead of independent **`randi_range`** on **dx/dz** (which filled a square).
- **`scripts/constants.gd`**: add **`SPOIL_DEPOSIT_INNER_CLEAR`** for the minimum radius from the nest center used when sampling spoil positions.

### Fixed

- **`scripts/queen_ant.gd`**: place the queen’s feet on the floor of each occupied voxel (`_apply_queen_cell_pos`) using the same body-origin offset as **`_place_on_surface`**, instead of voxel centers on Y (which buried the mesh in solid terrain during dig/carry); snap **`DIGGING`** start to the air cell above the surface block and align claustral placement with **`_apply_queen_cell_pos`**.

## [0.5.9] - 2026-04-04

### Changed

- **`scripts/world/terrain_gen.gd`**: fill subsurface sand columns with **`BLOCK_PACKED_SAND`** instead of **`BLOCK_SAND`**; document sand-column callback for sand-like blocks.
- **`scripts/main_controller.gd`**: skip **`sand_step`** while the queen’s **`sand_physics_suppressed()`** is true.
- **`scripts/queen_ant.gd`**: excavate the founding shaft and chamber **one voxel per trip** — approach through air when possible, multi-tick dig act, carry mesh while ascending **`get_path_to_surface`**, deposit loose **`BLOCK_SAND`** near the nest, then return for the next block (replacing whole-layer shaft removal and instant chamber clearing).
- **`scripts/constants.gd`**: replace **`QUEEN_DIG_INTERVAL`** with **`QUEEN_DIG_ACT_TICK_INTERVAL`** for queen dig-act timing alongside **`WORKER_MOVE_INTERVAL`** path steps.

## [0.5.8] - 2026-04-05

### Changed

- **`scripts/world/terrain_gen.gd`**: fill procedural terrain with **`BLOCK_PACKED_SAND`** instead of **`BLOCK_SAND`** so the initial world is entirely packed sand; loose sand remains for ant-placed voxels (e.g. spoil deposits).

## [0.5.7] - 2026-04-05

### Fixed

- **`scripts/queen_ant.gd`**, **`scripts/main_controller.gd`**: suppress **falling-sand** (`sand_step`) while the queen is in **`DIGGING`** so loose sand cannot refill excavated voxels between dig ticks (sand ran every physics frame; digging runs on a longer interval).

## [0.5.6] - 2026-04-05

### Fixed

- **`scripts/queen_ant.gd`**: center the founding **shaft** footprint on **`(_wx, _wz)`** (even **`FOUNDING_SHAFT_WIDTH`**) so excavation aligns with the queen’s cell-center position; snap the queen to the first shaft layer when entering **DIGGING** and prime **`_dig_timer`** so the first dig runs on the next physics tick instead of after a full dig interval.

## [0.5.5] - 2026-04-05

### Fixed

- **`scripts/queen_ant.gd`**: record **`_shaft_top_y`** when founding dig starts and use it for shaft and chamber depth math so the surface level does not drift after the column is hollowed out.
- **`scripts/queen_ant.gd`**: seal the founding shaft with **`BLOCK_PACKED_SAND`** across the full shaft footprint at **`_shaft_top_y`** instead of placing a single loose **`BLOCK_SAND`** at **`sy + 1`**, which fell through the shaft in **`sand_step.gd`** (only loose sand moves) and refilled the nest.

## [0.5.4] - 2026-04-05

### Added

- **`scenes/loading_panel.tscn`**: reusable splash UI (background, title, hero art, progress bar) for the first-load screen and the main scene overlay.

### Changed

- **`scripts/main_controller.gd`**: defer **`_setup_systems`** until all **initial chunk meshes** are built; skip **`_physics_process`** and block **`_unhandled_input`** until then; show **`TerrainLoadOverlay`** (same panel as the loading screen) with a **0–100%** bar driven by mesh build progress; disable **`ColonyAnts`** processing during the build; use a larger **`initial_load_chunks_per_frame`** (default **32**) for the splash-phase batch build.
- **`scripts/loading_screen.gd`**, **`scenes/loading_screen.tscn`**: instance **`loading_panel.tscn`** instead of duplicating nodes; remove the forced **100%** bar jump before switching scenes.
- **`scenes/main.tscn`**: add **`TerrainLoadOverlay`** (`CanvasLayer`) with an instanced **`loading_panel`**.

## [0.5.3] - 2026-04-05

### Changed

- **`scenes/loading_screen.tscn`**: set **`texture_filter`** to **linear** on the loading root so splash art matches smooth previews (project **`default_texture_filter`** remains **nearest** for the rest of the UI).

## [0.5.2] - 2026-04-04

### Added

- **`scripts/day_night_cycle.gd`**: drive **`DirectionalLight3D`** orientation and color/energy from **`_game_tick`** so one full sun arc matches one **ant-day** (`TICKS_PER_ANT_DAY`); blend **`WorldEnvironment`** ambient and background for night.
- **`scripts/main_controller.gd`**, **`scenes/main.tscn`**: add **`DayNightCycle`** node; enable directional **shadows** (PSSM, max distance) on the sun light.
- **`scripts/colony_hud.gd`**: show a **24h-style clock** next to the day counter (same phase as the visual cycle).

## [0.5.1] - 2026-04-06

### Fixed

- **`scripts/colony_ants.gd`**: include **BROOD_CARE** workers past **`YOUNG_WORKER_AGE_THRESHOLD`** in **`_assign_tasks`** so they can be given **foraging** / **dig** / **rest** (previously only **EMERGING**/**RESTING** ants were reassigned, so interior workers never “graduated”).

### Changed

- **`scripts/constants.gd`**: set **`FAST_FORWARD_SCALE`** to **30** (was **10**).
- **`scripts/colony_hud.gd`**: show fast-forward multiplier from **`FAST_FORWARD_SCALE`** in the mode line.

## [0.4.2] - 2026-04-05

### Fixed

- **`scripts/nest_manager.gd`**: add **`bind_world`** so **`_world`** is set before the queen’s digging phase calls **`compact_around`** (full **`setup`** was only run at **`founding_chamber_ready`**).
- **`scripts/main_controller.gd`**: call **`bind_world(world)`** immediately after adding **`NestManager`**.

## [0.5.0] - 2026-04-05

### Added

- **`scripts/constants.gd`**: add **`BLOCK_PACKED_SAND`** (value 3) block type for stable compacted tunnel walls; add nest excavation constants (compaction radius, dig durations, spoil deposit radius, volume regulation, tunnel/chamber dimensions, dig target scoring weights, building pheromone parameters, x-ray view alpha).
- **`scripts/building_pheromone.gd`**: 3D building pheromone field for stigmergic construction coordination; sparse `Vector3i → float` grid with deposition (6-connected neighbor spread), multiplicative evaporation, and query API.
- **`scripts/nest_manager.gd`**: colony-level nest manager with `compact_around()` (converts SAND shell to PACKED_SAND on excavation), dig front tracking, voxel reservation system, stigmergic dig target scoring (depth bias, tunnel continuation bonus, crowding penalty, radial/branching transition), spoil deposit site selection with building pheromone feedback, greedy path-to-surface navigation for tunnel traversal, and nest volume regulation.
- **`scripts/colony_ants.gd`**: add worker digging states (DIGGING_APPROACH, DIGGING_ACT, CARRYING_TO_SURFACE, DEPOSITING) with voxel carry system — carried voxel visual mesh on ant, pick/drop mechanics, path-following through tunnels, stigmergic deposit on surface as loose SAND.
- **`scripts/main_controller.gd`**: add x-ray view toggle (X key) swapping terrain chunk materials between opaque and semi-transparent; wire nest_manager and building_pheromone to all systems.

### Changed

- **`scripts/world/mesh_builder.gd`**: add `COL_PACKED_SAND` vertex colour for compacted tunnel walls; add depth tinting to all block vertex colours for x-ray depth cueing.
- **`scripts/queen_ant.gd`**: widen founding shaft to `FOUNDING_SHAFT_WIDTH` (6×6 voxels); enlarge founding chamber to 10×8×10 voxels; call `compact_around()` on every voxel removal during digging to stabilise tunnels with PACKED_SAND; accept `nest_manager` reference.
- **`scripts/colony_ants.gd`**: add volume-deficit-based task assignment for NEST_BUILDING workers; cap concurrent diggers at `MAX_NEST_BUILDERS`.
- **`scripts/constants.gd`**: increase `FOUNDING_SHAFT_DEPTH` to 14; increase `FOUNDING_CHAMBER_SIZE` to `Vector3i(10, 8, 10)`; add `FOUNDING_SHAFT_WIDTH` (6).

## [0.4.1] - 2026-04-05

### Changed

- **`scripts/world/world_manager.gd`**: **`take_sand_columns(max_columns)`** pops at most **`max_columns`** keys per call.
- **`scripts/world/sand_step.gd`**: cap columns per physics step; set **`sand_idle`** only when the pending column set is empty.
- **`scripts/main_controller.gd`**: queue **dirty** chunk mesh rebuilds with **`max_mesh_rebuilds_per_physics_frame`** (default **8**).
- **`scripts/world/surface_query.gd`**: fast surface **Y** query with full fallback; **`main_controller`**, **`colony_ants`**, **`queen_ant`** use it instead of per-call full-column scans.
- **`scripts/colony_camera.gd`**: orbit / pan / zoom in **`_unhandled_input`**.

## [0.4.0] - 2026-04-05

### Added

- **`scripts/ant_caste.gd`**: define **`Caste`** enum (QUEEN, WORKER, MALE_ALATE, QUEEN_ALATE), **`Task`** enum, and **`WorkerState`** enum for Lasius niger simulation.
- **`scripts/queen_ant.gd`**: queen ant with **state machine** (FLYING_IN → WING_SHEDDING → SEARCHING → DIGGING → CLAUSTRAL → ESTABLISHED → REPRODUCTIVE); opening cinematic sequence with fly-in arc, dust puff particle effect, wing-shed animation, surface search, vertical shaft + founding chamber excavation, entrance sealing, and claustral egg laying with energy drain.
- **`scripts/brood_manager.gd`**: track eggs, larvae, and pupae with development timers (egg → larva → pupa → eclosion); emit **`ant_eclosed`** signal when adults emerge; support trophic egg cannibalism and larva feeding.
- **`scripts/brood_renderer.gd`**: instanced mesh rendering of eggs (spheres), larvae (capsules), and pupae (capsules) inside nest chambers.
- **`scripts/pheromone_field.gd`**: 2D trail pheromone grid on the XZ plane with cell-based deposition, multiplicative evaporation, directional sampling for forager navigation.
- **`scripts/food_source.gd`**: food sources on terrain — aphid colony (sugar, replenishing), dead insect (protein, finite), seed cache (carbohydrate, finite) — with procedural mesh visuals.
- **`scripts/colony_food_store.gd`**: colony-level sugar/protein resource tracker with **`food_critical`** signal.
- **`scripts/nest_builder.gd`**: nest blueprint system with planned chambers (brood, food storage, worker rest) relative to founding chamber; expose dig targets for workers.
- **`scripts/colony_hud.gd`**: HUD overlay showing colony stage, ant-day counter, queen energy status, food store bars, and population/brood counts.
- **`scripts/game_over.gd`**: game over screen with cause of death, days survived, peak workers, and retry button.

### Changed

- **`scripts/constants.gd`**: add game time scale constants (`TICKS_PER_ANT_DAY`, `GAME_SECONDS_PER_ANT_DAY`), brood development durations, queen claustral parameters, pheromone field parameters, food source parameters, worker age thresholds, nest building dimensions, and cinematic timing constants.
- **`scripts/colony_ants.gd`**: replace random-walk system with task-based worker state machine (EMERGING, RESTING, BROOD_CARE, NEST_BUILDING, FORAGING_DEPART, FORAGING_SCOUT, FORAGING_RECRUIT, RETURNING, TROPHALLAXIS, ATTENDING_QUEEN, DEFENDING); add age-based polyethism task assignment; support pheromone trail following and food source collection; spawn workers via `spawn_worker()` from brood eclosion instead of at startup.
- **`scripts/main_controller.gd`**: wire up all colony systems (queen, brood manager, brood renderer, pheromone field, food store, food sources, nest builder, HUD, game over); manage game clock and colony stage transitions; spawn food sources on terrain at game start.

## [0.3.7] - 2026-04-05

### Changed

- **`scripts/world/terrain_gen.gd`**: optional **`on_sand_column_placed`** callback — mark each **sand** **column** once while **filling** chunks (replaces **`bootstrap_sand_columns()`** full-world scan).
- **`scripts/world/world_manager.gd`**: remove **`bootstrap_sand_columns()`**; seed **`_sand_columns`** via **`fill_chunk`** callback.
- **`scripts/main_controller.gd`**: build **initial chunk meshes** over several frames (**`initial_mesh_chunks_per_frame`**, default **10**) instead of one **`_ready`** burst to reduce the **post-loading-bar** stall.
- **`scripts/colony_ant_model.gd`**: refine **exoskeleton** (**per-pixel** shading, **metallic**/**roughness**), **post-petiole**/**petiole**/**thorax**/**head**/**eyes**/**mandibles**, **three-segment** antennae, **femur**/**tibia**/**tarsus** legs.
- **`scripts/colony_ants.gd`**: adjust **`_ANT_LOCAL_Y_MIN`** for the updated leg reach.
- **`README.md`**: document **`main_controller.gd`** initial mesh batching.

## [0.3.6] - 2026-04-05

### Changed

- **`assets/splash/`**: redraw **`anthill_boot.png`** and **`anthill_hero.png`** with a **side-view** ant (**gaster**, **petiole**, **thorax**, **head**, **eye**, **mandible**, **geniculate antennae**, **six** **segmented** legs) on the existing sky / dune / mound background.
- **`tools/generate_splash_assets.py`**: add a **PIL** script to **regenerate** those **PNGs** for future tweaks.
- **`README.md`**: document **`tools/generate_splash_assets.py`**.
- **`game/anthill/.gitignore`**: ignore **`__pycache__/`** and **`*.py[cod]`** under the game tree.

## [0.3.5] - 2026-04-05

### Changed

- **`scripts/colony_ant_model.gd`**: rebuild colony ant mesh with **gaster / petiole / thorax / head**, **lateral eyes**, **small mandibles**, **geniculate antennae** (scape + funiculus), and **six** **two-segment** legs; expose **`MODEL_BODY_LENGTH`** (**1.0** local unit along the body axis).
- **`scripts/colony_ants.gd`**: set default **`ant_visual_scale`** to **3.0** so body length is **~3** voxels; update **`_ANT_LOCAL_Y_MIN`** for the new rig’s **foot** height.

## [0.3.4] - 2026-04-05

### Added

- **`scenes/loading_screen.tscn`** and **`scripts/loading_screen.gd`**: first-run scene that shows **ANTHILL** title, hero art, and a **progress bar** while **`main.tscn`** loads via **`ResourceLoader`** threaded load.
- **`assets/splash/`**: **`anthill_boot.png`** (engine boot splash) and **`anthill_hero.png`** (loading UI art), with **`.import`** metadata.

### Changed

- **`project.godot`**: set **`run/main_scene`** to the loading scene; configure **`boot_splash`** image and background so the engine splash matches Anthill branding instead of the default Godot logo.
- **`README.md`**: document **`loading_screen.tscn`** as the run entry and **`main.tscn`** as the colony scene.

## [0.3.3] - 2026-04-05

### Fixed

- **`scenes/main.tscn`**: add **`ColonyAnts`** node with **`colony_ants.gd`** (the script was referenced but never instantiated, so no ants appeared).

### Changed

- **`scripts/colony_ant_model.gd`**: render colony ants **black** (dark albedo + emission so **unshaded** bodies stay visible on **sand**).
- **`scripts/colony_ants.gd`**: set default **`ant_visual_scale`** to **3.0** (~**24** voxel lengths for the rig, **>10×** one grain).
- **`scenes/main.tscn`**: hint text now says **black** **ants** instead of **brown**.

## [0.3.2] - 2026-04-05

### Changed

- **`scripts/world/world_manager.gd`**: track **`_sand_columns`** (world **XZ** keys) for sand simulation; **`set_block`** marks the column **`sand_idle = false`**; **`bootstrap_sand_columns()`** runs once after terrain gen to seed columns that contain sand in the falling-sand **Y** band; **`take_sand_columns()`** returns pending columns and clears the set for the next tick.
- **`scripts/world/sand_step.gd`**: call **`take_sand_columns()`** and scan only those columns (plus existing **Y** band limits) instead of every **(x,z)** on the map; use **`has_method`/`call`** so **`WorldManager`** **`class_name`** is not required at parse time.

## [0.3.1] - 2026-04-05

### Changed

- **`scripts/constants.gd`**: document **real-world** sand-grain (~**0.06–2** **mm**) and worker-ant (~**3–15** **mm**) **order-of-magnitude** scale vs **voxel** **grain** **fiction**.
- **`scripts/colony_ants.gd`**: apply **`ant_visual_scale`** to colony ants; **place** **ants** so **scaled** **mesh** **feet** sit on **surface** (**not** **below** **terrain**); **default** **scale** **5** so ants stay **visible** at **colony** **zoom** while **body** **length** stays **~8–12×** **one** **voxel** **before** **scale**.

## [0.3.0] - 2026-04-05

### Changed

- **`scripts/world/chunk_data.gd`**: increase **`SIZE_Y`** from **48** to **256** (~11× deeper voxel columns; subsurface extends ~210 layers instead of ~18).
- **`scripts/world/terrain_gen.gd`**: move surface from **y≈18** to **y≈210** (`SURFACE_BASE` constant); widen sand layer to **40** layers above stone; skip air-only Y layers during generation for speed.
- **`scripts/world/sand_step.gd`**: constrain falling-sand scan to the surface band (`SURFACE_BASE ± 50/20`) instead of the full 256-tall column.
- **`scripts/world/mesh_builder.gd`**: restrict mesh face iteration to the surface Y band (`SURFACE_BASE ± 50/20`) so deep enclosed stone produces no geometry.
- **`scripts/colony_ants.gd`**: cap `_surface_block_y` scan ceiling at **240** to avoid scanning the full 256-tall column per ant.
- **`scenes/main.tscn`**: reposition **Floor** collider and **DirectionalLight3D** for the higher surface level.

### Fixed

- **`scripts/colony_camera.gd`**: remove forced world-AABB fit and `is_position_in_frustum` refinement loop that caused **zoom level to jump** when orbiting; set **`size = _size_user`** directly so wheel zoom is always applied.
- **`scripts/colony_camera.gd`**: compute **`pan_scale`** from **`_size_user`** (not the engine-overridden `size`) so middle-drag pan moves predictably.
- **`scripts/colony_camera.gd`**: set **`orbit_radius`** from the horizontal world diagonal and generous **`far`** clip so corners are not depth-clipped at oblique orthographic angles.
- **`scripts/colony_camera.gd`**: place pivot at **surface Y** (`SURFACE_BASE`) so the camera orbits around the visible terrain, not underground.

## [0.2.30] - 2026-04-05

### Fixed

- **`scripts/colony_camera.gd`**: handle **orbit**, **pan**, and **wheel** in **`_input`** (not **`_unhandled_input`**) so **viewport**/**GUI** **handling** does not drop **events**; **debounce** **wheel** **ticks** (**40ms**) **without** **`pressed`** **gating**; **disable** **`physics_object_picking`** on the **viewport** so **picking** does not **consume** **mouse** **events**.
- **`scripts/colony_camera.gd`**: **widen** **ortho** **fit** **margins**, **raise** **far** **slack** (**2048**), **more** **frustum** **refine** **steps** (**28**) **and** **higher** **refine** **cap** (**~3×** **analytic**) for **corner** **clipping** at **oblique** **angles**.

## [0.2.29] - 2026-04-05

### Fixed

- **`scripts/colony_camera.gd`**: remove invalid **`event.echo`** on **`InputEventMouseButton`** (restores **wheel** **zoom**); **only** **process** **wheel** **notches** with **`event.pressed`**.
- **`scripts/colony_camera.gd`**: **clamp** **analytic** **required** **`size`**; **widen** **analytic** **margin**; **raise** **far** **margin** **past** **world** **corners** for **tilted** **views**.
- **`scripts/colony_camera.gd`**: add **capped** **`is_position_in_frustum`** **refinement** (**≤14** **steps**, **≤~2×** **analytic** **fit**, **no** **1e6** **blow-up**) so **ortho** **side** **planes** **match** **engine** **after** **near/far** **sync**.

## [0.2.27] - 2026-04-05

### Fixed

- **`scripts/colony_camera.gd`**: handle **orbit**, **pan**, and **zoom** in **`_unhandled_input`**; use **live** **`Input.is_mouse_button_pressed`** with held-state for **pan**/**orbit**; apply **wheel** **`factor`** and accept **`InputEventPanGesture`** where scroll does not arrive as buttons.
- **`scripts/colony_camera.gd`**: set **`keep_aspect`** to **`KEEP_HEIGHT`**; grow **`size`** until **`is_position_in_frustum`** is true for **world** **AABB** corners (matches engine frustum vs analytic size).
- **`scenes/main.tscn`**: set **Hint** **`mouse_filter`** to **IGNORE** so **UI** does not eat **viewport** **input**.

## [0.2.26] - 2026-04-05

### Fixed

- **`scripts/colony_camera.gd`**: enforce **minimum orthographic `size`** from **world AABB** in **camera space** so **side** frusta do not clip corners when **yawed**; track **wheel** intent separately from **effective** `size`.
- **`scripts/colony_camera.gd`**: pan with **middle** **mouse** using **held** **button** **state** (not **motion** `button_mask`); **invert** **pan** **delta** so **drag** **matches** **ground** **motion**.

## [0.2.25] - 2026-04-05

### Fixed

- **`scripts/colony_camera.gd`**: set **`near`** / **`far`** from **world AABB** corners each orbit/zoom so rotated ortho views do not **far**-clip the ground; raise **`max_zoom`** for panned views near a map edge.

## [0.2.24] - 2026-04-05

### Fixed

- **`scripts/colony_camera.gd`**: raise **`max_zoom`** past **~770** so orthographic **vertical size** can cover **diagonal** ground corners when the camera is **yawed**; set **`near`** / scale **`far`** with **`size`** so depth clipping stays safe when zoomed out.

## [0.2.23] - 2026-04-04

### Fixed

- **`scripts/colony_ant_model.gd`**: add procedural ant builder to version control (referenced by **`colony_ants.gd`** but missing from the tree).
- **`scripts/world/sand_step.gd`**: replace **`WorldManager`** type checks with **`get`/`set`** on **`sand_idle`** so the file parses without **`class_name`** resolution issues.
- **`scripts/main_controller.gd`**, **`scripts/colony_ants.gd`**: create **`SandStep`** / **`ColonyAntModel`** with **`preload(...).new()`** inside **`_ready`** only (avoid **`GDScript.new`** at field init on Godot **4.2**).

### Changed

- **`scripts/colony_camera.gd`**: raise default **`ortho_size`**, **`zoom_step`**, and **`max_zoom`** so the camera can zoom out far enough for the larger world.

## [0.2.22] - 2026-04-04

### Added

- **`scripts/colony_ant_model.gd`**: build **procedural** colony ants — **segmented abdomen**, **petiole**, **thorax**, **head**, **antennae**, and **six** **legs** (primitives + unshaded materials with light **emission** for visibility).

### Changed

- **`scripts/colony_ants.gd`**: spawn **assembled ant** **rig** instead of a **sphere**; **face** **walk** **direction**; **random** **spawn** **yaw**.
- **`scenes/main.tscn`**: hint text no longer says **red spheres**.

## [0.2.21] - 2026-04-04

### Added

- **`scripts/world/world_manager.gd`**: track **`_dirty_chunks`** on **`set_block`** and expose **`get_and_clear_dirty_chunks()`** so mesh rebuilds touch **only** modified chunks (needed for larger worlds).

### Changed

- **`scripts/world/world_manager.gd`**: default **`chunks_x` / `chunks_z`** from **3** to **17** (~**32×** horizontal cell count vs **96×96**, ~**5.5×** longer per side).
- **`scripts/main_controller.gd`**: rebuild **dirty chunks only** after sand moves; keep **full** rebuild in **`_ready`**.
- **`scripts/colony_camera.gd`**: center **pivot** / **`look_at_xz`** from **`WorldManager`** extents; raise default **`orbit_radius`**.
- **`scripts/colony_ants.gd`**: increase default **`ant_count`** to **72** for the larger surface.
- **`scenes/main.tscn`**: enlarge / recenter **floor** collider and **DirectionalLight3D** for the bigger volume.

## [0.2.20] - 2026-04-04

### Fixed

- **`scripts/main_controller.gd`**: construct **`SandStep`** at **variable init** (not only in **`_ready`**) so **`_sand_step`** is never **`Nil`** when **`_physics_process`** runs **`step`**.

## [0.2.19] - 2026-04-04

### Fixed

- **`scripts/world/sand_step.gd`**, **`scripts/main_controller.gd`**: use an **instance** **`step`** on a **`SandStep.new()`** ref — **`GDScript.call_static`** does not exist on **Godot 4.2**’s **`GDScript`** type (runtime error every physics tick).

## [0.2.18] - 2026-04-04

### Fixed

- **`scripts/main_controller.gd`**: invoke sand **`step`** via **`GDScript.call_static`** on a typed **`preload`** — **`SandStep`** **`class_name`** is not always in scope at parse time on some loads, which caused **Identifier "SandStep" not declared**.

## [0.2.17] - 2026-04-04

### Fixed

- **`scripts/main_controller.gd`**: call **`SandStep.step`** via the **`class_name`** (**`SandStep`**) instead of **`preload(...).step`**, which targets the **`Script`** resource and throws **Nonexistent function 'step' in base 'GDScript'** on **Godot 4.2**.

## [0.2.16] - 2026-04-04

### Fixed

- **`scripts/world/sand_step.gd`**, **`scripts/world/world_manager.gd`**, **`scripts/main_controller.gd`**: after falling sand **stops moving**, set **`sand_idle`** and **skip** the **full-world scan** each tick (previously **~432k `get_block` calls per physics frame** at **60 Hz**, pegging **~100%** of one **CPU** core).
- **`project.godot`**: cap **`run/max_fps`** at **60**, enable **vsync**, set **`physics_ticks_per_second`** to **30** to reduce steady-state load.

## [0.2.15] - 2026-04-04

### Added

- **`scripts/colony_camera.gd`**: **orbit** the orthographic camera around a **ground pivot** — **left-drag** adjusts **yaw** and **pitch**; **middle-drag** **pans** the pivot on **XZ**; **wheel** still zooms **`size`**.

### Changed

- **`scripts/colony_ants.gd`**: render ants as **large emissive red spheres** (not brown boxes) so they are distinct from **sand tone** and from **terrain cross-section** edges; expose **`sphere_radius`**.

- **`scenes/main.tscn`**: update **hint** text for **orbit / pan / ants**.

## [0.2.14] - 2026-04-04

### Fixed

- **`scripts/colony_camera.gd`**: assign **`InputEventMouseMotion`** explicitly so **`relative`** is typed (**Godot 4.2** could not infer **`var rel := event.relative`** and failed to load the script, leaving **no camera / no terrain**).

## [0.2.13] - 2026-04-04

### Fixed

- **`scripts/colony_camera.gd`**: pan along **camera-aligned ground axes** (flattened **basis** onto **XZ**) instead of raw **world X/Z**, which felt **wrong and jittery** with a **tilted** orthographic camera; **clamp** large **relative** deltas and **tune** pan gain.

### Changed

- **`scripts/colony_ants.gd`**: make placeholder ants **larger**, **unshaded**, and slightly **emissive** so they stay **visible** on **sand** at colony zoom.

## [0.2.12] - 2026-04-04

### Fixed

- **`scripts/colony_camera.gd`**: stop calling **`gui_get_hovered_control`** on the root viewport (**`Window`** in **4.2.x** has no such method), which was spamming errors and breaking **pan**.
- **`scripts/colony_ants.gd`**: enlarge **placeholder** ant **meshes** to **several world units** so they stay **visible** at colony **ortho** zoom (~**4 px** per voxel); previous **sub-voxel** boxes were **~1 pixel** wide on screen.

## [0.2.11] - 2026-04-04

### Added

- **`scripts/colony_ants.gd`**, **`scenes/main.tscn`**: spawn **wandering brown box “ants”** on the **sand surface** for colony view (separate from the FPS **`ant.tscn`** prototype).

### Fixed

- **`scripts/colony_camera.gd`**: handle **pan** in **`_input`** and allow **left** or **middle** drag; **skip** panning when the mouse is over a **GUI control** so the hint label does not steal drags from the whole window.

### Changed

- **`scenes/main.tscn`**: update the **hint** line to describe **left-drag** and the **placeholder ants**.

## [0.2.10] - 2026-04-04

### Changed

- **`scripts/colony_camera.gd`**: default **`ortho_size`** to **180** and raise **`max_zoom`** so colony view matches roughly **~4 screen pixels per voxel height** at **720p** (Godot orthographic **`size`** is vertical world units; **pixels ≈ viewport_height / size**). Increase **`zoom_step`** slightly for the wider zoom range.
- **`scripts/constants.gd`**: document the **ortho `size` → pixels-per-grain** relationship.

## [0.2.9] - 2026-04-04

### Fixed

- **`scripts/world/world_manager.gd`**, **`scripts/main_controller.gd`**: rebuild chunk **meshes only when `set_block` runs** (sand moved) instead of every **physics** frame, avoiding redundant uploads and reducing **flicker** / **strip** artifacts on some **Mesa** setups.

## [0.2.8] - 2026-04-04

### Fixed

- **`scripts/main_controller.gd`**, **`scenes/main.tscn`**, **`scripts/colony_camera.gd`**: show voxel terrain as **lit** **`StandardMaterial3D`** with **vertex-color albedo**, **`WorldEnvironment`** ambient fill, and a **slightly tilted** orthographic camera so height steps read as **3D** instead of a **uniform flat** sand-colored field (common when the view is **straight down** and **unshaded**).

### Removed

- **`shaders/terrain_unshaded.gdshader`**: drop the **unshaded** terrain shader now that the project runs on **GL Compatibility** where **`StandardMaterial3D`** + **vertex colors** behave reliably.

## [0.2.7] - 2026-04-04

### Fixed

- **`scripts/main_controller.gd`**, **`shaders/terrain_unshaded.gdshader`**: draw voxel terrain with a minimal **unshaded spatial shader** that reads **vertex colors** (avoids a **blank / white / non-visible** terrain on **Vulkan llvmpipe** where **`StandardMaterial3D`** + vertex color was unreliable).
- **`project.godot`**: set **`renderer/rendering_method`** to **`gl_compatibility`** and **`config/features`** to **GL Compatibility** so the game prefers **OpenGL** on hosts without stable **Vulkan** software rasterizers.

### Changed

- **`project.godot`**: omit **window stretch** and fixed **viewport size** overrides (they were added while chasing apparent **letterboxing**; that came from an external **screenshot overlay**, not the game).

## [0.2.6] - 2026-04-04

### Fixed

- **`scenes/main.tscn`**: add **`ColonyCamera`** **`Camera3D`** node with **`colony_camera.gd`** (script was loaded but unattached, so no active camera ran and the 3D world did not display correctly).
- **`scripts/main_controller.gd`**: set terrain **`StandardMaterial3D`** to **`SHADING_MODE_UNSHADED`** so vertex colors stay visible without relying on directional lighting (helps software **`llvmpipe`** and steep light angles).

### Changed

- **`scenes/main.tscn`**: disable **DirectionalLight3D** shadows to avoid rasterizer edge cases on software Vulkan.

## [0.2.5] - 2026-04-05

### Fixed

- **`scripts/world/*.gd`**, **`main_controller.gd`**, **`entities/ant.gd`**: use **`preload()`** for **`constants.gd`** and **`chunk_data.gd`** instead of relying on global **`class_name`** resolution (fixes parse/analyzer errors for **`GameConstants`**, **`VoxelChunk`**, and **`:=` inference** on some Godot 4.2 builds).
- **`terrain_gen.gd`**, **`mesh_builder.gd`**: use **`range()`** for **`for`** loops over chunk sizes; add explicit **`int`** types where needed.

## [0.2.4] - 2026-04-05

### Fixed

- **`scripts/world/world_manager.gd`**: replace **`//`** integer division with **`int(floor(float(x) / float(y)))`** so Godot 4.2 parses the file (avoids `/` parse errors and restores **`class_name`** registration).

### Changed

- **`scenes/main.tscn`**, **`scripts/colony_camera.gd`**: **orthographic top-down** colony view (middle-drag pan, wheel zoom); remove spawning the old first-person **ant** player from **`main_controller.gd`**.
- **`project.godot`**, UI hint label: describe **colony management** intent, not direct ant control.
- **`game/anthill/README.md`**: document camera vs future systems.

### Updated

- **`scripts/entities/ant.gd`**: note script is for future **AI** ants only.

## [0.2.3] - 2026-04-05

### Added

- **`scripts/install-godot4.sh`**: download and install official **Godot 4.x** Linux x86_64 to **`$PREFIX/lib/anthill/godot4`** with **`$PREFIX/bin/godot4`** symlink (`GODOT_VERSION` overrides default **4.2.2**).

### Updated

- **`README.md`**: document **`install-godot4.sh`** before **`install-anthill.sh`** when Godot is missing.

## [0.2.2] - 2026-04-04

### Added

- **`scripts/install-anthill.sh`**: warn when **`~/.local/bin/anthill`** is an ELF that could shadow **`/usr/local/bin/anthill`** on PATH.

### Updated

- **`README.md`**: explain PATH conflict with an older **`~/.local/bin/anthill`** Luanti build.

## [0.2.1] - 2026-04-04

### Added

- **`scripts/install-anthill.sh`**: copy **`game/anthill`** to **`$PREFIX/share/anthill/game/anthill`** and install **`$PREFIX/bin/anthill`** launcher (invokes **`godot4`** / **`godot`**, common **`/usr/bin`** and **`/usr/local/bin`** paths, or **`GODOT_BIN`**, with `--path`).
- **`scripts/anthill-launcher.sh.in`**: template for the installed launcher.

### Updated

- **`README.md`**: document system install and `PREFIX`.

## [0.2.0] - 2026-04-04

### Removed

- **Luanti / Minetest engine workflow**: delete **`anthill_game/`** (subgame), **`engine/`** (build scripts, patch, branding, CMake presets), **`luanti_menu_patch/`**, **`scripts/install-menu-patch.sh`**, and **`docs/building-from-source.md`**.

### Updated

- **Root `README.md`**: Godot-only project overview; drop engine/subgame instructions.
- **`game/anthill/README.md`**: remove references to the old subgame tree.
- **`.gitignore`**: remove paths that only applied to the Luanti build.

## [0.1.0] - 2026-04-04

### Added

- **`game/anthill/`**: standalone **Godot 4.2+** prototype — chunked **voxel** world (32×48×32 per chunk, 3×3 chunks), **2D noise** terrain (sand / stone / air), **Minecraft-style falling sand** each physics frame, **greedy-style** exposed-face meshing with vertex colors, **ant** CharacterBody3D (**WASD**, mouse look, **E** grab one sand block, **Q** place), floor **StaticBody3D** placeholder (voxel mesh collision not yet implemented).
- **`game/anthill/README.md`**: document running from Godot or `--path`, layout, prototype limits.
- **Root `README.md`**: describe the Godot game as primary; move Luanti subgame under a collapsible **legacy** section.

## [2.1.12] - 2026-04-04

### Added

- `anthill_game/mods/anthill/textures/blank.png`: **1×1** base texture for **`blank.png^[colorize:...`** on nodes, the spectator cube, and ant entities (missing file previously showed engine “no texture” / checkerboard placeholders).

## [2.1.11] - 2026-04-04

### Added

- `anthill_game/settingtypes.txt`: **`anthill_observer_clearance`** (default **176**) so the spectator stays within the stock client **viewing_range** mapblock radius; document that **user** `minetest.conf` overrides game-layer **`viewing_range`**.

### Changed

- `anthill_game/mods/anthill/player_spawn.lua`: apply **`anthill_observer_clearance`** instead of a fixed **520**-node offset so terrain mapblocks load when **`~/.minetest/minetest.conf`** keeps **`viewing_range`** at the engine default.

### Updated

- `README.md`: describe default vs high clearance and config override order.

## [2.1.10] - 2026-04-04

### Added

- `anthill_game/minetest.conf`: set **`viewing_range`**, **`max_block_send_distance`**, and **`active_object_send_range_blocks`** in the engine **game settings layer** so **clients** negotiate a large enough mapblock radius (server Lua alone cannot change remote clients’ `viewing_range`).

### Changed

- `anthill_game/mods/anthill/init.lua`: clarify comments about game **`minetest.conf`** vs server Lua settings.
- `anthill_game/mods/anthill/player_spawn.lua`: raise sky **`fog_distance`** to **6000** so client **`wanted_range`** is not capped below **`viewing_range`** by fog.

### Updated

- `README.md`: document client **`viewing_range`**, game vs user config override order, and `minetest.conf` path table entry.

## [2.1.9] - 2026-04-04

### Changed

- `anthill_game/mods/anthill/player_spawn.lua`: remove **`enforce_spectator_pitch`** (no pitch clamping); set initial **`set_look_vertical(0)`** so the spectator can look up at clouds and down at the ground. Ground visibility remains from **`viewing_range`** in `init.lua`.

## [2.1.8] - 2026-04-04

### Changed

- `anthill_game/mods/anthill/init.lua`: set **`viewing_range` to 1200** at mod load so the client negotiates a large enough **mapblock send radius** with the server (default ~190 nodes was ~12 blocks — terrain ~33+ blocks below the camera never loaded).
- `anthill_game/mods/anthill/player_spawn.lua`: steeper default **`set_look_vertical`**, lighter fog, **`enforce_spectator_pitch`** when the view drifts to the horizon, and drop redundant late **`viewing_range`** set from `apply_observer_visibility`.

### Updated

- `README.md`: explain the viewing-range / mapblock send interaction.

## [2.1.7] - 2026-04-04

### Changed

- `anthill_game/mods/anthill/player_spawn.lua`: raise the **cloud layer** (`set_clouds` height ~1180) above the spectator camera; set **sky fog** (`fog_distance` / `fog_start`) and client **`viewing_range`** so ground and ants render far below.
- `anthill_game/mods/anthill/init.lua`: increase **`max_block_send_distance`** and **`active_object_send_range_blocks`** so the server sends mapblocks and entities within the long vertical view.

### Updated

- `README.md`: note clouds/render tuning and optional world restart for send distance.

## [2.1.6] - 2026-04-04

### Changed

- `anthill_game/mods/anthill/ant_entity.lua`: restore **~80-node** ant scale (large vs grains).
- `anthill_game/mods/anthill/player_spawn.lua`: spectator-style camera — **minimum ~520 nodes** above local terrain (so many ants fit in frame), **`zoom_fov = 0`** (no engine zoom), **fly** + **noclip**, slow pan speed; **globalstep** enforces minimum altitude; steep downward look and default FOV ~72.

### Updated

- `README.md` and `anthill_game/game.conf`: describe large ants vs grains and spectator rules.

## [2.1.5] - 2026-04-04

### Changed

- `anthill_game/mods/anthill/ant_entity.lua`: shrink ant visual/collision scale so ants read as small from the default camera; tune speed, separation, and spawn drop height.
- `anthill_game/mods/anthill/player_spawn.lua`: spawn first join high above the nest (~260 nodes over surface), point view downward, grant **fly**, optional wider FOV; add **`/observer_reset`**; remove duplicate `on_newplayer` spawn in favor of player-meta-gated setup.

### Updated

- `README.md` and `anthill_game/game.conf`: describe observer scale and `/observer_reset`.

## [2.1.4] - 2026-04-04

### Added

- `engine/branding/`: `menu_header.png` and `logo.png` text wordmarks; `engine/branding/README.md` documents sizes and replacement.

### Changed

- `engine/patches/0001-anthill-engine.patch`: disable default **`update_information_url`**; reword main-menu strings that referred to Luanti; About tab homepage button points at the Anthill GitHub repo; **`settingtypes.txt`** default for the update URL is empty.
- `engine/build.sh`: install branding textures into **`$PREFIX/share/luanti/textures/base/pack/`** after CMake install.
- `engine/README.md`: describe branding and update-check behavior.
- `docs/building-from-source.md`: explain the upstream “new version” dialog vs Anthill releases.
- `luanti_menu_patch/dlg_create_world.lua`: align comment with the engine patch wording.

## [2.1.3] - 2026-04-04

### Added

- `docs/building-from-source.md`: developer-oriented build steps, Debian-style dependencies, troubleshooting, and how CMake presets relate to the Luanti tree.
- `engine/CMakeUserPresets-anthill.json`: **`anthill-engine`** configure/build preset (inherits Luanti’s **`RelWithDebInfo`**), intended to be copied into `third_party/luanti-src/CMakeUserPresets.json`.

### Changed

- Remove root `CMakePresets.json` (invalid fields for CMake 3.31; presets must be loaded from the Luanti source directory).
- `engine/build.sh`: copy `CMakeUserPresets-anthill.json` into the clone; run `cmake --preset` / `cmake --build` from `third_party/luanti-src`; detect preset availability with `cmake --list-presets`; install with `cmake --install` on `engine/out/build`.
- `README.md` and `engine/README.md`: document the user-preset path and link **`docs/building-from-source.md`**.

## [2.1.2] - 2026-04-04

### Added

- `docs/cursor-agent-shell.md`: troubleshoot Cursor agent shell (empty output / no workspace writes) and pointer to Agent + Sandbox settings.
- `.cursor/rules/shell-execution.mdc`: remind agents to fall back to file tools when shell is unreliable.

### Changed

- `README.md`: link to Cursor agent shell troubleshooting.

## [2.1.1] - 2026-04-04

### Added

- Root `CMakePresets.json`: preset **`anthill-engine`** (configure / build / install) for the patched Luanti tree under `third_party/luanti-src`.

### Changed

- `engine/build.sh`: use `cmake --preset anthill-engine` when available; export `ANTHILL_INSTALL_PREFIX` for the preset; symlink **`anthill_game`** into `$PREFIX/share/luanti/games/`; append **`~/.local/bin`** to **`~/.bashrc`** once when missing from `PATH`.
- `engine/README.md`: document CMake preset workflow and manual `cmake --preset` commands.

## [2.1.0] - 2026-04-04

### Added

- `engine/patches/0001-anthill-engine.patch`: Luanti 5.10.0 patch setting display name **Anthill**, client binary **`anthill`**, server **`anthillserver`**, and bundled create-world menu Lua.
- `engine/build.sh` and `engine/README.md`: clone upstream Luanti, apply patch, CMake install to `$HOME/.local` (override `ANTHILL_INSTALL_PREFIX`).
- `engine/NOTICE`: LGPL attribution for the patch.

### Changed

- `README.md`: document building and running **`anthill`** vs system **`luanti`**; games path under `~/.local/share/luanti/games/` for the custom install.
- `.gitignore`: ignore `third_party/luanti-src/` and `engine/out/`.

## [2.0.2] - 2026-04-04

### Added

- `luanti_menu_patch/dlg_create_world.lua` and `luanti_menu_patch/README.md`: optional Luanti builtin patch to hide the mapgen dropdown when only one mapgen is allowed and to fix create-world layout when the seed field is hidden.
- `scripts/install-menu-patch.sh`: copy the patched dialog into the system Luanti install.

### Changed

- `anthill_game/game.conf`: add `mg_flags` and `seed` to `disallowed_mapgen_settings` so the stock create-world dialog hides generic caves/dungeons/decorations and the seed field without a menu patch.
- `anthill_game/menu/icon.png`: regenerate with a visible “Anthill” label for the bottom game bar.
- `README.md`: document the menu patch, icon, and removing `luanti-game-minetest` for an Anthill-only game list.

## [2.0.1] - 2026-04-04

### Added

- `anthill_game/menu/background.png` and `menu/icon.png` (desert-toned placeholders) for the engine main menu.

### Changed

- `anthill_game/game.conf`: set `allowed_mapgens` / `default_mapgen` to flat only; `disabled_settings` for creative, damage, and host-server; `disallowed_mapgen_settings` for flat mapgen fields that do not apply to Lua dunes.
- `README.md`: describe menu behavior and engine limitations.

## [2.0.0] - 2026-04-04

### Added

- `anthill_game/` Luanti subgame (engine only): `anthill:sand`, `anthill:stone`, `anthill:nest`; mapgen aliases for flat mapgen; Perlin dune terrain and nest at the origin.
- Coarse-grid **trail** and **home** pheromone fields with decay and nest seeding.
- **`anthill:ant`** entities (~80-node visual cube): wander steering, trail gradient, home vector, separation, ground raycast, trail deposit; initial colony once per world via mod storage; **`/spawn_ants`** and **`/ant_count`**.
- Observer-style **player** spawn high above the nest and simple cube appearance.

### Removed

- `minetest_mods/` mods that depended on **Minetest Game** (`default` nodes).

### Changed

- Document Luanti-only workflow in `README.md` (symlink `anthill_game`, no `minetest_game` requirement).

## [1.0.0] - 2026-04-04

### Added

- `minetest_mods/anthill_desert`: flat mapgen settings and `on_generated` fill using `default:desert_sand` and `default:desert_stone` with air above a fixed surface (no trees or decorations).
- `minetest_mods/anthill_ant`: `anthill_ant:giant` cube entity at ~100-node visual scale and `/spawn_ant` chat command.
- Root `README.md` documenting Minetest install, mod paths, new-world flow, and scale intent.

### Removed

- Expo / TypeScript / React Three Fiber web app (`App.tsx`, `src/`, `package.json`, `babel.config.js`, `public/`, `app.json`, `index.ts`, `tsconfig.json`, and bundled dependencies).

## [0.5.0] - 2026-04-04

### Added

- Discrete sand model: `GrainWorld` with per-column stacks of grain ids, bilinear surface height, falling and sliding substeps, and carried-grain attachment to ants.
- `src/simulation/grains/` module (constants, types, `GrainWorld`).
- `ColonySimulation` replacing the heightfield world: ants wander, stochastically pick the **top** grain from a column (revealing the grain below), carry it, and drop near the nest with ballistic release.

### Changed

- Remove continuous terrain heightfield, pheromone fields, spoil mounds, tunnel instancing, and food-patch cylinders from the default scene.
- Render the bed as up to ~62k instanced grain spheres at `GRAIN_RADIUS` scale; nest remains a simple disc.
- Ants scale to ~26× grain radius (low, wide silhouette) on the new coordinate system.

### Removed

- `terrain.ts`, `pheromones.ts`, legacy `types.ts` / `constants.ts`, `terrainMesh.ts`, `tunnelGeometry.ts`, `visualConstants.ts` (superseded by the grain model).

## [0.4.0] - 2026-04-04

### Added

- `antGeometry.ts`: merged low-profile worker-ant mesh (gaster, thorax, head, petiole) with feet on Y=0.
- `tunnelGeometry.ts`: horizontal cylindrical tunnel bores alternating E–W / N–S for gallery-like segments.
- `visualConstants.ts`: fixed grain radius and surface bias independent of grid cell size.

### Changed

- Shrink loose sand spheres to realistic grain size; vary scale and rotation slightly.
- Replace tall black capsule ants with segmented brown silhouette; align heading with `theta` on +X body axis.
- Replace tunnel boxes with darker bored cylinders; tune depth offset and lighting (wider FOV, softer sun, larger shadow map).
- Lower nest disc profile; reduce `ANT_FOOT_CLEARANCE` for ground contact.

## [0.3.0] - 2026-04-04

### Added

- `depositSpoilMound` to raise terrain where excavated sand is dumped: primary mound outward from the nest, a smaller side cast, and a shallow trail between pit and mound.
- Constants for spoil offset, mound radius, and volume-to-height scaling.

### Changed

- Pass removed volume from `carveCrater` into spoil deposition so dig volume shapes mound height.
- Spawn loose grains on the spoil heap center so spheres sit on accumulated topography.

## [0.2.0] - 2026-04-04

### Added

- Procedural sand heightfield (`terrain.ts`) with dunes, radial bias, and bilinear sampling.
- `terrainMesh.ts` helpers to build and update shaded sand mesh geometry.
- Loose sand grains array: excavated grains render as instanced spheres with a live count in the HUD.
- Correlated random walk (`omega` angular state) for ant steering; reflective bounds instead of silent clamping.

### Changed

- Enlarge simulation grid (`GRID_SIZE` 240) and tune cell size for a wider play area.
- Retune pheromone emission and steering so foragers wander pseudo-randomly; carriers retain a weak nest bias.
- Replace flat green plane with displaced sand-colored terrain (topography, shadows, flat shading).
- Model digging as `carveCrater` on the heightfield plus tunnel growth; terrain mesh updates when carving changes.
- Position nest, food markers, ants, and tunnels on local surface height.

## [0.1.0] - 2026-04-04

### Added

- Expo (TypeScript) app with web support and fast refresh via Metro.
- `babel.config.js` using `babel-preset-expo` with `unstable_transformImportMeta` so Metro replaces `import.meta` in bundled dependencies on web.
- `public/index.html` with full-viewport `#root` layout for react-native-web.
- `ErrorBoundary` component to surface runtime render errors in the UI.
- Three.js / React Three Fiber scene: ground plane, nest mound, food patches, instanced ant capsules, instanced tunnel blocks.
- Orbit camera with surface vs underground (x-ray ground) view toggle.
- Grid-based dual pheromone fields (nest / home gradient and food-recruitment trail) with diffusion and evaporation.
- Ant agent model with bilateral sampling (left / center / right) and role switching (forage vs carry food to nest).
- Stochastic tunnel growth near the nest and visualization of tunnel cells in 3D below the surface.

### Changed

- Adjust React Native flex styles on the root and canvas stack (`minHeight: 0`, width stretch) so the Three.js canvas measures and draws in the browser.
