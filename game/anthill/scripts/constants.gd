extends Object
class_name GameConstants
## Fiction: one voxel = one sand grain. Godot units match voxels 1:1 for the prototype.
## Colony camera orthographic `size` is vertical world units visible; grain height in pixels ≈ viewport_height / size.
##
## Real-world scale (order of magnitude): natural sand grains are often ~0.06–2 mm diameter (Wentworth:
## fine ~0.06–0.25 mm, medium ~0.25–0.5 mm, coarse ~0.5–2 mm). Worker ants are commonly ~3–15 mm body
## length (species-dependent). A grain-to-ant length ratio ~5:1–20:1 is plausible; "carry one grain" needs
## the ant's body a few times larger than one grain — here one voxel ≈ one grain and the ant model is
## ~8–12 voxels long before colony-view scaling.
const GRAIN_SIZE_MM := 3.0
## How many millimetres one world unit represents (same as grain for this build).
const MM_PER_UNIT := GRAIN_SIZE_MM

const BLOCK_AIR := 0
const BLOCK_SAND := 1
const BLOCK_STONE := 2
const BLOCK_PACKED_SAND := 3

## Contiguous **loose sand** voxels in one column above this count trigger lateral spill (one top grain per column per sand step).
const SAND_LATERAL_SPILL_STACK_LIMIT := 6
## Lateral spill does not **deposit** onto surface columns within this XZ radius of **`nest_spill_exclude_xz`** (reduces plugging the shaft mouth).
const NEST_SPILL_LATERAL_EXCLUDE_RADIUS := 5
## Workers within this horizontal distance of **`nest_entrance`** complete **returning** (covers shaft + spoil ring; a tight radius strands workers on the mound rim).
const WORKER_NEST_ARRIVAL_MAX_DIST := 10.0
## Within this horizontal distance of **`nest_entrance`**, workers may engage **shaft clearing** (dig sand / packed sand blocking the shaft).
const WORKER_ENTRANCE_CLEAR_ENGAGE_DIST := 14.0

# ---------------------------------------------------------------------------
# Game time scale  (Lasius niger biology compressed into playable real-time)
# ---------------------------------------------------------------------------
## Physics ticks map 1:1 with Godot physics ticks (default 30/sec).
const TICKS_PER_GAME_SECOND := 1
## One "ant-day" lasts this many real-time seconds (at 30 ticks/sec → 1800 ticks).
const GAME_SECONDS_PER_ANT_DAY := 60
## Convenience: ticks per ant-day.
const TICKS_PER_ANT_DAY := GAME_SECONDS_PER_ANT_DAY * 30
const GAME_DAYS_PER_ANT_WEEK := 7

# ---------------------------------------------------------------------------
# Brood development durations (ant-days at ~24 °C baseline)
# ---------------------------------------------------------------------------
const EGG_DURATION_DAYS := 10
const LARVA_DURATION_DAYS := 14
const PUPA_DURATION_DAYS := 10
## Total egg→adult: 34 ant-days ≈ 34 real minutes.
const EGG_DURATION_TICKS := EGG_DURATION_DAYS * TICKS_PER_ANT_DAY
const LARVA_DURATION_TICKS := LARVA_DURATION_DAYS * TICKS_PER_ANT_DAY
const PUPA_DURATION_TICKS := PUPA_DURATION_DAYS * TICKS_PER_ANT_DAY

