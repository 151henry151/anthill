extends RefCounted
class_name SandStep

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")


static func step(world: Node) -> void:
	var sx: int = world.chunks_x * _Chunk.SIZE_X
	var sy: int = _Chunk.SIZE_Y
	var sz: int = world.chunks_z * _Chunk.SIZE_Z
	var moves: Array[Vector3i] = []
	for x in range(sx):
		for z in range(sz):
			for y in range(1, sy):
				if world.get_block(x, y, z) == _Const.BLOCK_SAND:
					if world.get_block(x, y - 1, z) == _Const.BLOCK_AIR:
						moves.append(Vector3i(x, y, z))
	moves.shuffle()
	for p in moves:
		if world.get_block(p.x, p.y, p.z) != _Const.BLOCK_SAND:
			continue
		if world.get_block(p.x, p.y - 1, p.z) != _Const.BLOCK_AIR:
			continue
		world.set_block(p.x, p.y, p.z, _Const.BLOCK_AIR)
		world.set_block(p.x, p.y - 1, p.z, _Const.BLOCK_SAND)
