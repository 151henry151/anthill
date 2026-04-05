extends Node3D

@onready var world: WorldManager = $WorldManager
@onready var chunks_root: Node3D = $Chunks

var _chunk_meshes: Dictionary = {} # Vector2i -> MeshInstance3D
var _mat: StandardMaterial3D


func _ready() -> void:
	_mat = StandardMaterial3D.new()
	_mat.vertex_color_use_as_albedo = true
	_mat.roughness = 0.92
	for cz in range(world.chunks_z):
		for cx in range(world.chunks_x):
			var mi := MeshInstance3D.new()
			mi.material_override = _mat
			chunks_root.add_child(mi)
			mi.position = Vector3.ZERO
			_chunk_meshes[Vector2i(cx, cz)] = mi
	_rebuild_all_meshes()


func _physics_process(_delta: float) -> void:
	SandStep.step(world)
	_rebuild_all_meshes()


func _rebuild_all_meshes() -> void:
	for k in _chunk_meshes:
		var ch: VoxelChunk = world.get_chunk(k.x, k.y)
		if ch == null:
			continue
		var mesh: ArrayMesh = VoxelMeshBuilder.build_chunk_mesh(world, ch)
		var mi: MeshInstance3D = _chunk_meshes[k]
		mi.mesh = mesh
