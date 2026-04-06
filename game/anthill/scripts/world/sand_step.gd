extends RefCounted
class_name SandStep

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")
const _TerrainGen := preload("res://scripts/world/terrain_gen.gd")

## Only scan the region where sand can exist: from stone top to a few layers above surface.
const _SCAN_FLOOR := _TerrainGen.SURFACE_BASE - 50
const _SCAN_CEIL := _TerrainGen.SURFACE_BASE + 20
## Limits work per physics tick so sand + mesh rebuild do not freeze input.
const _MAX_COLUMNS_PER_STEP := 384


func step(world: Node) -> void:
	if world.get("sand_idle") == true:
		return
	if not world.has_method("take_sand_columns"):
		return
	var cols: Array = world.callv("take_sand_columns", [_MAX_COLUMNS_PER_STEP])
	if cols.is_empty():
		world.set("sand_idle", true)
		return
	var cols_spill: Array = cols.duplicate()
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
	moves.shuffle()
	for p in moves:
		if world.get_block(p.x, p.y, p.z) != _Const.BLOCK_SAND:
			continue
		if world.get_block(p.x, p.y - 1, p.z) != _Const.BLOCK_AIR:
			continue
		world.set_block(p.x, p.y, p.z, _Const.BLOCK_AIR)
		world.set_block(p.x, p.y - 1, p.z, _Const.BLOCK_SAND)
	for xz in cols_spill:
		_try_lateral_spill_column(world, xz.x, xz.y, y_lo, y_hi)


## Move one top **loose sand** grain sideways when the column is taller than **`SAND_LATERAL_SPILL_STACK_LIMIT`**.
func _try_lateral_spill_column(world: Node, wx: int, wz: int, y_lo: int, y_hi: int) -> void:
	if not world.has_method("get_surface_y"):
		return
	var y_top: int = -1
	for y in range(y_hi - 1, y_lo - 1, -1):
		if world.get_block(wx, y, wz) == _Const.BLOCK_SAND and world.get_block(wx, y + 1, wz) == _Const.BLOCK_AIR:
			y_top = y
			break
	if y_top < 0:
		return
	var h: int = 0
	var yy: int = y_top
	while yy >= y_lo:
		if world.get_block(wx, yy, wz) != _Const.BLOCK_SAND:
			break
		h += 1
		yy -= 1
	if h <= _Const.SAND_LATERAL_SPILL_STACK_LIMIT:
		return
	var cx: Variant = world.get("chunks_x")
	var cz: Variant = world.get("chunks_z")
	if cx == null or cz == null:
		return
	var max_x: int = int(cx) * _Chunk.SIZE_X
	var max_z: int = int(cz) * _Chunk.SIZE_Z
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	]
	dirs.shuffle()
	var best_py: int = 999999
	var best_nx: int = 0
	var best_nz: int = 0
	var found: bool = false
	for d in dirs:
		var nx: int = wx + d.x
		var nz: int = wz + d.y
		if nx < 1 or nz < 1 or nx >= max_x - 1 or nz >= max_z - 1:
			continue
		if _nest_spill_dest_forbidden(world, nx, nz):
			continue
		var sy: int = world.get_surface_y(nx, nz)
		if sy < 0:
			continue
		var py: int = sy + 1
		if py > y_top:
			continue
		if world.get_block(nx, py, nz) != _Const.BLOCK_AIR:
			continue
		if py < best_py:
			best_py = py
			best_nx = nx
			best_nz = nz
			found = true
	if not found:
		return
	world.set_block(wx, y_top, wz, _Const.BLOCK_AIR)
	world.set_block(best_nx, best_py, best_nz, _Const.BLOCK_SAND)


func _nest_spill_dest_forbidden(world: Node, nx: int, nz: int) -> bool:
	var v: Variant = world.get("nest_spill_exclude_xz")
	if v == null:
		return false
	var c: Vector2i = v as Vector2i
	var r: int = _Const.NEST_SPILL_LATERAL_EXCLUDE_RADIUS
	var dx: int = nx - c.x
	var dz: int = nz - c.y
	return dx * dx + dz * dz <= r * r
