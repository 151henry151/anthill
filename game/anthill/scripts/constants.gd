extends Object
class_name GameConstants
## Fiction: one voxel = one sand grain. Godot units match voxels 1:1 for the prototype.
## Colony camera orthographic `size` is vertical world units visible; grain height in pixels ≈ viewport_height / size.
##
## Real-world scale (order of magnitude): natural sand grains are often ~0.06–2 mm diameter (Wentworth:
## fine ~0.06–0.25 mm, medium ~0.25–0.5 mm, coarse ~0.5–2 mm). Worker ants are commonly ~3–15 mm body
## length (species-dependent). A grain-to-ant length ratio ~5:1–20:1 is plausible; “carry one grain” needs
## the ant’s body a few times larger than one grain — here one voxel ≈ one grain and the ant model is
## ~8–12 voxels long before colony-view scaling.
const GRAIN_SIZE_MM := 3.0
## How many millimetres one world unit represents (same as grain for this build).
const MM_PER_UNIT := GRAIN_SIZE_MM

const BLOCK_AIR := 0
const BLOCK_SAND := 1
const BLOCK_STONE := 2
