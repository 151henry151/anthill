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
## Passive CHC footprint grid (negative chemotaxis); same cell size as **`pheromone_field`**.
var footprint_field: Node
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
## **`entrance_clear`** on **`11..12`**: dig **nest shaft** plug (sand / packed sand), then resume **`post_entrance_state`**.
var _digger_count: int = 0
static var _next_worker_sim_id: int = 1
var _selection_ring: MeshInstance3D = null


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
	var inv_sc: float = 1.0 / sc
	carry_mesh.size = Vector3.ONE * inv_sc * 0.8
	carry_vis.mesh = carry_mesh
	var carry_mat := StandardMaterial3D.new()
	carry_mat.albedo_color = Color(0.92, 0.82, 0.62)
	carry_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	carry_vis.material_override = carry_mat
	carry_vis.position = Vector3(0, 0.12, 0.42) * inv_sc * 2.5
	carry_vis.visible = false
	ant.add_child(carry_vis)
	_ants.append({
		"node": ant,
		"sim_id": _next_worker_sim_id,
		"wx": int(pos.x),
		"wz": int(pos.z),
		"t": 0.0,
		"state": state,
		"age_ticks": 0,
		## Placeholder **vitality** (0–1) for scientific readout; future metabolism can drain this.
		"health": 1.0,
		## Abstract **crop / labial gland** fullness when carrying liquid food (0–1).
		"metabolic_reserve": 1.0,
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
		"entrance_clear": false,
		"post_entrance_state": 1,
		"food_source_wx": 0,
		"food_source_wz": 0,
		"heading_rad": _rng.randf_range(0.0, TAU),
		"trail_spot_dist_accum": 0.0,
		"trail_next_spot_vox": 8,
		"knows_food_site": false,
		"memory_wx": 0,
		"memory_wz": 0,
		"memory_quality": 0.0,
		"last_food_quality": 1.0,
	})
	_next_worker_sim_id += 1


func _surface_y(wx: int, wz: int) -> int:
	return world.get_surface_y(wx, wz)


func _ant_pos(wx: int, wy: int, wz: int, sc: float) -> Vector3:
	var surface_top: float = float(wy) + 1.0
	var y: float = surface_top - _ANT_LOCAL_Y_MIN * sc
	return Vector3(float(wx) + 0.5, y, float(wz) + 0.5)


func _physics_process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	var sim_steps: int = maxi(1, mini(int(round(Engine.time_scale)), _Const.FAST_FORWARD_SIM_STEPS_CAP))
	_task_assign_timer += sim_steps
	if _task_assign_timer >= _TASK_ASSIGN_INTERVAL:
		_task_assign_timer = 0
		_assign_tasks()
	for a in _ants:
		a["age_ticks"] = int(a["age_ticks"]) + sim_steps
		for _i in range(sim_steps):
			a["t"] = float(a["t"]) + delta
			while float(a["t"]) >= move_interval:
				a["t"] -= move_interval
				_step_ant(a)
	PerfTrace.set_ants_usec(Time.get_ticks_usec() - t0)


func _assign_tasks() -> void:
	## Prefer one **resting** worker near the nest to open a blocked shaft (same tick budget as other assignments).
	if nest_manager and _entrance_needs_clearing():
		for a in _ants:
			if int(a["state"]) != 1:
				continue
			if _dist_to(a, nest_entrance) >= _Const.WORKER_ENTRANCE_CLEAR_ENGAGE_DIST:
				continue
			a["entrance_clear"] = true
			a["post_entrance_state"] = 1
			a["dig_target"] = Vector3i.ZERO
			a["state"] = 11
			break
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
	var sugar_level: float = food_store.sugar if food_store else 0.0
	var protein_level: float = food_store.protein if food_store else 0.0
	var sugar_deficit: float = maxf(0.0, _Const.FOOD_STORE_TARGET_SUGAR - sugar_level)
	var protein_deficit: float = maxf(0.0, _Const.FOOD_STORE_TARGET_PROTEIN - protein_level)
	var food_urgency: float = clampf((sugar_deficit + protein_deficit) / _Const.FOOD_STORE_TARGET_SUGAR, 0.0, 1.0)
	var forage_prob: float = lerpf(_Const.MIN_FORAGER_FRACTION, 0.65, food_urgency)
	var dig_prob: float = 0.0
	if need_diggers and food_urgency < 0.5:
		dig_prob = 0.35
	elif need_diggers:
		dig_prob = 0.15
	for a in old_idle:
		var roll: float = _rng.randf()
		if roll < dig_prob and _digger_count < _Const.MAX_NEST_BUILDERS:
			a["state"] = 11  # DIGGING_APPROACH
			_digger_count += 1
		elif roll < dig_prob + forage_prob:
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
	if nest_manager and _entrance_needs_clearing() and _dist_to(a, nest_entrance) < _Const.WORKER_ENTRANCE_CLEAR_ENGAGE_DIST:
		a["entrance_clear"] = true
		a["post_entrance_state"] = 2
		a["dig_target"] = Vector3i.ZERO
		a["state"] = 11
		return
	_move_toward(a, nest_chamber)


