extends Node
class_name WorldManager

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")
const _TerrainGen := preload("res://scripts/world/terrain_gen.gd")

var _chunks: Dictionary = {}
var _noise: FastNoiseLite
var _mesh_dirty: bool = false
var _dirty_chunks: Dictionary = {}
## Columns (world XZ) that may contain falling sand this physics tick — avoids scanning 544×544 every frame.
var _sand_columns: Dictionary = {}
## After falling sand settles, `SandStep` skips work (pending columns empty).
var sand_idle: bool = false
## Surface-Y cache: maps Vector2i(wx, wz) → int (topmost non-air Y). -1 = not cached.
var _surface_cache: Dictionary = {}

## ~sqrt(30)× prior 3×3 extent → ~30× horizontal cells; 17×32 = 544 units per side.
@export var chunks_x: int = 17
@export var chunks_z: int = 17


func _ready() -> void:
	_init_bounds()
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.frequency = 1.0
	for cz in range(chunks_z):
		for cx in range(chunks_x):
			var ch = _Chunk.new(cx, cz)
			_TerrainGen.fill_chunk(ch, _noise)
			_chunks[Vector2i(cx, cz)] = ch
	sand_idle = true


func get_chunk(cx: int, cz: int) -> Variant:
	return _chunks.get(Vector2i(cx, cz), null)


## SIZE_X and SIZE_Z are both 32 — use bit shifts for chunk coordinate math.
const _SHIFT_X := 5  # log2(32)
const _MASK_X := 31  # 32 - 1
const _SHIFT_Z := 5
const _MASK_Z := 31

var _max_wx: int = 0
var _max_wz: int = 0


func _init_bounds() -> void:
	_max_wx = chunks_x << _SHIFT_X
	_max_wz = chunks_z << _SHIFT_Z


func get_block(wx: int, wy: int, wz: int) -> int:
	if wy < 0:
		return _Const.BLOCK_STONE
	if wy >= _Chunk.SIZE_Y:
		return _Const.BLOCK_AIR
	if wx < 0 or wz < 0 or wx >= _max_wx or wz >= _max_wz:
		return _Const.BLOCK_AIR
	var cx: int = wx >> _SHIFT_X
	var cz: int = wz >> _SHIFT_Z
	var ch = _chunks.get(Vector2i(cx, cz))
	if ch == null:
		return _Const.BLOCK_AIR
	return ch.data[(wx & _MASK_X) + wy * _Chunk.SIZE_X + (wz & _MASK_Z) * _Chunk.SIZE_X * _Chunk.SIZE_Y]


func set_block(wx: int, wy: int, wz: int, id: int) -> void:
	if wy < 0 or wy >= _Chunk.SIZE_Y:
		return
	if wx < 0 or wz < 0 or wx >= _max_wx or wz >= _max_wz:
		return
	var cx: int = wx >> _SHIFT_X
	var cz: int = wz >> _SHIFT_Z
	var ck := Vector2i(cx, cz)
	var ch = _chunks.get(ck)
	if ch == null:
		return
	var idx: int = (wx & _MASK_X) + wy * _Chunk.SIZE_X + (wz & _MASK_Z) * _Chunk.SIZE_X * _Chunk.SIZE_Y
	if ch.data[idx] == id:
		return
	ch.data.set(idx, id)
	_mesh_dirty = true
	_dirty_chunks[ck] = true
	_surface_cache.erase(Vector2i(wx, wz))
	if id == _Const.BLOCK_SAND or id == _Const.BLOCK_AIR:
		sand_idle = false
		_mark_sand_column_wx_wz(wx, wz)


## Clears the flag; call once per frame after stepping sand to decide whether to rebuild meshes.
func take_mesh_dirty() -> bool:
	var was: bool = _mesh_dirty
	_mesh_dirty = false
	return was


func get_and_clear_dirty_chunks() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for k in _dirty_chunks:
		out.append(k)
	_dirty_chunks.clear()
	return out


func _mark_sand_column_wx_wz(wx: int, wz: int) -> void:
	var max_wx: int = chunks_x * _Chunk.SIZE_X
	var max_wz: int = chunks_z * _Chunk.SIZE_Z
	if wx < 0 or wz < 0 or wx >= max_wx or wz >= max_wz:
		return
	_sand_columns[Vector2i(wx, wz)] = true


## Pops up to **`max_columns`** keys; remaining keys stay for the next tick (keeps one physics frame from scanning the whole map).
func take_sand_columns(max_columns: int = 65536) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for k in _sand_columns:
		if out.size() >= max_columns:
			break
		out.append(k)
	for item in out:
		_sand_columns.erase(item)
	return out


func get_surface_y(wx: int, wz: int) -> int:
	var key := Vector2i(wx, wz)
	if _surface_cache.has(key):
		return int(_surface_cache[key])
	var ceiling: int = mini(_Chunk.SIZE_Y - 2, _TerrainGen.SURFACE_BASE + 28)
	var floor_y: int = maxi(1, _TerrainGen.SURFACE_BASE - 80)
	for y in range(ceiling, floor_y - 1, -1):
		if get_block(wx, y, wz) != _Const.BLOCK_AIR and get_block(wx, y + 1, wz) == _Const.BLOCK_AIR:
			_surface_cache[key] = y
			return y
	for y in range(floor_y - 1, -1, -1):
		if get_block(wx, y, wz) != _Const.BLOCK_AIR and get_block(wx, y + 1, wz) == _Const.BLOCK_AIR:
			_surface_cache[key] = y
			return y
	_surface_cache[key] = -1
	return -1


func debug_sand_column_count() -> int:
	return _sand_columns.size()


func debug_surface_cache_size() -> int:
	return _surface_cache.size()


func world_bounds_aabb() -> AABB:
	var max_x: int = chunks_x * _Chunk.SIZE_X
	var max_z: int = chunks_z * _Chunk.SIZE_Z
	return AABB(Vector3.ZERO, Vector3(max_x, _Chunk.SIZE_Y, max_z))
