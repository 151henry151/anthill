extends Node3D

const _SandStep := preload("res://scripts/world/sand_step.gd")
const _MeshBuilder := preload("res://scripts/world/mesh_builder.gd")
const _TerrainShader := preload("res://shaders/terrain_unshaded.gdshader")

@onready var world: Node = $WorldManager
@onready var chunks_root: Node3D = $Chunks

var _chunk_meshes: Dictionary = {} # Vector2i -> MeshInstance3D
var _mat: ShaderMaterial


func _ready() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = _TerrainShader
	for cz in range(world.chunks_z):
		for cx in range(world.chunks_x):
			var mi := MeshInstance3D.new()
			mi.material_override = _mat
			chunks_root.add_child(mi)
			mi.position = Vector3.ZERO
			_chunk_meshes[Vector2i(cx, cz)] = mi
	_rebuild_all_meshes()


func _physics_process(_delta: float) -> void:
	_SandStep.step(world)
	_rebuild_all_meshes()


func _rebuild_all_meshes() -> void:
	for k in _chunk_meshes:
		var ch = world.get_chunk(k.x, k.y)
		if ch == null:
			continue
		var mesh: ArrayMesh = _MeshBuilder.build_chunk_mesh(world, ch)
		var mi: MeshInstance3D = _chunk_meshes[k]
		mi.mesh = mesh
