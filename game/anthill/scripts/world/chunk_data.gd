extends RefCounted
class_name VoxelChunk

const SIZE_X := 32
const SIZE_Y := 256
const SIZE_Z := 32

var cx: int
var cz: int
var data: PackedByteArray

func _init(p_cx: int, p_cz: int) -> void:
	cx = p_cx
	cz = p_cz
	data.resize(SIZE_X * SIZE_Y * SIZE_Z)


func _idx(x: int, y: int, z: int) -> int:
	return x + y * SIZE_X + z * SIZE_X * SIZE_Y


func get_b(x: int, y: int, z: int) -> int:
	return data[_idx(x, y, z)]


func set_b(x: int, y: int, z: int, id: int) -> void:
	data.set(_idx(x, y, z), id)
