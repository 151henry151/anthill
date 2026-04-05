extends Node3D
## A food source on the terrain surface: aphid colony (sugar), dead insect (protein), or seed cache (carb).

const _Const := preload("res://scripts/constants.gd")

var food_type: String = "sugar"
var source_type: String = "aphid_colony"
var supply: float = 1.0
var max_supply: float = 1.0
var replenish_rate: float = 0.0
var is_known_to_colony: bool = false
var wx: int = 0
var wz: int = 0


func setup(p_source_type: String, p_wx: int, p_wz: int, surface_y: int) -> void:
	source_type = p_source_type
	wx = p_wx
	wz = p_wz
	match source_type:
		"aphid_colony":
			food_type = "sugar"
			max_supply = 1.0
			supply = 1.0
			replenish_rate = _Const.APHID_REPLENISH_RATE
		"dead_insect":
			food_type = "protein"
			max_supply = 0.6
			supply = 0.6
			replenish_rate = 0.0
		"seed_cache":
			food_type = "sugar"
			max_supply = 0.4
			supply = 0.4
			replenish_rate = 0.0
	position = Vector3(float(wx) + 0.5, float(surface_y) + 1.0, float(wz) + 0.5)
	_build_mesh()


func _build_mesh() -> void:
	match source_type:
		"aphid_colony":
			_build_aphid_mesh()
		"dead_insect":
			_build_insect_mesh()
		"seed_cache":
			_build_seed_mesh()


func _build_aphid_mesh() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.65, 0.78, 0.42)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.3, 0.1)
	var stem := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.15
	cyl.bottom_radius = 0.2
	cyl.height = 3.0
	stem.mesh = cyl
	stem.material_override = mat
	stem.position = Vector3(0, 1.5, 0)
	add_child(stem)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var aphid_mat := StandardMaterial3D.new()
	aphid_mat.albedo_color = Color(0.75, 0.82, 0.5)
	aphid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	aphid_mat.emission_enabled = true
	aphid_mat.emission = Color(0.25, 0.3, 0.12)
	for i in range(rng.randi_range(5, 12)):
		var aphid := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.2
		s.height = 0.35
		aphid.mesh = s
		aphid.material_override = aphid_mat
		aphid.position = Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(0.5, 2.8), rng.randf_range(-0.5, 0.5))
		add_child(aphid)


func _build_insect_mesh() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.15, 0.1)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.08, 0.06, 0.04)
	var body := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.5
	bm.height = 2.5
	body.mesh = bm
	body.material_override = mat
	body.rotation_degrees = Vector3(90, 0, 0)
	body.position = Vector3(0, 0.3, 0)
	add_child(body)
	for i in range(6):
		var leg := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.04
		cyl.bottom_radius = 0.03
		cyl.height = 1.2
		leg.mesh = cyl
		leg.material_override = mat
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var z_off: float = float(i / 2 - 1) * 0.6
		leg.position = Vector3(side * 0.5, 0.15, z_off)
		leg.rotation_degrees = Vector3(20, 0, side * 55)
		add_child(leg)


func _build_seed_mesh() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.78, 0.6)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.25, 0.18)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(rng.randi_range(4, 8)):
		var seed_mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.25
		s.height = 0.4
		seed_mi.mesh = s
		seed_mi.material_override = mat
		seed_mi.position = Vector3(rng.randf_range(-0.8, 0.8), 0.1, rng.randf_range(-0.8, 0.8))
		add_child(seed_mi)


func collect(amount: float) -> float:
	var taken: float = minf(amount, supply)
	supply -= taken
	return taken


func tick() -> void:
	if replenish_rate > 0.0 and supply < max_supply:
		supply = minf(supply + replenish_rate, max_supply)


func is_depleted() -> bool:
	return supply <= 0.001