func _step_nest_building(a: Dictionary) -> void:
	a["state"] = 11  # Redirect to digging approach


func _step_foraging_depart(a: Dictionary) -> void:
	_move_away_from(a, nest_entrance)
	if _dist_to(a, nest_entrance) > 8:
		if _detect_trail(a):
			a["state"] = 6  # FORAGING_RECRUIT
		else:
			a["state"] = 5  # FORAGING_SCOUT


func _step_foraging_scout(a: Dictionary) -> void:
	## Roulette-biased Moore exploration (prefer lower footprint, weak trail up-gradient) until recruitment trail is sensed.
	if _detect_trail(a):
		a["state"] = 6
		return
	_moore_exploration_step(a)
	if _detect_trail(a):
		a["state"] = 6
		return
	_check_food_nearby(a)


## Scout search: weighted Moore step — **lower neighbor footprint** and **trail gradient**; falls back to shuffled uniform if no footprint field.
func _moore_exploration_step(a: Dictionary) -> void:
	if footprint_field == null:
		_moore_uniform_random_step(a)
		return
	var wx: int = int(a["wx"])
	var wz: int = int(a["wz"])
	var t_here: float = pheromone_field.sample(wx, wz) if pheromone_field else 0.0
	var fp_here: float = footprint_field.sample(wx, wz)
	var weights: Array[float] = []
	var dirs: Array[Vector2i] = []
	for ox in range(-1, 2):
		for oz in range(-1, 2):
			if ox == 0 and oz == 0:
				continue
			var nwx: int = wx + ox
			var nwz: int = wz + oz
			if not _cell_walkable(nwx, nwz):
				continue
			var t_nb: float = pheromone_field.sample(nwx, nwz) if pheromone_field else 0.0
			var fp_nb: float = footprint_field.sample(nwx, nwz)
			var w: float = _Const.FOOTPRINT_SCOUT_BASE_WEIGHT
			w += _Const.FOOTPRINT_SCOUT_REPULSION_MULT * _Const.FOOTPRINT_REPULSION_WEIGHT * maxf(0.0, fp_here - fp_nb)
			w += maxf(0.0, t_nb - t_here)
			weights.append(w)
			dirs.append(Vector2i(ox, oz))
	if dirs.is_empty():
		_moore_uniform_random_step(a)
		return
	var total: float = 0.0
	for wv in weights:
		total += wv
	var r: float = _rng.randf() * total
	var acc: float = 0.0
	for i in range(weights.size()):
		acc += weights[i]
		if r <= acc:
			var d: Vector2i = dirs[i]
			_try_move(a, d.x, d.y)
			return
	var d0: Vector2i = dirs[dirs.size() - 1]
	_try_move(a, d0.x, d0.y)


func _moore_uniform_random_step(a: Dictionary) -> void:
	var wx: int = int(a["wx"])
	var wz: int = int(a["wz"])
	for d in _shuffle_dir8():
		if _try_apply_if_walkable(a, wx + d.x, wz + d.y, d.x, d.y):
			return
	var dx: int = _rng.randi_range(-1, 1)
	var dz: int = _rng.randi_range(-1, 1)
	if dx == 0 and dz == 0:
		dx = 1 if _rng.randf() > 0.5 else -1
	_try_move(a, dx, dz)


