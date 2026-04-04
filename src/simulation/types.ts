export type AntRole = 'forage' | 'carry';

export interface Ant {
  x: number;
  z: number;
  /** Heading in XZ plane; 0 = +X, π/2 = +Z. */
  theta: number;
  role: AntRole;
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
