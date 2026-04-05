extends Node3D
## Renders brood (eggs, larvae, pupae) as instanced meshes inside the nest.

var _brood_manager: Node
var _egg_mesh: SphereMesh
var _larva_mesh: CapsuleMesh
var _pupa_mesh: CapsuleMesh
var _mat_egg: StandardMaterial3D
var _mat_larva: StandardMaterial3D
var _mat_pupa: StandardMaterial3D
var _instances: Array[MeshInstance3D] = []


func setup(brood_manager: Node) -> void:
	_brood_manager = brood_manager
	_brood_manager.brood_changed.connect(_on_brood_changed)
	_setup_meshes()


func _setup_meshes() -> void:
	_egg_mesh = SphereMesh.new()
	_egg_mesh.radius = 0.25
	_egg_mesh.height = 0.4
	_larva_mesh = CapsuleMesh.new()
	_larva_mesh.radius = 0.2
	_larva_mesh.height = 0.7
	_pupa_mesh = CapsuleMesh.new()
	_pupa_mesh.radius = 0.25
	_pupa_mesh.height = 0.9
	_mat_egg = StandardMaterial3D.new()
	_mat_egg.albedo_color = Color(0.95, 0.93, 0.88)
	_mat_egg.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_egg.emission_enabled = true
	_mat_egg.emission = Color(0.4, 0.38, 0.35)
	_mat_larva = StandardMaterial3D.new()
	_mat_larva.albedo_color = Color(0.92, 0.9, 0.82)
	_mat_larva.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_larva.emission_enabled = true
	_mat_larva.emission = Color(0.35, 0.33, 0.28)
	_mat_pupa = StandardMaterial3D.new()
	_mat_pupa.albedo_color = Color(0.88, 0.85, 0.78)
	_mat_pupa.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_pupa.emission_enabled = true
	_mat_pupa.emission = Color(0.3, 0.28, 0.24)


func _on_brood_changed() -> void:
	_rebuild()


func _rebuild() -> void:
	for mi in _instances:
		if is_instance_valid(mi):
			mi.queue_free()
	_instances.clear()
	if _brood_manager == null:
		return
	var brood: Array[Dictionary] = _brood_manager.get_brood()
	for b in brood:
		if bool(b.get("is_trophic", false)):
			continue
		var mi := MeshInstance3D.new()
		var btype: String = b["type"]
		if btype == "egg":
			mi.mesh = _egg_mesh
			mi.material_override = _mat_egg
		elif btype == "larva":
			mi.mesh = _larva_mesh
			mi.material_override = _mat_larva
		elif btype == "pupa":
			mi.mesh = _pupa_mesh
			mi.material_override = _mat_pupa
		mi.position = b["position"] as Vector3
		add_child(mi)
		_instances.append(mi)