func _step_foraging_recruit(a: Dictionary) -> void:
	if pheromone_field == null:
		a["state"] = 5
		return
	var wx: int = int(a["wx"])
	var wz: int = int(a["wz"])
	var here: float = pheromone_field.sample(wx, wz)
	if here < _Const.PHEROMONE_RECRUIT_THRESHOLD * 0.3:
		a["state"] = 5
		return
	_step_tropotaxis_moore(a)
	_check_food_nearby(a)


## Tropotaxis + **phase-dependent** CHC: **search** (low trail) weak attraction along **`f_nb − f_here`**; **exploitation** (high trail) repellent **`f_here − f_nb`**.
func _step_tropotaxis_moore(a: Dictionary) -> void:
	if pheromone_field == null:
		return
	var wx: int = int(a["wx"])
	var wz: int = int(a["wz"])
	var here: float = pheromone_field.sample(wx, wz)
	var fp_here: float = footprint_field.sample(wx, wz) if footprint_field else 0.0
	var exploit: bool = here >= _Const.PHEROMONE_EXPLOITATION_THRESHOLD
	var weights: Array[float] = []
	var dirs: Array[Vector2i] = []
	for ox in range(-1, 2):
		for oz in range(-1, 2):
			if ox == 0 and oz == 0:
				continue
			var nwx: int = wx + ox
			var nwz: int = wz + oz
			if not _cell_walkable(nwx, nwz):
				continue
			var c_nb: float = pheromone_field.sample(nwx, nwz)
			var w: float = _Const.PHEROMONE_TROPOTAXIS_FLOOR + maxf(0.0, c_nb - here)
			if footprint_field:
				var fp_nb: float = footprint_field.sample(nwx, nwz)
				if exploit:
					w += _Const.FOOTPRINT_REPULSION_WEIGHT * maxf(0.0, fp_here - fp_nb)
				else:
					w += _Const.FOOTPRINT_SEARCH_ATTRACTION_WEIGHT * maxf(0.0, fp_nb - fp_here)
			if bool(a.get("knows_food_site", false)) and here < _Const.FORAGING_MEMORY_TRAIL_WEAK:
				var mx: int = int(a.get("memory_wx", 0))
				var mz: int = int(a.get("memory_wz", 0))
				if mx != 0 or mz != 0:
					var tdx: int = signi(mx - wx)
					var tdz: int = signi(mz - wz)
					var mem_align: float = 0.0
					if tdx != 0 and ox == tdx:
						mem_align += 0.55
					if tdz != 0 and oz == tdz:
						mem_align += 0.55
					w += _Const.FORAGING_MEMORY_BIAS_WEIGHT * float(a.get("memory_quality", 0.5)) * mem_align
			weights.append(w)
			dirs.append(Vector2i(ox, oz))
	if dirs.is_empty():
		_moore_exploration_step(a)
		return
	var total: float = 0.0
	for w in weights:
		total += w
	var r: float = _rng.randf() * total
	var acc: float = 0.0
	for i in range(weights.size()):
		acc += weights[i]
		if r <= acc:
			var d: Vector2i = dirs[i]
			_try_move(a, d.x, d.y)
			return
	var d0: Vector2i = dirs[dirs.size() - 1]
	_try_move(a, d0.x, d0.y)