# ---------------------------------------------------------------------------
# Queen parameters
# ---------------------------------------------------------------------------
## Ticks between egg batches during claustral phase.
const QUEEN_CLAUSTRAL_EGG_INTERVAL_TICKS := 4 * TICKS_PER_ANT_DAY
## Batch size during claustral phase.
const QUEEN_CLAUSTRAL_EGG_BATCH_MIN := 3
const QUEEN_CLAUSTRAL_EGG_BATCH_MAX := 6
## Ticks between egg batches once colony is established.
const QUEEN_ESTABLISHED_EGG_INTERVAL_TICKS := 2 * TICKS_PER_ANT_DAY
## Energy drain per physics tick during claustral phase (queen survives ~55 ant-days at **1.0** reserve; must exceed **egg + larva + pupa** time to first worker plus founding variance).
const QUEEN_CLAUSTRAL_ENERGY_DRAIN_PER_TICK := 1.0 / float(55 * TICKS_PER_ANT_DAY)
## Energy regained when queen cannibalises a trophic egg.
const QUEEN_EGG_CANNIBAL_ENERGY_GAIN := 0.06
## Legacy single-feed cost (reserved for future targeted care).
const QUEEN_LARVA_FEED_ENERGY_COST := 0.003
## Nutrition added to **each** larva per tick when the queen is the sole caregiver (claustral, or established with no workers yet). Slightly above base larva loss so brood can reach pupation.
const QUEEN_LARVA_FEED_PER_TICK := 0.00012
## Extra energy subtracted per larva per tick when provisioning (**0** = cost is folded into **`QUEEN_CLAUSTRAL_ENERGY_DRAIN`**; non-zero values drain the queen many times faster than base metabolism and prevent first eclosion).
const QUEEN_LARVA_FEED_ENERGY_PER_LARVA_PER_TICK := 0.0
## Trophallaxis-style topping when workers exist (foraging not modeled per-larva; stabilizes nutrition until a fuller food→brood loop exists).
const WORKER_BROOD_CARE_PER_TICK := 0.00011
## Workers regurgitate crop contents to nestmates (**stomodeal trophallaxis**); the queen is fed by workers and does not forage. Base food mass (colony-store units) moved toward the queen per tick, before scaling by worker count.
const QUEEN_TROPHALLAXIS_BASE_PER_TICK := 0.000018
## Extra trophallaxis capacity per **`sqrt(worker_count)`** (diminishing returns vs a naive linear headcount).
const QUEEN_TROPHALLAXIS_PER_WORKER_SQRT := 0.0000055
## Split of each tick’s trophallaxis **request** between sugar (carbohydrate) and protein.
const QUEEN_TROPHALLAXIS_SUGAR_FRACTION := 0.52
const QUEEN_TROPHALLAXIS_PROTEIN_FRACTION := 0.48
## Converts colony-store mass taken by the queen into **`energy_reserve`** (0–1); tuned so full recovery from depletion takes on the order of many ant-days when stores are abundant.
const QUEEN_TROPHALLAXIS_ENERGY_PER_UNIT_FOOD := 0.34
## Visual scale multiplier for queen vs worker model.
const QUEEN_VISUAL_SCALE := 6.0
## Worker visual scale.
const WORKER_VISUAL_SCALE := 3.0
## Nanitic (first-generation) workers are smaller.
const NANITIC_VISUAL_SCALE := 2.1

# ---------------------------------------------------------------------------
# Worker age-based polyethism
# ---------------------------------------------------------------------------
## Workers younger than this (ticks) perform interior tasks only.
const YOUNG_WORKER_AGE_THRESHOLD := 10 * TICKS_PER_ANT_DAY
## Ticks for a callow worker to darken from pale to full colour.
const CALLOW_DARKEN_TICKS := 3 * TICKS_PER_ANT_DAY

# ---------------------------------------------------------------------------
# Pheromone trail
# ---------------------------------------------------------------------------
## Each pheromone cell covers this many voxels on a side.
const PHEROMONE_CELL_SIZE := 2
## Base deposit per step while RETURNING with food.
const PHEROMONE_BASE_DEPOSIT := 0.12
## Extra deposit amount close to food source.
const PHEROMONE_DISTANCE_BONUS := 0.18
## Legacy single-event deposit (food pickup burst).
const PHEROMONE_DEPOSIT_AMOUNT := 0.15
## Multiplicative factor applied every evaporation tick (closer to 1.0 = slower evaporation).
const PHEROMONE_EVAPORATION_RATE := 0.985
## Explicit Laplacian diffusion step on the trail grid each evaporation interval (**< 0.25** for 4-neighbor stability).
const PHEROMONE_DIFFUSION_LAMBDA := 0.12
## Physics ticks between evaporation passes.
const PHEROMONE_EVAPORATION_INTERVAL_TICKS := 30
## Min concentration to trigger trail-following mode.
const PHEROMONE_RECRUIT_THRESHOLD := 0.02
## Cells below this are removed.
const PHEROMONE_MINIMUM_THRESHOLD := 0.005
## Voxels ahead an ant can sense trail.
const PHEROMONE_SENSE_RADIUS := 4
## Minimum roulette weight for tropotaxis (flat field → near-uniform random walk among walkable Moore neighbors).
const PHEROMONE_TROPOTAXIS_FLOOR := 0.001
## Bernoulli probability that a **satiated** returning forager deposits recruitment pheromone at each **spot** opportunity (spec ~1/3).
const TRAIL_SATIATED_DEPOSIT_PROBABILITY := 0.333333
## Laboratory spacing of discrete trail **spots** along the return path (mm); converted to voxels via **`MM_PER_UNIT`**.
const TRAIL_SPOT_MIN_MM := 20.0
const TRAIL_SPOT_MAX_MM := 40.0
## Below this local trail concentration, CHC footprint uses **search-phase** weak attraction to explored substrate; at or above, **exploitation-phase** repellent term applies.
const PHEROMONE_EXPLOITATION_THRESHOLD := 0.015
## Weight on **`max(0, f_nb − f_here)`** in **search** phase (positive chemotaxis to recent exploration).
const FOOTPRINT_SEARCH_ATTRACTION_WEIGHT := 0.35

