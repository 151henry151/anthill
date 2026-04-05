extends Node
class_name WorldManager

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")
const _TerrainGen := preload("res://scripts/world/terrain_gen.gd")

var _chunks: Dictionary = {}
var _noise: FastNoiseLite
var _mesh_dirty: bool = false
## After falling sand settles, `SandStep` skips the full-world scan (major CPU save).
var sand_idle: bool = false

@export var chunks_x: int = 3
@export var chunks_z: int = 3


func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.frequency = 1.0
	for cz in range(chunks_z):
		for cx in range(chunks_x):
			var ch = _Chunk.new(cx, cz)
			_TerrainGen.fill_chunk(ch, _noise)
			_chunks[Vector2i(cx, cz)] = ch


func get_chunk(cx: int, cz: int) -> Variant:
	return _chunks.get(Vector2i(cx, cz), null)


func get_block(wx: int, wy: int, wz: int) -> int:
	if wy < 0:
		return _Const.BLOCK_STONE
	if wy >= _Chunk.SIZE_Y:
		return _Const.BLOCK_AIR
	var sx: int = _Chunk.SIZE_X
	var sz: int = _Chunk.SIZE_Z
	var max_wx: int = chunks_x * sx
	var max_wz: int = chunks_z * sz
	if wx < 0 or wz < 0 or wx >= max_wx or wz >= max_wz:
		return _Const.BLOCK_AIR
	var cx: int = int(floor(float(wx) / float(sx)))
	var cz: int = int(floor(float(wz) / float(sz)))
	var lx: int = wx % sx
	var lz: int = wz % sz
	var ch = _chunks[Vector2i(cx, cz)]
	return ch.get_b(lx, wy, lz)


func set_block(wx: int, wy: int, wz: int, id: int) -> void:
	if wy < 0 or wy >= _Chunk.SIZE_Y:
		return
	var sx: int = _Chunk.SIZE_X
	var sz: int = _Chunk.SIZE_Z
	var max_wx: int = chunks_x * sx
	var max_wz: int = chunks_z * sz
	if wx < 0 or wz < 0 or wx >= max_wx or wz >= max_wz:
		return
	var cx: int = int(floor(float(wx) / float(sx)))
	var cz: int = int(floor(float(wz) / float(sz)))
	var lx: int = wx % sx
	var lz: int = wz % sz
	var ch = _chunks[Vector2i(cx, cz)]
	ch.set_b(lx, wy, lz, id)
	_mesh_dirty = true
	sand_idle = false


## Clears the flag; call once per frame after stepping sand to decide whether to rebuild meshes.
func take_mesh_dirty() -> bool:
	var was: bool = _mesh_dirty
	_mesh_dirty = false
	return was


func world_bounds_aabb() -> AABB:
	var max_x: int = chunks_x * _Chunk.SIZE_X
	var max_z: int = chunks_z * _Chunk.SIZE_Z
	return AABB(Vector3.ZERO, Vector3(max_x, _Chunk.SIZE_Y, max_z))