func _step_returning(a: Dictionary) -> void:
	var d: float = _dist_to(a, nest_entrance)
	if nest_manager and _entrance_needs_clearing() and d < _Const.WORKER_ENTRANCE_CLEAR_ENGAGE_DIST:
		a["entrance_clear"] = true
		a["post_entrance_state"] = 7
		a["dig_target"] = Vector3i.ZERO
		a["state"] = 11
		return
	# Home-vector navigation: move directly toward nest with minimal noise (±10°).
	var wx: int = int(a["wx"])
	var wz: int = int(a["wz"])
	var to_nest_x: float = float(nest_entrance.x - wx)
	var to_nest_z: float = float(nest_entrance.z - wz)
	var home_angle: float = atan2(to_nest_x, to_nest_z)
	home_angle += _rng.randf_range(-0.17, 0.17)
	var dx: int = int(round(sin(home_angle)))
	var dz: int = int(round(cos(home_angle)))
	if dx == 0 and dz == 0:
		dx = signi(nest_entrance.x - wx)
	_try_move(a, dx, dz)
	# **Recruitment trail** (fed return): discrete spots (mm spacing) × Bernoulli **TRAIL_SATIATED_DEPOSIT_PROBABILITY**; amount scales with food proximity and saturation.
	if pheromone_field and bool(a.get("carrying_food", false)):
		wx = int(a["wx"])
		wz = int(a["wz"])
		var fsx: int = int(a.get("food_source_wx", wx))
		var fsz: int = int(a.get("food_source_wz", wz))
		var d_to_food: float = sqrt(float((wx - fsx) * (wx - fsx) + (wz - fsz) * (wz - fsz)))
		var d_to_nest: float = _dist_to(a, nest_entrance)
		var total_path: float = d_to_food + d_to_nest
		if total_path < 1.0:
			total_path = 1.0
		var food_proximity: float = clampf(1.0 - d_to_food / total_path, 0.0, 1.0)
		var q: float = float(a.get("last_food_quality", 1.0))
		var base_amt: float = (_Const.PHEROMONE_BASE_DEPOSIT + _Const.PHEROMONE_DISTANCE_BONUS * food_proximity) * q
		_maybe_deposit_recruitment_spot(a, wx, wz, base_amt)
	d = _dist_to(a, nest_entrance)
	if d < _Const.WORKER_NEST_ARRIVAL_MAX_DIST:
		if food_store and bool(a.get("carrying_food", false)):
			food_store.add_food(String(a["food_type"]), _Const.FOOD_CARRY_AMOUNT)
		a["carrying_food"] = false
		a["food_type"] = ""
		a["return_stuck"] = 0
		a["state"] = 8
		return
	a["return_stuck"] = int(a.get("return_stuck", 0)) + 1


func _step_trophallaxis(a: Dictionary) -> void:
	# Successful foragers immediately re-depart (real ants make repeated trips).
	var fsx: int = int(a.get("food_source_wx", 0))
	var fsz: int = int(a.get("food_source_wz", 0))
	if fsx != 0 or fsz != 0:
		a["state"] = 4  # FORAGING_DEPART (will detect trail and become recruit)
	else:
		a["state"] = 1  # RESTING


func _step_digging_approach(a: Dictionary) -> void:
	if nest_manager == null:
		a["entrance_clear"] = false
		a["state"] = int(a.get("post_entrance_state", 1))
		return
	var target: Vector3i = a.get("dig_target", Vector3i.ZERO) as Vector3i
	if target == Vector3i.ZERO:
		if bool(a.get("entrance_clear", false)):
			var et: Vector3i = _get_entrance_dig_target()
			if et == Vector3i.ZERO:
				a["entrance_clear"] = false
				a["state"] = int(a.get("post_entrance_state", 1))
				return
			target = et
			a["dig_target"] = target
			nest_manager.reserve_voxel(target, a["node"])
		else:
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
		a["dig_target"] = Vector3i.ZERO
		a["dig_ticks"] = 0
		if bool(a.get("entrance_clear", false)):
			a["state"] = 11
			return
		a["carrying_voxel"] = true
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


func _detect_trail(a: Dictionary) -> bool:
	if pheromone_field == null:
		return false
	var wx: int = int(a["wx"])
	var wz: int = int(a["wz"])
	var r: int = _Const.PHEROMONE_SENSE_RADIUS
	for dx in range(-r, r + 1, 2):
		for dz in range(-r, r + 1, 2):
			if pheromone_field.sample(wx + dx, wz + dz) >= _Const.PHEROMONE_RECRUIT_THRESHOLD:
				return true
	return false


func _count_workers_near_patch(pwx: int, pwz: int, radius: int) -> int:
	var n: int = 0
	for ant in _ants:
		var ax: int = int(ant["wx"])
		var az: int = int(ant["wz"])
		if absi(ax - pwx) <= radius and absi(az - pwz) <= radius:
			n += 1
	return n