# ---------------------------------------------------------------------------
# Pheromone overlay (scientific visualization — [P] field view)
# ---------------------------------------------------------------------------
## Recruitment / foraging trail (**2D** surface field).
const PHEROMONE_VIS_RECRUITMENT := Color(0.12, 0.82, 0.38, 1.0)
## Cuticular hydrocarbon **footprint** (passive substrate marking).
const PHEROMONE_VIS_FOOTPRINT := Color(0.88, 0.28, 0.72, 1.0)
## **Nest construction** stigmergy (**3D** voxel field).
const PHEROMONE_VIS_BUILDING := Color(0.96, 0.74, 0.18, 1.0)
## When local **recruitment** concentration exceeds this, scale down further **fed-worker** deposits (counteracts runaway positive feedback; cf. *briefing.txt*).
const TRAIL_SATURATION_START := 0.38
## Multiplier applied to recruitment deposit at **full** saturation (**1.0** = no extra deposit).
const TRAIL_SATURATION_MIN_DEPOSIT_SCALE := 0.22

# ---------------------------------------------------------------------------
# Footprint hydrocarbons (CHC) — passive marking, negative chemotaxis (Lasius niger)
# ---------------------------------------------------------------------------
## Deposited per successful worker step (tarsi); same grid resolution as **`PHEROMONE_CELL_SIZE`**.
const FOOTPRINT_DEPOSIT_PER_STEP := 0.0035
## Slow decay (persistent “hours–days” substrate marking in compressed ant-time).
const FOOTPRINT_EVAPORATION_RATE := 0.997
const FOOTPRINT_EVAPORATION_INTERVAL_TICKS := 90
const FOOTPRINT_MINIMUM_THRESHOLD := 0.0002
## Weight on **`max(0, f_here − f_nb)`** in combined scout/recruit roulette (repellent / negative feedback).
const FOOTPRINT_REPULSION_WEIGHT := 2.2
## Base roulette weight for **scout** exploration before footprint terms.
const FOOTPRINT_SCOUT_BASE_WEIGHT := 0.002
## Extra emphasis on footprint avoidance while **scouting** (vs recruit).
const FOOTPRINT_SCOUT_REPULSION_MULT := 1.4

# ---------------------------------------------------------------------------
# Foraging task balance
# ---------------------------------------------------------------------------
const FOOD_STORE_TARGET_SUGAR := 200.0
const FOOD_STORE_TARGET_PROTEIN := 150.0
const MIN_FORAGER_FRACTION := 0.15
const SCOUT_MAX_TURN_DEG_PER_STEP := 25.0
const SCOUT_MIN_SEARCH_RADIUS := 15.0

