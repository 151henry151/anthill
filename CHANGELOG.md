# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

## [Unreleased]
