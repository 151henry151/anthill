extends Node
class_name WorldManager

var _chunks: Dictionary = {}
var _noise: FastNoiseLite

@export var chunks_x: int = 3
@export var chunks_z: int = 3


func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.frequency = 1.0
	for cz in range(chunks_z):
		for cx in range(chunks_x):
			var ch := VoxelChunk.new(cx, cz)
			TerrainGen.fill_chunk(ch, _noise)
			_chunks[Vector2i(cx, cz)] = ch


func get_chunk(cx: int, cz: int) -> VoxelChunk:
	return _chunks.get(Vector2i(cx, cz), null)


func get_block(wx: int, wy: int, wz: int) -> int:
	if wy < 0:
		return GameConstants.BLOCK_STONE
	if wy >= VoxelChunk.SIZE_Y:
		return GameConstants.BLOCK_AIR
	var sx := VoxelChunk.SIZE_X
	var sz := VoxelChunk.SIZE_Z
	var max_wx := chunks_x * sx
	var max_wz := chunks_z * sz
	if wx < 0 or wz < 0 or wx >= max_wx or wz >= max_wz:
		return GameConstants.BLOCK_AIR
	var cx := wx // sx
	var cz := wz // sz
	var lx := wx % sx
	var lz := wz % sz
	var ch: VoxelChunk = _chunks[Vector2i(cx, cz)]
	return ch.get_b(lx, wy, lz)


func set_block(wx: int, wy: int, wz: int, id: int) -> void:
	if wy < 0 or wy >= VoxelChunk.SIZE_Y:
		return
	var sx := VoxelChunk.SIZE_X
	var sz := VoxelChunk.SIZE_Z
	var max_wx := chunks_x * sx
	var max_wz := chunks_z * sz
	if wx < 0 or wz < 0 or wx >= max_wx or wz >= max_wz:
		return
	var cx := wx // sx
	var cz := wz // sz
	var lx := wx % sx
	var lz := wz % sz
	var ch: VoxelChunk = _chunks[Vector2i(cx, cz)]
	ch.set_b(lx, wy, lz, id)


func world_bounds_aabb() -> AABB:
	var max_x := chunks_x * VoxelChunk.SIZE_X
	var max_z := chunks_z * VoxelChunk.SIZE_Z
	return AABB(Vector3.ZERO, Vector3(max_x, VoxelChunk.SIZE_Y, max_z))