func _check_food_nearby(a: Dictionary) -> void:
	var wx: int = int(a["wx"])
	var wz: int = int(a["wz"])
	var order: Array[int] = []
	for i in range(food_sources.size()):
		order.append(i)
	for i in range(order.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var t: int = order[i]
		order[i] = order[j]
		order[j] = t
	for idx in order:
		var fs: Node3D = food_sources[idx]
		if not is_instance_valid(fs):
			continue
		if fs.is_depleted():
			continue
		var dx: int = absi(fs.wx - wx)
		var dz: int = absi(fs.wz - wz)
		if dx <= 2 and dz <= 2:
			var crowd: int = _count_workers_near_patch(fs.wx, fs.wz, _Const.FEEDER_CROWD_RADIUS)
			if crowd >= _Const.FEEDER_CROWD_MAX_WORKERS and _rng.randf() > _Const.FEEDER_CROWD_OVERFLOW_ATTEMPT_PROB:
				continue
			var taken: float = fs.collect(_Const.FOOD_CARRY_AMOUNT)
			if taken > 0.0:
				a["carrying_food"] = true
				a["food_type"] = fs.food_type
				a["food_source_wx"] = fs.wx
				a["food_source_wz"] = fs.wz
				a["knows_food_site"] = true
				a["memory_wx"] = fs.wx
				a["memory_wz"] = fs.wz
				var rq: float = 0.7
				if fs.has_method("get_reward_quality"):
					rq = float(fs.call("get_reward_quality"))
				a["memory_quality"] = rq
				a["last_food_quality"] = rq
				fs.is_known_to_colony = true
				a["state"] = 7  # RETURNING
				a["return_stuck"] = 0
				a["trail_spot_dist_accum"] = 0.0
				a["trail_next_spot_vox"] = _random_trail_spot_spacing_voxels()
				# **Recruitment** burst at source: Bernoulli × saturation (no spot spacing — first mark at resource).
				if pheromone_field and _rng.randf() < _Const.TRAIL_SATIATED_DEPOSIT_PROBABILITY:
					var burst: float = _Const.PHEROMONE_DEPOSIT_AMOUNT * 2.0 * float(a.get("last_food_quality", 1.0)) * _trail_saturation_multiplier(wx, wz)
					pheromone_field.deposit(wx, wz, burst)
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


func _entrance_needs_clearing() -> bool:
	return _get_entrance_dig_target() != Vector3i.ZERO


## Topmost **sand / packed sand** voxel in the founding **shaft footprint** (clear highest plug first).
func _get_entrance_dig_target() -> Vector3i:
	if nest_entrance == Vector3i.ZERO or nest_chamber == Vector3i.ZERO or nest_manager == null:
		return Vector3i.ZERO
	var best_y: int = -999999
	var best: Vector3i = Vector3i.ZERO
	var hw: int = _Const.FOUNDING_SHAFT_WIDTH / 2
	var y_floor: int = maxi(1, nest_chamber.y - 24)
	for dx in range(-hw, hw + 1):
		for dz in range(-hw, hw + 1):
			var wx: int = nest_entrance.x + dx
			var wz: int = nest_entrance.z + dz
			var sy: int = _surface_y(wx, wz)
			if sy < 0:
				continue
			for y in range(sy, y_floor - 1, -1):
				var bt: int = world.get_block(wx, y, wz)
				if bt == _Const.BLOCK_AIR:
					continue
				if bt == _Const.BLOCK_SAND or bt == _Const.BLOCK_PACKED_SAND:
					if y > best_y:
						best_y = y
						best = Vector3i(wx, y, wz)
					break
				break
	return best if best_y > -900000 else Vector3i.ZERO


func _step_random_walk(a: Dictionary) -> void:
	var dx: int = _rng.randi_range(-1, 1)
	var dz: int = _rng.randi_range(-1, 1)
	if dx == 0 and dz == 0:
		dx = 1 if _rng.randf() > 0.5 else -1
	_try_move(a, dx, dz)
	if bool(a.get("carrying_food", false)) and pheromone_field:
		_maybe_deposit_recruitment_spot(a, int(a["wx"]), int(a["wz"]), _Const.PHEROMONE_DEPOSIT_AMOUNT * 0.5 * float(a.get("last_food_quality", 1.0)))


func _cell_walkable(nwx: int, nwz: int) -> bool:
	var max_x: int = world.chunks_x * _Chunk.SIZE_X
	var max_z: int = world.chunks_z * _Chunk.SIZE_Z
	if nwx < 1 or nwz < 1 or nwx >= max_x - 1 or nwz >= max_z - 1:
		return false
	return _surface_y(nwx, nwz) >= 0


func _apply_step_to(a: Dictionary, nwx: int, nwz: int, face_dx: int, face_dz: int) -> void:
	var wy: int = _surface_y(nwx, nwz)
	a["wx"] = nwx
	a["wz"] = nwz
	var ant: Node3D = a["node"]
	var sc: float = float(a.get("scale", _Const.WORKER_VISUAL_SCALE))
	ant.position = _ant_pos(nwx, wy, nwz, sc)
	if face_dx != 0 or face_dz != 0:
		ant.rotation.y = atan2(float(face_dx), float(face_dz))
	if footprint_field and footprint_field.has_method("deposit"):
		footprint_field.deposit(nwx, nwz, _Const.FOOTPRINT_DEPOSIT_PER_STEP)


func _random_trail_spot_spacing_voxels() -> int:
	var vmin: float = _Const.TRAIL_SPOT_MIN_MM / _Const.MM_PER_UNIT
	var vmax: float = _Const.TRAIL_SPOT_MAX_MM / _Const.MM_PER_UNIT
	return maxi(1, int(round(_rng.randf_range(vmin, vmax))))


## Discrete **spots** along return path (voxel steps) × **`TRAIL_SATIATED_DEPOSIT_PROBABILITY`**.
func _maybe_deposit_recruitment_spot(a: Dictionary, wx: int, wz: int, base_unscaled: float) -> void:
	if pheromone_field == null:
		return
	a["trail_spot_dist_accum"] = float(a.get("trail_spot_dist_accum", 0.0)) + 1.0
	if float(a["trail_spot_dist_accum"]) < float(a.get("trail_next_spot_vox", 8)):
		return
	a["trail_spot_dist_accum"] = 0.0
	a["trail_next_spot_vox"] = _random_trail_spot_spacing_voxels()
	if _rng.randf() > _Const.TRAIL_SATIATED_DEPOSIT_PROBABILITY:
		return
	var deposit_amt: float = base_unscaled * _trail_saturation_multiplier(wx, wz)
	pheromone_field.deposit(wx, wz, deposit_amt)


## Scale **recruitment** deposit when local trail concentration is high (**Lasius niger**-style negative feedback on runaway attraction).
func _trail_saturation_multiplier(wx: int, wz: int) -> float:
	if pheromone_field == null:
		return 1.0
	var c: float = pheromone_field.sample(wx, wz)
	var s0: float = _Const.TRAIL_SATURATION_START
	if c <= s0:
		return 1.0
	var t: float = clampf((c - s0) / maxf(1e-6, 1.0 - s0), 0.0, 1.0)
	return lerpf(1.0, _Const.TRAIL_SATURATION_MIN_DEPOSIT_SCALE, t)


func _try_apply_if_walkable(a: Dictionary, nwx: int, nwz: int, face_dx: int, face_dz: int) -> bool:
	if not _cell_walkable(nwx, nwz):
		return false
	_apply_step_to(a, nwx, nwz, face_dx, face_dz)
	return true


func _shuffle_dir8() -> Array[Vector2i]:
	var dirs: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	]
	for i in range(7, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp: Vector2i = dirs[i]
		dirs[i] = dirs[j]
		dirs[j] = tmp
	return dirs


func _try_move(a: Dictionary, dx: int, dz: int) -> void:
	var wx: int = int(a["wx"])
	var wz: int = int(a["wz"])
	var nwx: int = wx + dx
	var nwz: int = wz + dz
	if _try_apply_if_walkable(a, nwx, nwz, dx, dz):
		return
	## Diagonal blocked: try axis slides (wall-following).
	if dx != 0 and dz != 0:
		if _try_apply_if_walkable(a, wx, wz + dz, 0, dz):
			return
		if _try_apply_if_walkable(a, wx + dx, wz, dx, 0):
			return
	## Cardinal at an edge, or slides failed: pick any walkable neighbor (prevents corner clustering).
	for d in _shuffle_dir8():
		if d.x == dx and d.y == dz:
			continue
		if _try_apply_if_walkable(a, wx + d.x, wz + d.y, d.x, d.y):
			return


func get_worker_count() -> int:
	return _ants.size()


func get_ant_by_sim_id(sim_id: int) -> Dictionary:
	for a in _ants:
		if int(a.get("sim_id", -1)) == sim_id:
			return a
	return {}


func get_worker_state_name(st: int) -> String:
	match st:
		0:
			return "EMERGING"
		1:
			return "RESTING"
		2:
			return "BROOD_CARE"
		3:
			return "NEST_BUILDING"
		4:
			return "FORAGING_DEPART"
		5:
			return "FORAGING_SCOUT"
		6:
			return "FORAGING_RECRUIT"
		7:
			return "RETURNING"
		8:
			return "TROPHALLAXIS"
		9:
			return "ATTENDING_QUEEN"
		10:
			return "DEFENDING"
		11:
			return "DIGGING_APPROACH"
		12:
			return "DIGGING_ACT"
		13:
			return "CARRYING_TO_SURFACE"
		14:
			return "DEPOSITING"
		_:
			return "OTHER(%d)" % st


## Screen-space pick (orthographic colony view): closest worker within **`max_px`** of **`screen_pos`**.
func try_pick_ant(camera: Camera3D, screen_pos: Vector2, max_px: float) -> Dictionary:
	var best_d: float = max_px
	var best: Dictionary = {}
	for a in _ants:
		var node: Node3D = a["node"] as Node3D
		if node == null or not is_instance_valid(node):
			continue
		var wpos: Vector3 = node.global_position
		if not camera.is_position_in_frustum(wpos):
			continue
		var sp: Vector2 = camera.unproject_position(wpos)
		var d: float = sp.distance_to(screen_pos)
		if d < best_d:
			best_d = d
			best = a
	return best


## Data for inspector UI and exports (local chemistry samples at worker feet).
func get_ant_inspector_snapshot(a: Dictionary) -> Dictionary:
	if a.is_empty():
		return {}
	var wx: int = int(a["wx"])
	var wz: int = int(a["wz"])
	var st: int = int(a["state"])
	var crop: float = 1.0 if bool(a.get("carrying_food", false)) else 0.0
	var trail: float = pheromone_field.sample(wx, wz) if pheromone_field else 0.0
	var fp: float = footprint_field.sample(wx, wz) if footprint_field else 0.0
	var age: int = int(a.get("age_ticks", 0))
	return {
		"sim_id": int(a.get("sim_id", 0)),
		"state_name": get_worker_state_name(st),
		"state": st,
		"wx": wx,
		"wz": wz,
		"age_ticks": age,
		"age_ant_days": float(age) / float(_Const.TICKS_PER_ANT_DAY),
		"is_nanitic": bool(a.get("is_nanitic", false)),
		"carrying_food": bool(a.get("carrying_food", false)),
		"food_type": String(a.get("food_type", "")),
		"crop_load": crop,
		"health": float(a.get("health", 1.0)),
		"metabolic_reserve": float(a.get("metabolic_reserve", 1.0)),
		"trail_sample": trail,
		"footprint_sample": fp,
		"heading_deg": rad_to_deg(float(a.get("heading_rad", 0.0))),
		"dist_to_nest": _dist_to(a, nest_entrance) if nest_entrance != Vector3i.ZERO else -1.0,
		"knows_food_site": bool(a.get("knows_food_site", false)),
		"memory_wx": int(a.get("memory_wx", 0)),
		"memory_wz": int(a.get("memory_wz", 0)),
		"memory_quality": float(a.get("memory_quality", 0.0)),
		"last_food_quality": float(a.get("last_food_quality", 1.0)),
	}


func set_selected_ant_highlight(selected: Dictionary) -> void:
	if _selection_ring != null and is_instance_valid(_selection_ring):
		if _selection_ring.get_parent():
			_selection_ring.get_parent().remove_child(_selection_ring)
		_selection_ring.queue_free()
		_selection_ring = null
	if selected.is_empty():
		return
	var ant_node: Node3D = selected.get("node") as Node3D
	if ant_node == null or not is_instance_valid(ant_node):
		return
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.28
	torus.outer_radius = 0.42
	ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.95, 0.85, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.35, 0.05)
	ring.material_override = mat
	ring.rotation_degrees = Vector3(90, 0, 0)
	ring.position = Vector3(0, 0.06, 0)
	ant_node.add_child(ring)
	_selection_ring = ring
