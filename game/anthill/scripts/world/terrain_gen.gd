extends RefCounted
class_name TerrainGen

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")


## Surface sits near the top of the chunk so the bulk of SIZE_Y is subsurface.
## ~40 layers of sand above stone; stone extends down to y=0.
const SURFACE_BASE := 210

static func fill_chunk(chunk: RefCounted, noise: FastNoiseLite) -> void:
	var sx: int = _Chunk.SIZE_X
	var sy: int = _Chunk.SIZE_Y
	var sz: int = _Chunk.SIZE_Z
	for lz in range(sz):
		for lx in range(sx):
			var wx: int = chunk.cx * sx + lx
			var wz: int = chunk.cz * sz + lz
			var h: int = int(float(SURFACE_BASE) + noise.get_noise_2d(wx * 0.04, wz * 0.04) * 8.0)
			h = clampi(h, 4, sy - 4)
			var stone_top: int = h - 40
			for ly in range(0, stone_top):
				chunk.set_b(lx, ly, lz, _Const.BLOCK_STONE)
			for ly in range(stone_top, h):
				chunk.set_b(lx, ly, lz, _Const.BLOCK_SAND)
