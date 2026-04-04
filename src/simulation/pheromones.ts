import {
  GRID_SIZE,
  PHEROMONE_DIFFUSION,
  PHEROMONE_EVAPORATION,
} from './constants';

function idx(x: number, z: number): number {
  return z * GRID_SIZE + x;
}

/**
 * Double-buffered scalar field on the ground grid.
 * Update: diffuse toward neighborhood average, then evaporate.
 * Matches common stigmergy ABM treatments (lattice diffusion + decay).
 */
export class PheromoneField {
  readonly a: Float32Array;
  readonly b: Float32Array;
  private readFromA = true;

  constructor() {
    const n = GRID_SIZE * GRID_SIZE;
    this.a = new Float32Array(n);
    this.b = new Float32Array(n);
  }

  get read(): Float32Array {
    return this.readFromA ? this.a : this.b;
  }

  get write(): Float32Array {
    return this.readFromA ? this.b : this.a;
  }

  swap(): void {
    this.readFromA = !this.readFromA;
  }

  clear(): void {
    this.a.fill(0);
    this.b.fill(0);
  }

  step(): void {
    const src = this.read;
    const dst = this.write;
    const w = GRID_SIZE;
    const h = GRID_SIZE;
    const d = PHEROMONE_DIFFUSION;
    const e = PHEROMONE_EVAPORATION;
    const retain = 1 - e;

    for (let z = 0; z < h; z++) {
      for (let x = 0; x < w; x++) {
        const i = idx(x, z);
        let sum = src[i];
        let count = 1;
        if (x > 0) {
          sum += src[i - 1];
          count++;
        }
        if (x < w - 1) {
          sum += src[i + 1];
          count++;
        }
        if (z > 0) {
          sum += src[i - w];
          count++;
        }
        if (z < h - 1) {
          sum += src[i + w];
          count++;
        }
        const avg = sum / count;
        dst[i] = retain * ((1 - d) * src[i] + d * avg);
      }
    }
    this.swap();
  }

  addDeposit(ix: number, iz: number, amount: number, radius: number): void {
    const buf = this.read;
    const r = Math.ceil(radius);
    const x0 = Math.max(0, ix - r);
    const x1 = Math.min(GRID_SIZE - 1, ix + r);
    const z0 = Math.max(0, iz - r);
    const z1 = Math.min(GRID_SIZE - 1, iz + r);
    const r2 = radius * radius;
    for (let z = z0; z <= z1; z++) {
      for (let x = x0; x <= x1; x++) {
        const dx = x - ix;
        const dz = z - iz;
        if (dx * dx + dz * dz <= r2) {
          const i = idx(x, z);
          buf[i] += amount;
        }
      }
    }
  }

  /** Bilinear sample at fractional grid coordinates. */
  sampleAt(x: number, z: number): number {
    const field = this.read;
    const xf = Math.min(GRID_SIZE - 1.001, Math.max(0, x));
    const zf = Math.min(GRID_SIZE - 1.001, Math.max(0, z));
    const x0 = Math.floor(xf);
    const z0 = Math.floor(zf);
    const x1 = Math.min(x0 + 1, GRID_SIZE - 1);
    const z1 = Math.min(z0 + 1, GRID_SIZE - 1);
    const tx = xf - x0;
    const tz = zf - z0;
    const v00 = field[idx(x0, z0)];
    const v10 = field[idx(x1, z0)];
    const v01 = field[idx(x0, z1)];
    const v11 = field[idx(x1, z1)];
    const a = v00 * (1 - tx) + v10 * tx;
    const b = v01 * (1 - tx) + v11 * tx;
    return a * (1 - tz) + b * tz;
  }
}
