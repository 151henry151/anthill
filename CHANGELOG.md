# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
