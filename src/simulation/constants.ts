/** World grid resolution (square). Larger play area for wandering. */
export const GRID_SIZE = 240;

/** World extent in simulation units; maps to 3D via CELL_SIZE. */
export const CELL_SIZE = 0.22;

/** Fixed physics step (seconds). Multiple may run per frame. */
export const SIM_STEP = 1 / 30;

/** Number of worker ants in the colony. */
export const ANT_COUNT = 140;

/** Nest center in grid coordinates. */
export const NEST_IX = GRID_SIZE / 2;
export const NEST_IZ = GRID_SIZE / 2;
export const NEST_RADIUS = 5;

/**
 * Pheromone dynamics — kept weak so foragers rely on random walk unless tuned up later.
 */
export const PHEROMONE_EVAPORATION = 0.018;
export const PHEROMONE_DIFFUSION = 0.2;

/** Emitted at the nest (subtle homing cue for carriers only). */
export const NEST_EMISSION = 0.08;

export const FOOD_TRAIL_DEPOSIT = 0.35;
export const EXPLORATION_DEPOSIT = 0.01;

export const ANT_SPEED = 2.8;

export const SENSOR_DISTANCE = 1.0;
export const SENSOR_SPREAD = 0.5;

/** Correlated random walk: angular acceleration noise (rad/s^2 scale). */
export const WANDER_ANG_ACCEL = 14;
export const WANDER_ANG_DAMP = 0.965;
export const WANDER_MAX_OMEGA = 2.8;

/** Carriers get a weak bias toward nest scent (still mostly wandering). */
export const CARRIER_HOME_GAIN = 0.35;

export const FOOD_SENSITIVITY = 0.35;
export const PHEROMONE_TURN_GAIN = 0.45;

export const DIG_PROBABILITY = 0.0012;
export const MAX_TUNNEL_DEPTH = 5;

/** Sand removed from surface per dig (grid units height). */
export const DIG_CARVE_DEPTH = 0.28;
export const DIG_CARVE_RADIUS = 1.8;

/** Loose grains spawned per dig (capped in world). */
export const GRAINS_PER_DIG = 8;
export const MAX_LOOSE_GRAINS = 3500;

/** Scale terrain height samples to world Y (meters in Three.js). */
export const TERRAIN_VISUAL_SCALE = 0.48;

/** Lift ants slightly above the sand surface. */
export const ANT_FOOT_CLEARANCE = 0.05;
