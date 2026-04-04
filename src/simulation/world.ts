import {
  ANT_COUNT,
  ANT_SPEED,
  CARRIER_HOME_GAIN,
  DIG_CARVE_DEPTH,
  DIG_CARVE_RADIUS,
  DIG_PROBABILITY,
  EXPLORATION_DEPOSIT,
  FOOD_SENSITIVITY,
  FOOD_TRAIL_DEPOSIT,
  GRID_SIZE,
  GRAINS_PER_DIG,
  MAX_LOOSE_GRAINS,
  MAX_TUNNEL_DEPTH,
  NEST_EMISSION,
  NEST_IX,
  NEST_IZ,
  NEST_RADIUS,
  PHEROMONE_TURN_GAIN,
  SENSOR_DISTANCE,
  SENSOR_SPREAD,
  SIM_STEP,
  WANDER_ANG_ACCEL,
  WANDER_ANG_DAMP,
  WANDER_MAX_OMEGA,
} from './constants';
import { PheromoneField } from './pheromones';
import { carveCrater, createTerrainHeights, sampleHeightBilinear } from './terrain';
import type { Ant, FoodSource, LooseGrain } from './types';

function nestDist(x: number, z: number): number {
  const dx = x - NEST_IX;
  const dz = z - NEST_IZ;
  return Math.sqrt(dx * dx + dz * dz);
}

function tunnelKey(ix: number, iz: number, depth: number): string {
  return `${ix},${iz},${depth}`;
}

function wrapAngle(a: number): number {
  while (a > Math.PI) a -= Math.PI * 2;
  while (a < -Math.PI) a += Math.PI * 2;
  return a;
}

export interface WorldSnapshot {
  ants: Ant[];
  foodSources: FoodSource[];
  tunnelKeys: string[];
  tick: number;
  foodDelivered: number;
  looseGrainCount: number;
  terrainVersion: number;
}

export class World {
  readonly home = new PheromoneField();
  readonly foodTrail = new PheromoneField();
  readonly terrainHeight: Float32Array;
  terrainVersion = 0;
  ants: Ant[] = [];
  foodSources: FoodSource[] = [];
  readonly tunnels = new Set<string>();
  /** Excavated sand grains (surface height samples + small offset for drawing). */
  grains: LooseGrain[] = [];
  tick = 0;
  foodDelivered = 0;

  constructor() {
    this.terrainHeight = createTerrainHeights();
    this.seedFood();
    this.seedTunnels();
    this.seedAnts();
  }

  private seedFood(): void {
    const margin = Math.floor(GRID_SIZE * 0.12);
    const r = 6;
    this.foodSources = [
      { ix: margin, iz: margin, radius: r, remaining: 8000 },
      { ix: GRID_SIZE - margin, iz: margin, radius: r, remaining: 8000 },
      { ix: GRID_SIZE - margin, iz: GRID_SIZE - margin, radius: r, remaining: 8000 },
      { ix: margin, iz: GRID_SIZE - margin, radius: r, remaining: 8000 },
    ];
  }

  private seedTunnels(): void {
    this.tunnels.add(tunnelKey(Math.floor(NEST_IX), Math.floor(NEST_IZ), 1));
    for (let k = 0; k < 18; k++) {
      const keys = [...this.tunnels];
      const pick = keys[Math.floor(Math.random() * keys.length)];
      const [sx, sz, sd] = pick.split(',').map(Number);
      const opts: [number, number, number][] = [
        [sx + 1, sz, sd],
        [sx - 1, sz, sd],
        [sx, sz + 1, sd],
        [sx, sz - 1, sd],
        [sx, sz, Math.min(MAX_TUNNEL_DEPTH, sd + 1)],
      ];
      const c = opts[Math.floor(Math.random() * opts.length)];
      if (
        c[0] >= 1 &&
        c[0] < GRID_SIZE - 1 &&
        c[1] >= 1 &&
        c[1] < GRID_SIZE - 1 &&
        c[2] >= 1 &&
        c[2] <= MAX_TUNNEL_DEPTH
      ) {
        this.tunnels.add(tunnelKey(c[0], c[1], c[2]));
      }
    }
  }

