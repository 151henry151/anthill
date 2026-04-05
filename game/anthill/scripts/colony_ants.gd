extends Node3D
## Worker ants with task-based state machine. Spawns new workers from brood eclosion.

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")
const _AntModelScript = preload("res://scripts/colony_ant_model.gd")
const _TerrainGen := preload("res://scripts/world/terrain_gen.gd")
const _SurfaceQuery := preload("res://scripts/world/surface_query.gd")

@export var move_interval: float = _Const.WORKER_MOVE_INTERVAL
const _ANT_LOCAL_Y_MIN: float = -0.28

@onready var world: Node = $"../WorldManager"

var _ants: Array[Dictionary] = []
var _rng: RandomNumberGenerator
var _ant_builder: RefCounted
## External references set by main_controller.
var pheromone_field: Node
var food_store: Node
var food_sources: Array[Node3D] = []
var nest_entrance: Vector3i = Vector3i.ZERO
var nest_chamber: Vector3i = Vector3i.ZERO
var nest_manager: Node
var building_pheromone: Node
## Task assignment tick counter.
var _task_assign_timer: int = 0
const _TASK_ASSIGN_INTERVAL := 300
## Extended states: 11=DIGGING_APPROACH 12=DIGGING_ACT 13=CARRYING_TO_SURFACE 14=DEPOSITING
var _digger_count: int = 0


func _ready() -> void:
	_ant_builder = _AntModelScript.new() as RefCounted
	_rng = RandomNumberGenerator.new()
	_rng.randomize()


func spawn_worker(pos: Vector3, is_nanitic: bool) -> void:
	var ant: Node3D = _ant_builder.build_ant()
	var sc: float = _Const.NANITIC_VISUAL_SCALE if is_nanitic else _Const.WORKER_VISUAL_SCALE
	ant.scale = Vector3.ONE * sc
	ant.rotation_degrees.y = _rng.randf_range(0.0, 360.0)
	add_child(ant)
	var sy: int = _surface_y(int(pos.x), int(pos.z))
	if sy < 0:
		sy = _TerrainGen.SURFACE_BASE
	ant.position = _ant_pos(int(pos.x), sy, int(pos.z), sc)
	var state: int = 0  # EMERGING
	var carry_vis := MeshInstance3D.new()
	var carry_mesh := BoxMesh.new()
	carry_mesh.size = Vector3(0.25, 0.25, 0.25)
	carry_vis.mesh = carry_mesh
	var carry_mat := StandardMaterial3D.new()
	carry_mat.albedo_color = Color(0.92, 0.82, 0.62)
	carry_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	carry_vis.material_override = carry_mat
	carry_vis.position = Vector3(0, 0.4, 0.3)
	carry_vis.visible = false
	ant.add_child(carry_vis)
	_ants.append({
		"node": ant,
		"wx": int(pos.x),
		"wz": int(pos.z),
		"t": 0.0,
		"state": state,
		"age_ticks": 0,
		"carrying_food": false,
		"food_type": "",
		"target_food": -1,
		"is_nanitic": is_nanitic,
		"scale": sc,
		"callow_ticks": 0,
		"carrying_voxel": false,
		"dig_target": Vector3i.ZERO,
		"dig_ticks": 0,
		"carry_visual": carry_vis,
		"path_to_surface": [] as Array[Vector3i],
		"path_idx": 0,
	})


func _surface_y(wx: int, wz: int) -> int:
	return world.get_surface_y(wx, wz)


func _ant_pos(wx: int, wy: int, wz: int, sc: float) -> Vector3:
	var surface_top: float = float(wy) + 1.0
	var y: float = surface_top - _ANT_LOCAL_Y_MIN * sc
	return Vector3(float(wx) + 0.5, y, float(wz) + 0.5)


func _physics_process(delta: float) -> void:
	_task_assign_timer += 1
	if _task_assign_timer >= _TASK_ASSIGN_INTERVAL:
		_task_assign_timer = 0
		_assign_tasks()
	for a in _ants:
		a["age_ticks"] = int(a["age_ticks"]) + 1
		a["t"] = float(a["t"]) + delta
		if float(a["t"]) < move_interval:
			continue
		a["t"] = 0.0
		_step_ant(a)


