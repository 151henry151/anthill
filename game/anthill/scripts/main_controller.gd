extends Node3D

const _MeshBuilder := preload("res://scripts/world/mesh_builder.gd")
const _SandStepScript = preload("res://scripts/world/sand_step.gd")

## Chunk mesh builds per frame during initial load (spreads GPU/CPU cost; avoids a long freeze after the loading bar).
@export var initial_mesh_chunks_per_frame: int = 10

var _sand_step: RefCounted

@onready var world: Node = $WorldManager
@onready var chunks_root: Node3D = $Chunks

var _chunk_meshes: Dictionary = {} # Vector2i -> MeshInstance3D
var _mat: StandardMaterial3D
var _initial_mesh_keys: Array[Vector2i] = []
var _initial_mesh_idx: int = 0


func _ready() -> void:
	# Instantiate in `_ready` only — field `preload(...).new()` hits `GDScript` without `.new()` in 4.2.
	_sand_step = _SandStepScript.new() as RefCounted
	_mat = StandardMaterial3D.new()
	_mat.vertex_color_use_as_albedo = true
	_mat.roughness = 0.88
	_mat.metallic = 0.0
	for cz in range(world.chunks_z):
		for cx in range(world.chunks_x):
			var mi := MeshInstance3D.new()
			mi.material_override = _mat
			chunks_root.add_child(mi)
			mi.position = Vector3.ZERO
			_chunk_meshes[Vector2i(cx, cz)] = mi
	for k in _chunk_meshes:
		_initial_mesh_keys.append(k)
	set_process(true)


func _process(_delta: float) -> void:
	if _initial_mesh_idx < _initial_mesh_keys.size():
		var n: int = maxi(1, initial_mesh_chunks_per_frame)
		var end_i: int = mini(_initial_mesh_idx + n, _initial_mesh_keys.size())
		for i in range(_initial_mesh_idx, end_i):
			_rebuild_chunk_mesh(_initial_mesh_keys[i])
		_initial_mesh_idx = end_i
		return
	set_process(false)


func _physics_process(_delta: float) -> void:
	if _sand_step != null and not world.sand_idle:
		_sand_step.step(world)
	if world.take_mesh_dirty():
		for ck in world.get_and_clear_dirty_chunks():
			_rebuild_chunk_mesh(ck)


func _rebuild_chunk_mesh(k: Vector2i) -> void:
	var ch = world.get_chunk(k.x, k.y)
	if ch == null:
		return
	var mi: MeshInstance3D = _chunk_meshes.get(k)
	if mi == null:
		return
	var mesh: ArrayMesh = _MeshBuilder.build_chunk_mesh(world, ch)
	mi.mesh = mesh
