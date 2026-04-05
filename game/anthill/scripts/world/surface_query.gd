extends Object
## Fast open-air surface height for colony AI. Narrow band first, then full-column fallback (queen digs).

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")
const _TerrainGen := preload("res://scripts/world/terrain_gen.gd")


static func surface_block_y(world: Node, wx: int, wz: int) -> int:
	var y: int = _surface_block_y_fast(world, wx, wz)
	if y >= 0:
		return y
	return _surface_block_y_full(world, wx, wz)


static func _surface_block_y_fast(world: Node, wx: int, wz: int) -> int:
	var ceiling: int = mini(_Chunk.SIZE_Y - 2, _TerrainGen.SURFACE_BASE + 28)
	var floor_y: int = maxi(1, _TerrainGen.SURFACE_BASE - 80)
	for y in range(ceiling, floor_y - 1, -1):
		if world.get_block(wx, y, wz) != _Const.BLOCK_AIR and world.get_block(wx, y + 1, wz) == _Const.BLOCK_AIR:
			return y
	return -1


static func _surface_block_y_full(world: Node, wx: int, wz: int) -> int:
	var ceiling: int = mini(_Chunk.SIZE_Y - 2, 240)
	for y in range(ceiling, -1, -1):
		if world.get_block(wx, y, wz) != _Const.BLOCK_AIR and world.get_block(wx, y + 1, wz) == _Const.BLOCK_AIR:
			return y
	return -1