func _assign_tasks() -> void:
	_digger_count = 0
	for a in _ants:
		var st: int = int(a["state"])
		if st >= 11 and st <= 14:
			_digger_count += 1
	var need_diggers: bool = false
	if nest_manager:
		var vol: int = nest_manager.get_nest_air_volume()
		var target: int = _ants.size() * _Const.VOLUME_PER_WORKER
		need_diggers = vol < target and _digger_count < _Const.MAX_NEST_BUILDERS
	var young_idle: Array[Dictionary] = []
	var old_idle: Array[Dictionary] = []
	for a in _ants:
		var st: int = int(a["state"])
		var age: int = int(a["age_ticks"])
		if st == 0 or st == 1:
			if age < _Const.YOUNG_WORKER_AGE_THRESHOLD:
				young_idle.append(a)
			else:
				old_idle.append(a)
		elif st == 2 and age >= _Const.YOUNG_WORKER_AGE_THRESHOLD:
			# Brood-care workers past the “young” window must be eligible for foraging / dig / rest.
			old_idle.append(a)
	for a in young_idle:
		a["state"] = 2  # BROOD_CARE
	for a in old_idle:
		if need_diggers and _digger_count < _Const.MAX_NEST_BUILDERS and _rng.randf() < 0.5:
			a["state"] = 11  # DIGGING_APPROACH
			_digger_count += 1
		elif _rng.randf() < 0.6:
			a["state"] = 4  # FORAGING_DEPART
		else:
			a["state"] = 1  # RESTING


## State indices: 0=EMERGING 1=RESTING 2=BROOD_CARE 3=NEST_BUILDING
## 4=FORAGING_DEPART 5=FORAGING_SCOUT 6=FORAGING_RECRUIT 7=RETURNING
## 8=TROPHALLAXIS 9=ATTENDING_QUEEN 10=DEFENDING
func _step_ant(a: Dictionary) -> void:
	var st: int = int(a["state"])
	match st:
		0:
			_step_emerging(a)
		1:
			_step_resting(a)
		2:
			_step_brood_care(a)
		3:
			_step_nest_building(a)
		4:
			_step_foraging_depart(a)
		5:
			_step_foraging_scout(a)
		6:
			_step_foraging_recruit(a)
		7:
			_step_returning(a)
		8:
			_step_trophallaxis(a)
		11:
			_step_digging_approach(a)
		12:
			_step_digging_act(a)
		13:
			_step_carrying_to_surface(a)
		14:
			_step_depositing(a)
		_:
			_step_random_walk(a)


func _step_emerging(a: Dictionary) -> void:
	a["callow_ticks"] = int(a.get("callow_ticks", 0)) + 1
	if int(a["callow_ticks"]) > 90:
		a["state"] = 1
	_step_random_walk(a)


func _step_resting(_a: Dictionary) -> void:
	pass


func _step_brood_care(a: Dictionary) -> void:
	_move_toward(a, nest_chamber)


func _step_nest_building(a: Dictionary) -> void:
	a["state"] = 11  # Redirect to digging approach


func _step_foraging_depart(a: Dictionary) -> void:
	_move_away_from(a, nest_entrance)
	if _dist_to(a, nest_entrance) > 30:
		a["state"] = 5  # FORAGING_SCOUT


func _step_foraging_scout(a: Dictionary) -> void:
	_step_random_walk(a)
	_check_food_nearby(a)


func _step_foraging_recruit(a: Dictionary) -> void:
	if pheromone_field == null:
		_step_random_walk(a)
		_check_food_nearby(a)
		return
	var wx: int = int(a["wx"])
	var wz: int = int(a["wz"])
	var heading: float = (a["node"] as Node3D).rotation.y
	var samples: Array[float] = pheromone_field.sample_directional(wx, wz, heading)
	var best_idx: int = 0
	var best_val: float = samples[0]
	for i in range(1, samples.size()):
		if samples[i] > best_val:
			best_val = samples[i]
			best_idx = i
	var angle_off: float = (float(best_idx) - 1.0) * 0.5
	var move_angle: float = heading + angle_off + _rng.randf_range(-0.2, 0.2)
	var dx: int = int(round(sin(move_angle)))
	var dz: int = int(round(cos(move_angle)))
	_try_move(a, dx, dz)
	_check_food_nearby(a)


