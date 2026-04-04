export type AntRole = 'forage' | 'carry';

export interface Ant {
  x: number;
  z: number;
  /** Heading in XZ plane; 0 = +X, π/2 = +Z. */
  theta: number;
  /** Angular velocity for correlated random walk (rad/s). */
  omega: number;
  role: AntRole;
}

/** Single excavated grain sitting on the surface (world grid coords + height). */
export interface LooseGrain {
  x: number;
  z: number;
  y: number;
}

export interface FoodSource {
  ix: number;
  iz: number;
  radius: number;
  /** Remaining units; depletes slowly when harvested. */
  remaining: number;
}

export interface TunnelCell {
  ix: number;
  iz: number;
  /** 1 = first layer below ground. */
  depth: number;
}
