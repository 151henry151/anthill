import { GRID_SIZE } from './constants';

function fract(x: number): number {
  return x - Math.floor(x);
}

function hash2(ix: number, iz: number): number {
  const n = Math.sin(ix * 127.1 + iz * 311.7) * 43758.5453123;
  return fract(n);
}

function smooth(ix: number, iz: number): number {
  const x0 = Math.floor(ix);
  const z0 = Math.floor(iz);
  const fx = fract(ix);
  const fz = fract(iz);
  const u = fx * fx * (3 - 2 * fx);
  const w = fz * fz * (3 - 2 * fz);
  const a = hash2(x0, z0);
  const b = hash2(x0 + 1, z0);
  const c = hash2(x0, z0 + 1);
  const d = hash2(x0 + 1, z0 + 1);
  const ab = a + (b - a) * u;
  const cd = c + (d - c) * u;
  return ab + (cd - ab) * w;
}

function fbm(ix: number, iz: number): number {
  let v = 0;
  let a = 0.55;
  let f = 0.012;
  for (let o = 0; o < 5; o++) {
    v += a * smooth(ix * f, iz * f);
    a *= 0.48;
    f *= 2.05;
  }
  return v;
}

/**
 * Initialize dune-like surface height (simulation units). Higher = more sand above baseline.
 */
export function createTerrainHeights(): Float32Array {
  const n = GRID_SIZE * GRID_SIZE;
  const h = new Float32Array(n);
  const cx = GRID_SIZE * 0.5;
  const cz = GRID_SIZE * 0.5;
  const maxR = Math.hypot(cx, cz);
  for (let iz = 0; iz < GRID_SIZE; iz++) {
    for (let ix = 0; ix < GRID_SIZE; ix++) {
      const dx = (ix - cx) / maxR;
      const dz = (iz - cz) / maxR;
      const radial = 1.0 - Math.min(1, Math.hypot(dx, dz) * 1.15);
      const dunes = fbm(ix * 0.9, iz * 0.9) * 1.4;
      const ripples = Math.sin(ix * 0.21 + iz * 0.13) * 0.08 + Math.cos(ix * 0.09 - iz * 0.11) * 0.06;
      const v = 0.22 * radial + dunes * 0.55 + ripples;
      h[ix + iz * GRID_SIZE] = Math.max(0.04, v);
    }
  }
  return h;
}

export function sampleHeightBilinear(heights: Float32Array, x: number, z: number): number {
  const xf = Math.min(GRID_SIZE - 1.001, Math.max(0, x));
  const zf = Math.min(GRID_SIZE - 1.001, Math.max(0, z));
  const x0 = Math.floor(xf);
  const z0 = Math.floor(zf);
  const x1 = Math.min(x0 + 1, GRID_SIZE - 1);
  const z1 = Math.min(z0 + 1, GRID_SIZE - 1);
  const tx = xf - x0;
  const tz = zf - z0;
  const idx = (ix: number, iz: number) => ix + iz * GRID_SIZE;
  const v00 = heights[idx(x0, z0)];
  const v10 = heights[idx(x1, z0)];
  const v01 = heights[idx(x0, z1)];
  const v11 = heights[idx(x1, z1)];
  const a = v00 * (1 - tx) + v10 * tx;
  const b = v01 * (1 - tx) + v11 * tx;
  return a * (1 - tz) + b * tz;
}

/**
 * Excavate sand at and around a cell; returns approximate volume removed for grain spawning.
 */
export function carveCrater(
  heights: Float32Array,
  ix: number,
  iz: number,
  depth: number,
  radius: number
): number {
  const r = Math.ceil(radius);
  let removed = 0;
  for (let dz = -r; dz <= r; dz++) {
    for (let dx = -r; dx <= r; dx++) {
      const nx = ix + dx;
      const nz = iz + dz;
      if (nx < 0 || nx >= GRID_SIZE || nz < 0 || nz >= GRID_SIZE) continue;
      const d = Math.hypot(dx, dz);
      if (d > radius) continue;
      const falloff = 1 - d / (radius + 0.001);
      const i = nx + nz * GRID_SIZE;
      const take = depth * falloff * falloff;
      const prev = heights[i];
      const next = Math.max(0.02, prev - take);
      removed += prev - next;
      heights[i] = next;
    }
  }
  return removed;
}
