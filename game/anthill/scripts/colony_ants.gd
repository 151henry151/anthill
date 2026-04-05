extends Node3D
## Wandering colony ants — procedural segmented bodies (see `colony_ant_model.gd`).

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")
const _AntModelScript = preload("res://scripts/colony_ant_model.gd")

@export var ant_count: int = 72
@export var move_interval: float = 0.45

@onready var world: Node = $"../WorldManager"

var _ants: Array[Dictionary] = []
var _rng: RandomNumberGenerator
var _ant_builder: RefCounted


func _ready() -> void:
	_ant_builder = _AntModelScript.new() as RefCounted
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	for i in ant_count:
		_spawn_one()


func _spawn_one() -> void:
	var max_x: int = world.chunks_x * _Chunk.SIZE_X
	var max_z: int = world.chunks_z * _Chunk.SIZE_Z
	for attempt in range(400):
		var wx: int = _rng.randi_range(2, max_x - 3)
		var wz: int = _rng.randi_range(2, max_z - 3)
		var wy: int = _surface_block_y(wx, wz)
		if wy < 0:
			continue
		var ant: Node3D = _ant_builder.build_ant()
		ant.rotation_degrees.y = _rng.randf_range(0.0, 360.0)
		add_child(ant)
		ant.position = _ant_pos(wx, wy, wz)
		_ants.append({
			"node": ant,
			"wx": wx,
			"wz": wz,
			"t": _rng.randf_range(0.0, move_interval),
		})
		return


func _surface_block_y(wx: int, wz: int) -> int:
	var ceiling: int = mini(_Chunk.SIZE_Y - 2, 240)
	for y in range(ceiling, -1, -1):
		if world.get_block(wx, y, wz) != _Const.BLOCK_AIR and world.get_block(wx, y + 1, wz) == _Const.BLOCK_AIR:
			return y
	return -1


func _ant_pos(wx: int, wy: int, wz: int) -> Vector3:
	# Model origin at sand surface (feet / ground contact).
	return Vector3(float(wx) + 0.5, float(wy) + 1.0, float(wz) + 0.5)


func _physics_process(delta: float) -> void:
	for a in _ants:
		a["t"] = float(a["t"]) + delta
		if float(a["t"]) < move_interval:
			continue
		a["t"] = 0.0
		_step_ant(a)


func _step_ant(a: Dictionary) -> void:
	var wx: int = int(a["wx"])
	var wz: int = int(a["wz"])
	var dx: int = _rng.randi_range(-1, 1)
	var dz: int = _rng.randi_range(-1, 1)
	if dx == 0 and dz == 0:
		dx = 1 if _rng.randf() > 0.5 else -1
	var nwx: int = wx + dx
	var nwz: int = wz + dz
	var max_x: int = world.chunks_x * _Chunk.SIZE_X
	var max_z: int = world.chunks_z * _Chunk.SIZE_Z
	if nwx < 1 or nwz < 1 or nwx >= max_x - 1 or nwz >= max_z - 1:
		return
	var wy: int = _surface_block_y(nwx, nwz)
	if wy < 0:
		return
	a["wx"] = nwx
	a["wz"] = nwz
	var ant: Node3D = a["node"]
	ant.position = _ant_pos(nwx, wy, wz)
	ant.rotation.y = atan2(float(dx), float(dz))
