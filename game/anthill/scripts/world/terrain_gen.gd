extends RefCounted
class_name TerrainGen

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")


static func fill_chunk(chunk: RefCounted, noise: FastNoiseLite) -> void:
	var sx: int = _Chunk.SIZE_X
	var sy: int = _Chunk.SIZE_Y
	var sz: int = _Chunk.SIZE_Z
	for lz in range(sz):
		for lx in range(sx):
			var wx: int = chunk.cx * sx + lx
			var wz: int = chunk.cz * sz + lz
			var h: int = int(18.0 + noise.get_noise_2d(wx * 0.04, wz * 0.04) * 8.0)
			h = clampi(h, 4, sy - 4)
			for ly in range(sy):
				var wy: int = ly
				var id: int = _Const.BLOCK_AIR
				if wy < h - 4:
					id = _Const.BLOCK_STONE
				elif wy < h:
					id = _Const.BLOCK_SAND
				else:
					id = _Const.BLOCK_AIR
				chunk.set_b(lx, ly, lz, id)