func _step_returning(a: Dictionary) -> void:
	_move_toward(a, nest_entrance)
	if _dist_to(a, nest_entrance) < 3:
		if food_store and bool(a.get("carrying_food", false)):
			food_store.add_food(String(a["food_type"]), _Const.FOOD_CARRY_AMOUNT)
		a["carrying_food"] = false
		a["food_type"] = ""
		a["state"] = 8  # TROPHALLAXIS


func _step_trophallaxis(a: Dictionary) -> void:
	a["state"] = 1  # RESTING (simplified)


func _step_digging_approach(a: Dictionary) -> void:
	if nest_manager == null:
		a["state"] = 1
		return
	var target: Variant = a.get("dig_target", Vector3i.ZERO) as Vector3i
	if target == Vector3i.ZERO:
		var t: Variant = nest_manager.get_dig_target(a["node"])
		if t == null:
			a["state"] = 1
			return
		target = t as Vector3i
		a["dig_target"] = target
		nest_manager.reserve_voxel(target, a["node"])
	_move_toward(a, target)
	if _dist_to(a, target) < 2.0:
		a["state"] = 12
		a["dig_ticks"] = 0


func _step_digging_act(a: Dictionary) -> void:
	var target: Vector3i = a["dig_target"] as Vector3i
	var bt: int = world.get_block(target.x, target.y, target.z)
	if bt == _Const.BLOCK_AIR:
		nest_manager.release_voxel(target)
		a["dig_target"] = Vector3i.ZERO
		a["state"] = 11
		return
	var duration: int = nest_manager.dig_duration_for(bt)
	a["dig_ticks"] = int(a["dig_ticks"]) + 1
	if int(a["dig_ticks"]) >= duration:
		world.set_block(target.x, target.y, target.z, _Const.BLOCK_AIR)
		nest_manager.on_voxel_removed(target)
		nest_manager.release_voxel(target)
		a["carrying_voxel"] = true
		a["dig_target"] = Vector3i.ZERO
		var cv: MeshInstance3D = a.get("carry_visual") as MeshInstance3D
		if cv:
			cv.visible = true
		a["path_to_surface"] = nest_manager.get_path_to_surface(target)
		a["path_idx"] = 0
		a["state"] = 13


func _step_carrying_to_surface(a: Dictionary) -> void:
	var path: Array = a.get("path_to_surface", []) as Array
	var idx: int = int(a.get("path_idx", 0))
	if idx >= path.size():
		a["state"] = 14
		return
	var next_pos: Vector3i = path[idx] as Vector3i
	a["wx"] = next_pos.x
	a["wz"] = next_pos.z
	var ant: Node3D = a["node"]
	var sc: float = float(a.get("scale", _Const.WORKER_VISUAL_SCALE))
	ant.position = Vector3(float(next_pos.x) + 0.5, float(next_pos.y) + 0.5, float(next_pos.z) + 0.5)
	a["path_idx"] = idx + 1
	if idx + 1 >= path.size():
		a["state"] = 14


func _step_depositing(a: Dictionary) -> void:
	if not bool(a.get("carrying_voxel", false)):
		a["state"] = 1
		return
	var deposit_pos: Vector3i = nest_manager.choose_deposit_position(nest_entrance)
	world.set_block(deposit_pos.x, deposit_pos.y, deposit_pos.z, _Const.BLOCK_SAND)
	if building_pheromone:
		building_pheromone.add_build_pheromone(deposit_pos, _Const.BUILD_PHEROMONE_DEPOSIT_AMOUNT)
	nest_manager.on_voxel_placed(deposit_pos)
	a["carrying_voxel"] = false
	var cv: MeshInstance3D = a.get("carry_visual") as MeshInstance3D
	if cv:
		cv.visible = false
	var sy: int = _surface_y(int(a["wx"]), int(a["wz"]))
	if sy >= 0:
		var ant: Node3D = a["node"]
		var sc: float = float(a.get("scale", _Const.WORKER_VISUAL_SCALE))
		ant.position = _ant_pos(int(a["wx"]), sy, int(a["wz"]), sc)
	a["state"] = 11