# ---------------------------------------------------------------------------
# Food sources  (finite, spoil over time; new ones spawn at random intervals)
# ---------------------------------------------------------------------------
## How much food an ant carries per trip (fraction of source supply).
const FOOD_CARRY_AMOUNT := 0.04
## Bounds on initial **supply** (aphid / insect / seed); scales visuals and rot rate baseline.
const FOOD_APHID_SUPPLY_MIN := 0.38
const FOOD_APHID_SUPPLY_MAX := 1.18
const FOOD_INSECT_SUPPLY_MIN := 0.22
const FOOD_INSECT_SUPPLY_MAX := 0.88
const FOOD_SEED_SUPPLY_MIN := 0.18
const FOOD_SEED_SUPPLY_MAX := 0.62
## Random delay (simulation ticks) before the **first** spawn after load.
const FOOD_SPAWN_FIRST_DELAY_MIN := 90
const FOOD_SPAWN_FIRST_DELAY_MAX := 420
## Random interval (ticks) between spawn attempts once the previous source has been scheduled.
const FOOD_SPAWN_INTERVAL_TICKS_MIN := 400
const FOOD_SPAWN_INTERVAL_TICKS_MAX := 2200
## Cap active sources so the world does not fill indefinitely.
const FOOD_MAX_ACTIVE_SOURCES := 36
## Minimum horizontal distance (voxels) from **nest entrance** XZ when placing new sources (ignored until the nest exists).
const FOOD_SPAWN_MIN_DIST_FROM_NEST := 28
## Spoil duration: random lifetime in ticks; supply also decays by **`supply / duration`** per tick so uneaten food rots away.
const FOOD_SPOIL_DURATION_TICKS_MIN := 2 * TICKS_PER_ANT_DAY
const FOOD_SPOIL_DURATION_TICKS_MAX := 14 * TICKS_PER_ANT_DAY
## Uniform scale range for the visual root at **full** supply (slight size variety).
const FOOD_VISUAL_BASE_SCALE_MIN := 0.82
const FOOD_VISUAL_BASE_SCALE_MAX := 1.12
## At **depleted** supply the visual is scaled to this fraction of the current base scale.
const FOOD_VISUAL_MIN_SCALE_RATIO := 0.14

# ---------------------------------------------------------------------------
# Colony food store thresholds
# ---------------------------------------------------------------------------
## When either food type drops below this, emit food_critical.
const FOOD_CRITICAL_THRESHOLD := 0.15

# ---------------------------------------------------------------------------
# Packed sand / tunnel stability
# ---------------------------------------------------------------------------
## Shell radius around newly dug AIR converted from SAND to PACKED_SAND.
const COMPACTION_RADIUS := 1
## PACKED_SAND takes longer to dig than loose SAND.
const PACKED_SAND_DIG_MULTIPLIER := 2
## Vertex colour for compacted tunnel walls (darker/warmer than loose sand).
const PACKED_SAND_COLOR := Color(0.72, 0.60, 0.38)

# ---------------------------------------------------------------------------
# Nest excavation
# ---------------------------------------------------------------------------
## Ticks to complete one dig act on a SAND voxel.
const DIG_ACT_DURATION_TICKS := 3
## Ticks to wait when blocked in narrow tunnel.
const TUNNEL_YIELD_TICKS := 5
## Radius from entrance for spoil deposits (annulus outer radius; larger → wider mound ring).
const SPOIL_DEPOSIT_RADIUS := 24
## Minimum distance from nest center for spoil samples (disk sampling; world units ≈ voxels).
const SPOIL_DEPOSIT_INNER_CLEAR := 3.5
## Max extra height of spoil pile above baseline surface at a column (rejects deposit targets that are already tall).
const MAX_SPOIL_HEIGHT := 6
## Max simultaneous diggers (performance limit).
const MAX_NEST_BUILDERS := 8
## Target voxels of nest space per worker for volume regulation.
const VOLUME_PER_WORKER := 24
## Maximum voxel depth below surface ants can dig.
const MAX_DIG_DEPTH := 150

# ---------------------------------------------------------------------------
# Tunnel / chamber minimum dimensions (voxels, sized for rendered ant scale)
# ---------------------------------------------------------------------------
const MIN_GALLERY_WIDTH := 4
const MIN_GALLERY_HEIGHT := 4
const MIN_SHAFT_WIDTH := 6
const MIN_BROOD_CHAMBER_DIAMETER := 8
const QUEEN_CHAMBER_DIAMETER := 10
const QUEEN_CHAMBER_HEIGHT := 8
const QUEEN_PERMANENT_CHAMBER_DIAMETER := 14

