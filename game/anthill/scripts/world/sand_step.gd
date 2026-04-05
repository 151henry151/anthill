extends RefCounted
class_name SandStep

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")
const _TerrainGen := preload("res://scripts/world/terrain_gen.gd")

## Only scan the region where sand can exist: from stone top to a few layers above surface.
const _SCAN_FLOOR := _TerrainGen.SURFACE_BASE - 50
const _SCAN_CEIL := _TerrainGen.SURFACE_BASE + 20


func step(world: Node) -> void:
	if world.get("sand_idle") == true:
		return
	if not world.has_method("take_sand_columns"):
		return
	var cols: Array = world.call("take_sand_columns")
	if cols.is_empty():
		world.set("sand_idle", true)
		return
	var y_lo: int = maxi(_SCAN_FLOOR, 1)
	var y_hi: int = mini(_SCAN_CEIL, _Chunk.SIZE_Y)
	var moves: Array[Vector3i] = []
	for xz in cols:
		var x: int = xz.x
		var z: int = xz.y
		for y in range(y_lo, y_hi):
			if world.get_block(x, y, z) == _Const.BLOCK_SAND:
				if world.get_block(x, y - 1, z) == _Const.BLOCK_AIR:
					moves.append(Vector3i(x, y, z))
	if moves.is_empty():
		world.set("sand_idle", true)
		return
	moves.shuffle()
	for p in moves:
		if world.get_block(p.x, p.y, p.z) != _Const.BLOCK_SAND:
			continue
		if world.get_block(p.x, p.y - 1, p.z) != _Const.BLOCK_AIR:
			continue
		world.set_block(p.x, p.y, p.z, _Const.BLOCK_AIR)
		world.set_block(p.x, p.y - 1, p.z, _Const.BLOCK_SAND)
