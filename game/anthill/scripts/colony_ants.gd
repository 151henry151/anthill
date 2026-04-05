extends Node3D
## Simple wandering markers for colony view (not the FPS `ant.tscn` prototype).

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")

@export var ant_count: int = 16
@export var move_interval: float = 0.45
## World units — stylized “giants” so they read at ortho zoom (~4 px/voxel).
@export var ant_body_size: Vector3 = Vector3(5.0, 3.0, 6.0)

@onready var world: Node = $"../WorldManager"

var _ants: Array[Dictionary] = []
var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	for i in ant_count:
		_spawn_one()


func _spawn_one() -> void:
	var max_x: int = world.chunks_x * _Chunk.SIZE_X
	var max_z: int = world.chunks_z * _Chunk.SIZE_Z
	for attempt in range(100):
		var wx: int = _rng.randi_range(2, max_x - 3)
		var wz: int = _rng.randi_range(2, max_z - 3)
		var wy: int = _surface_block_y(wx, wz)
		if wy < 0:
			continue
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = ant_body_size
		mi.mesh = box
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.62, 0.14, 0.09)
		mat.emission_enabled = true
		mat.emission = Color(0.12, 0.03, 0.02)
		mi.material_override = mat
		add_child(mi)
		mi.position = _ant_pos(wx, wy, wz)
		_ants.append({
			"node": mi,
			"wx": wx,
			"wz": wz,
			"t": _rng.randf_range(0.0, move_interval),
		})
		return


func _surface_block_y(wx: int, wz: int) -> int:
	for y in range(_Chunk.SIZE_Y - 2, -1, -1):
		if world.get_block(wx, y, wz) != _Const.BLOCK_AIR and world.get_block(wx, y + 1, wz) == _Const.BLOCK_AIR:
			return y
	return -1


func _ant_pos(wx: int, wy: int, wz: int) -> Vector3:
	# Surface at y = wy + 1; place box so its bottom sits on that plane.
	var half_h: float = ant_body_size.y * 0.5
	return Vector3(float(wx) + 0.5, float(wy) + 1.0 + half_h, float(wz) + 0.5)


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
	var mi: MeshInstance3D = a["node"]
	mi.position = _ant_pos(nwx, wy, nwz)
