extends Node3D
## Surface food patch: sugar (aphid / seed) or protein (carcass). Finite supply, **spoils** over time, visuals scale with remaining food.

const _Const := preload("res://scripts/constants.gd")

var food_type: String = "sugar"
## For carbohydrate sources: modeled **sucrose molarity** (0.1–1.0 M fiction) for trail strength scaling.
var sucrose_molarity: float = 0.55
var source_type: String = "aphid_colony"
## Current collectible amount (colony store units).
var supply: float = 1.0
## Supply at spawn; used for scaling, spoil rate, and spoil tint.
var max_supply_initial: float = 1.0
var is_known_to_colony: bool = false
var wx: int = 0
var wz: int = 0

var _visual_root: Node3D
var _materials: Array[StandardMaterial3D] = []
var _base_colors: Array[Color] = []
var _base_emissions: Array[Color] = []
var _base_scale: float = 1.0
var _rot_per_tick: float = 0.0
var _spoil_end_tick: int = 0


func setup(p_source_type: String, p_wx: int, p_wz: int, surface_y: int, rng: RandomNumberGenerator) -> void:
	source_type = p_source_type
	wx = p_wx
	wz = p_wz
	match source_type:
		"aphid_colony":
			food_type = "sugar"
			max_supply_initial = rng.randf_range(_Const.FOOD_APHID_SUPPLY_MIN, _Const.FOOD_APHID_SUPPLY_MAX)
			sucrose_molarity = rng.randf_range(0.1, 1.0)
		"dead_insect":
			food_type = "protein"
			max_supply_initial = rng.randf_range(_Const.FOOD_INSECT_SUPPLY_MIN, _Const.FOOD_INSECT_SUPPLY_MAX)
			sucrose_molarity = 0.0
		"seed_cache":
			food_type = "sugar"
			max_supply_initial = rng.randf_range(_Const.FOOD_SEED_SUPPLY_MIN, _Const.FOOD_SEED_SUPPLY_MAX)
			sucrose_molarity = rng.randf_range(0.1, 1.0)
		_:
			food_type = "sugar"
			max_supply_initial = 0.5
			sucrose_molarity = rng.randf_range(0.1, 1.0)
	supply = max_supply_initial
	position = Vector3(float(wx) + 0.5, float(surface_y) + 1.0, float(wz) + 0.5)
	_visual_root = Node3D.new()
	add_child(_visual_root)
	_base_scale = rng.randf_range(_Const.FOOD_VISUAL_BASE_SCALE_MIN, _Const.FOOD_VISUAL_BASE_SCALE_MAX)
	_build_mesh(rng)
	_refresh_visual()


## Sets rot rate and hard spoil deadline; call right after **`setup`** with the current **`_game_tick`**.
func begin_life(spawn_tick: int, spoil_duration_ticks: int) -> void:
	var d: int = maxi(1, spoil_duration_ticks)
	_rot_per_tick = max_supply_initial / float(d)
	_spoil_end_tick = spawn_tick + d


func _build_mesh(rng: RandomNumberGenerator) -> void:
	_materials.clear()
	_base_colors.clear()
	_base_emissions.clear()
	match source_type:
		"aphid_colony":
			_build_aphid_mesh(rng)
		"dead_insect":
			_build_insect_mesh()
		"seed_cache":
			_build_seed_mesh(rng)


func _reg_mat(albedo: Color, emission: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = emission
	_materials.append(mat)
	_base_colors.append(albedo)
	_base_emissions.append(emission)
	return mat


func _build_aphid_mesh(rng: RandomNumberGenerator) -> void:
	var stem_mat := _reg_mat(Color(0.65, 0.78, 0.42), Color(0.2, 0.3, 0.1))
	var stem := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.15
	cyl.bottom_radius = 0.2
	cyl.height = 3.0
	stem.mesh = cyl
	stem.material_override = stem_mat
	stem.position = Vector3(0, 1.5, 0)
	_visual_root.add_child(stem)
	var aphid_mat := _reg_mat(Color(0.75, 0.82, 0.5), Color(0.25, 0.3, 0.12))
	var n_aphids: int = rng.randi_range(5, 12)
	for i in range(n_aphids):
		var aphid := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.2
		s.height = 0.35
		aphid.mesh = s
		aphid.material_override = aphid_mat
		aphid.position = Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(0.5, 2.8), rng.randf_range(-0.5, 0.5))
		_visual_root.add_child(aphid)


func _build_insect_mesh() -> void:
	var mat := _reg_mat(Color(0.2, 0.15, 0.1), Color(0.08, 0.06, 0.04))
	var body := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.5
	bm.height = 2.5
	body.mesh = bm
	body.material_override = mat
	body.rotation_degrees = Vector3(90, 0, 0)
	body.position = Vector3(0, 0.3, 0)
	_visual_root.add_child(body)
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
		_visual_root.add_child(leg)


func _build_seed_mesh(rng: RandomNumberGenerator) -> void:
	var mat := _reg_mat(Color(0.85, 0.78, 0.6), Color(0.3, 0.25, 0.18))
	var n_seeds: int = rng.randi_range(4, 8)
	for i in range(n_seeds):
		var seed_mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.25
		s.height = 0.4
		seed_mi.mesh = s
		seed_mi.material_override = mat
		seed_mi.position = Vector3(rng.randf_range(-0.8, 0.8), 0.1, rng.randf_range(-0.8, 0.8))
		_visual_root.add_child(seed_mi)


func collect(amount: float) -> float:
	var taken: float = minf(amount, supply)
	supply -= taken
	_refresh_visual()
	return taken


func tick(game_tick: int) -> void:
	if max_supply_initial <= 0.001:
		return
	supply -= _rot_per_tick
	if game_tick >= _spoil_end_tick:
		supply = 0.0
	supply = maxf(supply, 0.0)
	_refresh_visual()


func _refresh_visual() -> void:
	if _visual_root == null:
		return
	var ratio: float = 0.0
	if max_supply_initial > 0.0001:
		ratio = clampf(supply / max_supply_initial, 0.0, 1.0)
	var size_mix: float = sqrt(ratio)
	var s: float = _base_scale * lerpf(_Const.FOOD_VISUAL_MIN_SCALE_RATIO, 1.0, size_mix)
	_visual_root.scale = Vector3(s, s, s)
	var spoil_t: float = 1.0 - ratio
	var spoil_color := Color(0.42, 0.32, 0.22)
	var dim: float = lerpf(0.22, 1.0, ratio)
	for i in range(_materials.size()):
		var m: StandardMaterial3D = _materials[i]
		var base: Color = _base_colors[i]
		m.albedo_color = base.lerp(spoil_color, spoil_t * 0.62)
		m.emission = _base_emissions[i] * dim


func is_depleted() -> bool:
	return supply <= 0.001


## Relative reward quality for recruitment trail scaling (sugar → molarity; protein → fixed).
func get_reward_quality() -> float:
	if food_type == "protein":
		return 0.65
	return clampf(sucrose_molarity, 0.08, 1.0)
