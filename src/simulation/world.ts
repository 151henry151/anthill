import {
  ANGLE_NOISE,
  ANT_COUNT,
  ANT_SPEED,
  DIG_PROBABILITY,
  EXPLORATION_DEPOSIT,
  FOOD_SENSITIVITY,
  FOOD_TRAIL_DEPOSIT,
  GRID_SIZE,
  MAX_TUNNEL_DEPTH,
  NEST_EMISSION,
  NEST_IX,
  NEST_IZ,
  NEST_RADIUS,
  PHEROMONE_TURN_GAIN,
  SENSOR_DISTANCE,
  SENSOR_SPREAD,
  SIM_STEP,
} from './constants';
import { PheromoneField } from './pheromones';
import type { Ant, FoodSource } from './types';

function nestDist(ix: number, iz: number): number {
  const dx = ix - NEST_IX;
  const dz = iz - NEST_IZ;
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
}

export class World {
  readonly home = new PheromoneField();
  readonly foodTrail = new PheromoneField();
  ants: Ant[] = [];
  foodSources: FoodSource[] = [];
  readonly tunnels = new Set<string>();
  tick = 0;
  foodDelivered = 0;

  constructor() {
    this.seedFood();
    this.seedTunnels();
    this.seedAnts();
  }

  private seedFood(): void {
    const margin = 18;
    this.foodSources = [
      { ix: margin, iz: margin, radius: 5, remaining: 5000 },
      { ix: GRID_SIZE - margin, iz: margin, radius: 5, remaining: 5000 },
      { ix: GRID_SIZE - margin, iz: GRID_SIZE - margin, radius: 5, remaining: 5000 },
      { ix: margin, iz: GRID_SIZE - margin, radius: 5, remaining: 5000 },
    ];
  }

  private seedTunnels(): void {
    this.tunnels.add(tunnelKey(NEST_IX, NEST_IZ, 1));
    for (let k = 0; k < 24; k++) {
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
        role: 'forage',
      });
    }
  }

  private emitNest(): void {
    const r = NEST_RADIUS + 1.2;
    this.home.addDeposit(NEST_IX, NEST_IZ, NEST_EMISSION, r);
  }

  private sampleSensors(
    ant: Ant,
    field: PheromoneField
  ): [number, number, number] {
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
    noise: number
  ): number {
    /** Turn toward the side with stronger scent (bilateral antennae comparison). */
    const g = PHEROMONE_TURN_GAIN * (left - right);
    const centerBias = (center - (left + right) * 0.5) * 0.12;
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

  private maybeDig(ant: Ant): void {
    if (ant.role !== 'forage') return;
    if (nestDist(ant.x, ant.z) > NEST_RADIUS + 3) return;
    if (Math.random() > DIG_PROBABILITY) return;
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
    if (
      nx < 1 ||
      nx >= GRID_SIZE - 1 ||
      nz < 1 ||
      nz >= GRID_SIZE - 1
    ) {
      return;
    }
    this.tunnels.add(tunnelKey(nx, nz, nd));
  }

  step(dt: number): void {
    const steps = Math.min(15, Math.max(1, Math.floor(dt / SIM_STEP)));
    const h = SIM_STEP * ANT_SPEED;

    for (let s = 0; s < steps; s++) {
      this.home.step();
      this.foodTrail.step();
      this.emitNest();

      const noiseScale = ANGLE_NOISE * Math.sqrt(SIM_STEP);

      for (const ant of this.ants) {
        const homeS = this.sampleSensors(ant, this.home);
        const foodS = this.sampleSensors(ant, this.foodTrail);

        let dTheta = (Math.random() - 0.5) * 2 * noiseScale;

        if (ant.role === 'carry') {
          dTheta += this.steerTowardGradient(
            homeS[0],
            homeS[1],
            homeS[2],
            (Math.random() - 0.5) * noiseScale * 0.5
          );
          const cx = Math.floor(ant.x);
          const cz = Math.floor(ant.z);
          this.foodTrail.addDeposit(cx, cz, FOOD_TRAIL_DEPOSIT, 1.2);
        } else {
          const maxTrail = Math.max(foodS[0], foodS[1], foodS[2]);
          if (maxTrail > FOOD_SENSITIVITY) {
            dTheta += this.steerTowardGradient(
              foodS[0],
              foodS[1],
              foodS[2],
              (Math.random() - 0.5) * noiseScale * 0.4
            );
          }
          dTheta += (Math.random() - 0.5) * noiseScale * 1.2;
          const cx = Math.floor(ant.x);
          const cz = Math.floor(ant.z);
          this.home.addDeposit(cx, cz, EXPLORATION_DEPOSIT, 0.9);
        }

        ant.theta = wrapAngle(ant.theta + dTheta * SIM_STEP);
        ant.x += Math.cos(ant.theta) * h;
        ant.z += Math.sin(ant.theta) * h;

        ant.x = Math.min(GRID_SIZE - 1.5, Math.max(1.5, ant.x));
        ant.z = Math.min(GRID_SIZE - 1.5, Math.max(1.5, ant.z));

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
    };
  }
}
