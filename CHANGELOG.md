# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
