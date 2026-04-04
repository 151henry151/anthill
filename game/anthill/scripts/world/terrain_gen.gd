extends RefCounted
class_name TerrainGen

static func fill_chunk(chunk: VoxelChunk, noise: FastNoiseLite) -> void:
	var sx := VoxelChunk.SIZE_X
	var sy := VoxelChunk.SIZE_Y
	var sz := VoxelChunk.SIZE_Z
	for lz in sz:
		for lx in sx:
			var wx := chunk.cx * sx + lx
			var wz := chunk.cz * sz + lz
			var h: int = int(18.0 + noise.get_noise_2d(wx * 0.04, wz * 0.04) * 8.0)
			h = clampi(h, 4, sy - 4)
			for ly in sy:
				var wy := ly
				var id := GameConstants.BLOCK_AIR
				if wy < h - 4:
					id = GameConstants.BLOCK_STONE
				elif wy < h:
					id = GameConstants.BLOCK_SAND
				else:
					id = GameConstants.BLOCK_AIR
				chunk.set_b(lx, ly, lz, id)
