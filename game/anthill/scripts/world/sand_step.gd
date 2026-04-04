extends RefCounted
class_name SandStep

## Minecraft-style: sand falls into air below. One pass per call; run every physics frame.
static func step(world: WorldManager) -> void:
	var sx := world.chunks_x * VoxelChunk.SIZE_X
	var sy := VoxelChunk.SIZE_Y
	var sz := world.chunks_z * VoxelChunk.SIZE_Z
	var moves: Array[Vector3i] = []
	for x in range(sx):
		for z in range(sz):
			for y in range(1, sy):
				if world.get_block(x, y, z) == GameConstants.BLOCK_SAND:
					if world.get_block(x, y - 1, z) == GameConstants.BLOCK_AIR:
						moves.append(Vector3i(x, y, z))
	moves.shuffle()
	for p in moves:
		if world.get_block(p.x, p.y, p.z) != GameConstants.BLOCK_SAND:
			continue
		if world.get_block(p.x, p.y - 1, p.z) != GameConstants.BLOCK_AIR:
			continue
		world.set_block(p.x, p.y, p.z, GameConstants.BLOCK_AIR)
		world.set_block(p.x, p.y - 1, p.z, GameConstants.BLOCK_SAND)