  private seedAnts(): void {
    this.ants = [];
    for (let i = 0; i < ANT_COUNT; i++) {
      const a = Math.random() * Math.PI * 2;
      const r = Math.random() * (NEST_RADIUS - 0.5);
      this.ants.push({
        x: NEST_IX + Math.cos(a) * r,
        z: NEST_IZ + Math.sin(a) * r,
        theta: Math.random() * Math.PI * 2,
        omega: (Math.random() - 0.5) * 0.8,
        role: 'forage',
      });
    }
  }

  /** Abstract surface height at fractional grid coords (same units as terrainHeight). */
  heightAt(x: number, z: number): number {
    return sampleHeightBilinear(this.terrainHeight, x, z);
  }

  private emitNest(): void {
    this.home.addDeposit(NEST_IX, NEST_IZ, NEST_EMISSION, NEST_RADIUS + 0.8);
  }

  private sampleSensors(ant: Ant, field: PheromoneField): [number, number, number] {
    const d = SENSOR_DISTANCE;
    const s = SENSOR_SPREAD;
    const angles = [ant.theta - s, ant.theta, ant.theta + s];
    return angles.map((ang) => {
      const x = ant.x + Math.cos(ang) * d;
      const z = ant.z + Math.sin(ang) * d;
      return field.sampleAt(x, z);
    }) as [number, number, number];
  }

  private steerTowardGradient(
    left: number,
    center: number,
    right: number,
    gain: number,
    noise: number
  ): number {
    const g = PHEROMONE_TURN_GAIN * gain * (left - right);
    const centerBias = (center - (left + right) * 0.5) * 0.08 * gain;
    return g + centerBias + noise;
  }

  private tryHarvest(ant: Ant): boolean {
    for (const f of this.foodSources) {
      const dx = ant.x - f.ix;
      const dz = ant.z - f.iz;
      if (dx * dx + dz * dz <= f.radius * f.radius && f.remaining > 0) {
        f.remaining -= 1;
        return true;
      }
    }
    return false;
  }

  private atNest(ant: Ant): boolean {
    return nestDist(ant.x, ant.z) < NEST_RADIUS * 0.85;
  }

  private reflectAtBounds(ant: Ant): void {
    const m = 2.2;
    const max = GRID_SIZE - m;
    const jitter = () => (Math.random() - 0.5) * 0.9;

    if (ant.x < m) {
      ant.x = m;
      ant.theta = Math.PI - ant.theta + jitter();
      ant.omega *= -0.5;
    } else if (ant.x > max) {
      ant.x = max;
      ant.theta = Math.PI - ant.theta + jitter();
      ant.omega *= -0.5;
    }
    if (ant.z < m) {
      ant.z = m;
      ant.theta = -ant.theta + jitter();
      ant.omega *= -0.5;
    } else if (ant.z > max) {
      ant.z = max;
      ant.theta = -ant.theta + jitter();
      ant.omega *= -0.5;
    }
    ant.theta = wrapAngle(ant.theta);
  }

