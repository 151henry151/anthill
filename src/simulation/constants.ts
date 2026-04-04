/** World grid resolution (square). */
export const GRID_SIZE = 128;

/** World extent in simulation units; maps to 3D via CELL_SIZE. */
export const CELL_SIZE = 0.35;

/** Fixed physics step (seconds). Multiple may run per frame. */
export const SIM_STEP = 1 / 30;

/** Number of worker ants in the colony. */
export const ANT_COUNT = 120;

/** Nest center in grid coordinates. */
export const NEST_IX = GRID_SIZE / 2;
export const NEST_IZ = GRID_SIZE / 2;
export const NEST_RADIUS = 4;

/**
 * Pheromone dynamics (discrete diffusion + evaporation).
 * Tuned so trails remain local but persist long enough to recruit.
 */
export const PHEROMONE_EVAPORATION = 0.012;
export const PHEROMONE_DIFFUSION = 0.22;

/** Emitted at the nest each step (creates a home-gradient for homing). */
export const NEST_EMISSION = 2.4;

/** Laid per step by food-carrying ants (recruitment / stigmergy). */
export const FOOD_TRAIL_DEPOSIT = 0.85;

/** Weak trail laid by foragers (exploratory marking). */
export const EXPLORATION_DEPOSIT = 0.08;

/** Ant movement speed in grid cells per second. */
export const ANT_SPEED = 3.2;

/** Distance (cells) at which antennae sample the field. */
export const SENSOR_DISTANCE = 1.1;

/** Angle between left/center/right sensors (radians). */
export const SENSOR_SPREAD = 0.55;

/** Noise on heading (radians per sqrt(second)) — exploration. */
export const ANGLE_NOISE = 1.15;

/** How strongly ants steer toward pheromone gradients. */
export const PHEROMONE_TURN_GAIN = 2.1;

/** Minimum food scent before a forager treats it as a cue. */
export const FOOD_SENSITIVITY = 0.02;

/** Probability per step for a nearby forager to excavate (stochastic digging). */
export const DIG_PROBABILITY = 0.0008;

/** Max underground depth (layers below surface). */
export const MAX_TUNNEL_DEPTH = 4;