func _check_food_nearby(a: Dictionary) -> void:
	var wx: int = int(a["wx"])
	var wz: int = int(a["wz"])
	for i in range(food_sources.size()):
		var fs: Node3D = food_sources[i]
		if not is_instance_valid(fs):
			continue
		if fs.is_depleted():
			continue
		var dx: int = absi(fs.wx - wx)
		var dz: int = absi(fs.wz - wz)
		if dx <= 2 and dz <= 2:
			var taken: float = fs.collect(_Const.FOOD_CARRY_AMOUNT)
			if taken > 0.0:
				a["carrying_food"] = true
				a["food_type"] = fs.food_type
				fs.is_known_to_colony = true
				a["state"] = 7  # RETURNING
				if pheromone_field:
					pheromone_field.deposit(wx, wz, _Const.PHEROMONE_DEPOSIT_AMOUNT)
			return


func _move_toward(a: Dictionary, target: Vector3i) -> void:
	var wx: int = int(a["wx"])
	var wz: int = int(a["wz"])
	var dx: int = signi(target.x - wx)
	var dz: int = signi(target.z - wz)
	if dx == 0 and dz == 0:
		return
	if _rng.randf() < 0.2:
		dx += _rng.randi_range(-1, 1)
		dz += _rng.randi_range(-1, 1)
		dx = clampi(dx, -1, 1)
		dz = clampi(dz, -1, 1)
	_try_move(a, dx, dz)


func _move_away_from(a: Dictionary, target: Vector3i) -> void:
	var wx: int = int(a["wx"])
	var wz: int = int(a["wz"])
	var dx: int = signi(wx - target.x)
	var dz: int = signi(wz - target.z)
	if dx == 0 and dz == 0:
		dx = 1 if _rng.randf() > 0.5 else -1
	if _rng.randf() < 0.3:
		dx += _rng.randi_range(-1, 1)
		dz += _rng.randi_range(-1, 1)
		dx = clampi(dx, -1, 1)
		dz = clampi(dz, -1, 1)
	_try_move(a, dx, dz)


func _dist_to(a: Dictionary, target: Vector3i) -> float:
	var dx: float = float(int(a["wx"]) - target.x)
	var dz: float = float(int(a["wz"]) - target.z)
	return sqrt(dx * dx + dz * dz)


func _step_random_walk(a: Dictionary) -> void:
	var dx: int = _rng.randi_range(-1, 1)
	var dz: int = _rng.randi_range(-1, 1)
	if dx == 0 and dz == 0:
		dx = 1 if _rng.randf() > 0.5 else -1
	_try_move(a, dx, dz)
	if bool(a.get("carrying_food", false)) and pheromone_field:
		pheromone_field.deposit(int(a["wx"]), int(a["wz"]), _Const.PHEROMONE_DEPOSIT_AMOUNT * 0.5)


func _try_move(a: Dictionary, dx: int, dz: int) -> void:
	var nwx: int = int(a["wx"]) + dx
	var nwz: int = int(a["wz"]) + dz
	var max_x: int = world.chunks_x * _Chunk.SIZE_X
	var max_z: int = world.chunks_z * _Chunk.SIZE_Z
	if nwx < 1 or nwz < 1 or nwx >= max_x - 1 or nwz >= max_z - 1:
		return
	var wy: int = _surface_y(nwx, nwz)
	if wy < 0:
		return
	a["wx"] = nwx
	a["wz"] = nwz
	var ant: Node3D = a["node"]
	var sc: float = float(a.get("scale", _Const.WORKER_VISUAL_SCALE))
	ant.position = _ant_pos(nwx, wy, nwz, sc)
	if dx != 0 or dz != 0:
		ant.rotation.y = atan2(float(dx), float(dz))


func get_worker_count() -> int:
	return _ants.size()
