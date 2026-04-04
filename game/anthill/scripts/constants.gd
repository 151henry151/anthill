extends Object
class_name GameConstants
## Fiction: one voxel = one sand grain. Godot units match voxels 1:1 for the prototype.
const GRAIN_SIZE_MM := 3.0
## How many millimetres one world unit represents (same as grain for this build).
const MM_PER_UNIT := GRAIN_SIZE_MM

const BLOCK_AIR := 0
const BLOCK_SAND := 1
const BLOCK_STONE := 2
