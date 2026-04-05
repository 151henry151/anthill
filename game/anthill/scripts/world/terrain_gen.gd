extends RefCounted
class_name TerrainGen

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")


## Surface sits near the top of the chunk so the bulk of SIZE_Y is subsurface.
## ~40 layers of sand above stone; stone extends down to y=0.
const SURFACE_BASE := 210

## Fills the chunk. Subsurface fill uses **`BLOCK_PACKED_SAND`** so bulk terrain is stable under falling-sand physics; loose **`BLOCK_SAND`** is only created by ants (e.g. spoil).
## If **`on_sand_column_placed`** is set, it is called **once per world XZ** the first time a sand-like block is written in that column (used to seed falling-sand columns without a second full-world scan).
static func fill_chunk(chunk: RefCounted, noise: FastNoiseLite, on_sand_column_placed: Callable = Callable()) -> void:
	var sx: int = _Chunk.SIZE_X
	var sy: int = _Chunk.SIZE_Y
	var sz: int = _Chunk.SIZE_Z
	for lz in range(sz):
		for lx in range(sx):
			var wx: int = chunk.cx * sx + lx
			var wz: int = chunk.cz * sz + lz
			var h: int = int(float(SURFACE_BASE) + noise.get_noise_2d(wx * 0.012, wz * 0.012) * 1.5)
			h = clampi(h, 4, sy - 4)
			var stone_top: int = h - 40
			for ly in range(0, stone_top):
				chunk.set_b(lx, ly, lz, _Const.BLOCK_STONE)
			var marked: bool = false
			for ly in range(stone_top, h):
				chunk.set_b(lx, ly, lz, _Const.BLOCK_PACKED_SAND)
				if not marked and on_sand_column_placed.is_valid():
					on_sand_column_placed.call(wx, wz)
					marked = true