  private maybeDig(ant: Ant): void {
    if (ant.role !== 'forage') return;
    if (nestDist(ant.x, ant.z) > NEST_RADIUS + 8) return;
    if (Math.random() > DIG_PROBABILITY) return;

    const ix = Math.floor(ant.x);
    const iz = Math.floor(ant.z);
    carveCrater(this.terrainHeight, ix, iz, DIG_CARVE_DEPTH, DIG_CARVE_RADIUS);
    this.terrainVersion += 1;

    for (let g = 0; g < GRAINS_PER_DIG; g++) {
      if (this.grains.length >= MAX_LOOSE_GRAINS) this.grains.shift();
      const gx = ant.x + (Math.random() - 0.5) * 2.8;
      const gz = ant.z + (Math.random() - 0.5) * 2.8;
      const base = sampleHeightBilinear(this.terrainHeight, gx, gz);
      this.grains.push({
        x: gx,
        z: gz,
        y: base + 0.03 + Math.random() * 0.04,
      });
    }

    const keys = [...this.tunnels];
    const pick = keys[Math.floor(Math.random() * keys.length)];
    const [sx, sz, sd] = pick.split(',').map(Number);
    const dirs = [
      [1, 0, 0],
      [-1, 0, 0],
      [0, 1, 0],
      [0, -1, 0],
      [0, 0, 1],
    ];
    const [dx, dz, dd] = dirs[Math.floor(Math.random() * dirs.length)];
    const nx = sx + dx;
    const nz = sz + dz;
    const nd = Math.min(MAX_TUNNEL_DEPTH, Math.max(1, sd + dd));
    if (nx >= 1 && nx < GRID_SIZE - 1 && nz >= 1 && nz < GRID_SIZE - 1) {
      this.tunnels.add(tunnelKey(nx, nz, nd));
    }
  }

  step(dt: number): void {
    const steps = Math.min(15, Math.max(1, Math.floor(dt / SIM_STEP)));
    const h = SIM_STEP * ANT_SPEED;
    const noiseAccel = WANDER_ANG_ACCEL * SIM_STEP;

    for (let s = 0; s < steps; s++) {
      this.home.step();
      this.foodTrail.step();
      this.emitNest();

      for (const ant of this.ants) {
        const homeS = this.sampleSensors(ant, this.home);
        const foodS = this.sampleSensors(ant, this.foodTrail);

        /** Correlated random walk — primary motion for exploration. */
        ant.omega += (Math.random() - 0.5) * 2 * noiseAccel;
        ant.omega *= WANDER_ANG_DAMP;
        ant.omega = Math.max(-WANDER_MAX_OMEGA, Math.min(WANDER_MAX_OMEGA, ant.omega));

        let steer = ant.omega;

        if (ant.role === 'carry') {
          steer += this.steerTowardGradient(
            homeS[0],
            homeS[1],
            homeS[2],
            CARRIER_HOME_GAIN,
            (Math.random() - 0.5) * 0.08
          );
          const cx = Math.floor(ant.x);
          const cz = Math.floor(ant.z);
          this.foodTrail.addDeposit(cx, cz, FOOD_TRAIL_DEPOSIT, 1.0);
        } else {
          const maxTrail = Math.max(foodS[0], foodS[1], foodS[2]);
          if (maxTrail > FOOD_SENSITIVITY) {
            steer += this.steerTowardGradient(
              foodS[0],
              foodS[1],
              foodS[2],
              0.55,
              (Math.random() - 0.5) * 0.06
            );
          }
          const cx = Math.floor(ant.x);
          const cz = Math.floor(ant.z);
          this.home.addDeposit(cx, cz, EXPLORATION_DEPOSIT, 0.7);
        }

        ant.theta = wrapAngle(ant.theta + steer * SIM_STEP);
        ant.x += Math.cos(ant.theta) * h;
        ant.z += Math.sin(ant.theta) * h;

        this.reflectAtBounds(ant);

        if (ant.role === 'forage') {
          if (this.tryHarvest(ant)) {
            ant.role = 'carry';
          }
          this.maybeDig(ant);
        } else {
          if (this.atNest(ant)) {
            ant.role = 'forage';
            this.foodDelivered += 1;
          }
        }
      }

      this.tick += 1;
    }
  }

  getSnapshot(): WorldSnapshot {
    return {
      ants: this.ants.map((a) => ({ ...a })),
      foodSources: this.foodSources.map((f) => ({ ...f })),
      tunnelKeys: [...this.tunnels],
      tick: this.tick,
      foodDelivered: this.foodDelivered,
      looseGrainCount: this.grains.length,
      terrainVersion: this.terrainVersion,
    };
  }
}
