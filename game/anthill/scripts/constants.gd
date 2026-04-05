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
## Energy drain per physics tick during claustral phase (queen survives ~40 ant-days).
const QUEEN_CLAUSTRAL_ENERGY_DRAIN_PER_TICK := 1.0 / float(40 * TICKS_PER_ANT_DAY)
## Energy regained when queen cannibalises a trophic egg.
const QUEEN_EGG_CANNIBAL_ENERGY_GAIN := 0.06
## Energy drain per tick when queen feeds a larva from reserves.
const QUEEN_LARVA_FEED_ENERGY_COST := 0.003
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
## Amount deposited per cell per deposit event.
const PHEROMONE_DEPOSIT_AMOUNT := 0.15
## Multiplicative factor applied every evaporation tick.
const PHEROMONE_EVAPORATION_RATE := 0.97
## Physics ticks between evaporation passes.
const PHEROMONE_EVAPORATION_INTERVAL_TICKS := 60
## Cells below this are removed.
const PHEROMONE_MINIMUM_THRESHOLD := 0.005

# ---------------------------------------------------------------------------
# Food sources
# ---------------------------------------------------------------------------
## How much food an ant carries per trip (fraction of source supply).
const FOOD_CARRY_AMOUNT := 0.04
## Number of food sources spawned at game start.
const FOOD_SOURCE_COUNT_MIN := 3
const FOOD_SOURCE_COUNT_MAX := 6
## Aphid colony replenish rate per physics tick (fraction of max_supply).
const APHID_REPLENISH_RATE := 0.0001

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
## Radius from entrance for spoil deposits.
const SPOIL_DEPOSIT_RADIUS := 12
## Max extra height of spoil pile above surface.
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
const DEPTH_WEIGHT := 0.8
const TUNNEL_CONTINUE_BONUS := 2.0
const CROWDING_PENALTY := 5.0
const NOISE_AMPLITUDE := 0.3
const BLUEPRINT_WEIGHT := 1.5
const RADIAL_OUTWARD_BIAS := 2.0
const TUNNEL_EXTEND_BIAS := 2.5
## Voxels of open volume that trigger branching transition.
const CHAMBER_THRESHOLD := 400

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
# Worker movement intervals (seconds between steps)
# ---------------------------------------------------------------------------
const WORKER_MOVE_INTERVAL := 0.45
const QUEEN_SEARCH_MOVE_INTERVAL := 0.8
const QUEEN_DIG_INTERVAL := 0.3

# ---------------------------------------------------------------------------
# Opening cinematic timings (seconds)
# ---------------------------------------------------------------------------
const QUEEN_FLY_IN_DURATION := 4.0
const QUEEN_WING_SHED_DURATION := 2.0
const QUEEN_SEARCH_DURATION_MIN := 10.0
const QUEEN_SEARCH_DURATION_MAX := 20.0
