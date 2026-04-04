# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