# ---------------------------------------------------------------------------
# Dig target scoring weights
# ---------------------------------------------------------------------------
## Capped entry shaft pull (strong to get below surface, then levels off).
const SHAFT_TARGET_DEPTH := 14
const DEPTH_WEIGHT_ENTRY := 1.2
## Pull toward blueprint chamber depths (Gaussian-like attraction).
const DEPTH_WEIGHT_CHAMBER := 2.0
const DEPTH_ATTRACTION_FALLOFF := 0.15
## Horizontal gallery expansion.
const MAX_GALLERY_RADIUS := 20
const HORIZONTAL_WEIGHT := 1.8
const TUNNEL_CONTINUE_BONUS := 2.5
const CROWDING_PENALTY := 5.0
const NOISE_AMPLITUDE := 0.5
const BLUEPRINT_WEIGHT := 1.5
const RADIAL_OUTWARD_BIAS := 2.0
const TUNNEL_EXTEND_BIAS := 3.0

# ---------------------------------------------------------------------------
# Building pheromone
# ---------------------------------------------------------------------------
const BUILD_PHEROMONE_DEPOSIT_AMOUNT := 0.4
const BUILD_PHEROMONE_EVAPORATION_RATE := 0.94
const BUILD_PHEROMONE_EVAPORATION_INTERVAL_TICKS := 15
const BUILD_PHEROMONE_MINIMUM := 0.01

# ---------------------------------------------------------------------------
# Founding chamber (queen digs before workers exist)
# ---------------------------------------------------------------------------
## Voxels deep for queen's initial shaft.
const FOUNDING_SHAFT_DEPTH := 14
## Shaft width in voxels (queen is 3 vx wide; needs clearance).
const FOUNDING_SHAFT_WIDTH := 6
## Founding chamber size (x, y, z voxels) — fits queen at 6 vx long.
const FOUNDING_CHAMBER_SIZE := Vector3i(10, 8, 10)
## Cap air BFS expansion when the queen approaches a dig voxel (prevents pathological freezes in huge air volumes).
const QUEEN_BFS_AIR_MAX_NODES := 4096
## Greedy path length cap for queen carry-to-surface (nest-scale; avoids long get_block scans).
const PATH_TO_SURFACE_MAX_STEPS := 200
## Spoil deposit search iterations (each may call **`get_surface_y`**).
const QUEEN_SPOIL_DEPOSIT_SAMPLES := 16

# ---------------------------------------------------------------------------
# Surface trail covers
# ---------------------------------------------------------------------------
const TRAIL_COVER_BUILD_PROB := 0.05

# ---------------------------------------------------------------------------
# X-ray view
# ---------------------------------------------------------------------------
const XRAY_SAND_ALPHA := 0.18
const XRAY_DEPTH_FADE_RANGE := 80.0

# ---------------------------------------------------------------------------
# Fast-forward
# ---------------------------------------------------------------------------
## **[F]** cycles: **1×** → **10×** → **30×** → **60×** → **120×** → **1×** …
const FAST_FORWARD_SPEEDS: Array[float] = [10.0, 30.0, 60.0, 120.0]
## Max simulation sub-steps per physics frame (**`round(Engine.time_scale)`**); matches max **[F]** tier so fast-forward stays stable.
const FAST_FORWARD_SIM_STEPS_CAP := 120

# ---------------------------------------------------------------------------
# Worker movement intervals (seconds between steps)
# ---------------------------------------------------------------------------
const WORKER_MOVE_INTERVAL := 0.45
const QUEEN_SEARCH_MOVE_INTERVAL := 0.8
## Per-voxel dig cycle uses **`WORKER_MOVE_INTERVAL`** for path steps; dig-act uses this sub-tick interval.
const QUEEN_DIG_ACT_TICK_INTERVAL := 0.45

# ---------------------------------------------------------------------------
# Opening cinematic timings (seconds)
# ---------------------------------------------------------------------------
const QUEEN_FLY_IN_DURATION := 4.0
const QUEEN_WING_SHED_DURATION := 2.0
const QUEEN_SEARCH_DURATION_MIN := 10.0
const QUEEN_SEARCH_DURATION_MAX := 20.0
