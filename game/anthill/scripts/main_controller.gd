extends Node3D
## Scene coordinator: wires up all colony systems, manages game clock, food sources.

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")
const _MeshBuilder := preload("res://scripts/world/mesh_builder.gd")
const _SandStepScript = preload("res://scripts/world/sand_step.gd")
const _QueenScript = preload("res://scripts/queen_ant.gd")
const _BroodScript = preload("res://scripts/brood_manager.gd")
const _PheromoneScript = preload("res://scripts/pheromone_field.gd")
const _FoodStoreScript = preload("res://scripts/colony_food_store.gd")
const _BroodRendererScript = preload("res://scripts/brood_renderer.gd")
const _NestBuilderScript = preload("res://scripts/nest_builder.gd")
const _HudScript = preload("res://scripts/colony_hud.gd")
const _GameOverScript = preload("res://scripts/game_over.gd")
const _TerrainGen := preload("res://scripts/world/terrain_gen.gd")
const _SurfaceQuery := preload("res://scripts/world/surface_query.gd")
const _NestManagerScript = preload("res://scripts/nest_manager.gd")
const _BuildPheromoneScript = preload("res://scripts/building_pheromone.gd")

@export var initial_mesh_chunks_per_frame: int = 10
## Larger batches while the terrain overlay is visible (faster splash; does not affect steady-state mesh budget).
@export var initial_load_chunks_per_frame: int = 32
## Cap voxel mesh uploads per physics tick (sand/queen can dirty many chunks at once).
@export var max_mesh_rebuilds_per_physics_frame: int = 8

var _sand_step: RefCounted
@onready var world: Node = $WorldManager
@onready var chunks_root: Node3D = $Chunks
@onready var colony_ants: Node3D = $ColonyAnts
@onready var _colony_camera: Camera3D = $ColonyCamera
@onready var _terrain_load_overlay: CanvasLayer = $TerrainLoadOverlay
@onready var _terrain_load_bar: ProgressBar = $TerrainLoadOverlay/LoadingPanel/Center/VBox/ProgressBar
@onready var _terrain_load_status: Label = $TerrainLoadOverlay/LoadingPanel/Center/VBox/StatusLabel
@onready var _day_night: Node = $DayNightCycle

var _chunk_meshes: Dictionary = {}
var _mat: StandardMaterial3D
var _initial_mesh_keys: Array[Vector2i] = []
var _initial_mesh_idx: int = 0

var _queen: Node3D
var _brood_manager: Node
var _brood_renderer: Node3D
var _pheromone_field: Node
var _footprint_field: Node
var _food_store: Node
var _food_sources: Array[Node3D] = []
var _next_food_spawn_tick: int = 0
var _nest_builder: Node
var _nest_manager: Node
var _building_pheromone: Node
var _hud: CanvasLayer
var _game_over: CanvasLayer
var _rng: RandomNumberGenerator

var _mesh_pending: Dictionary = {}
var _xray_active: bool = false
var _pheromone_overlay_active: bool = false
## **0** = 1×, **1…N** = **`FAST_FORWARD_SPEEDS[i−1]`**.
var _ff_tier: int = 0
var _trail_overlay_meshes: Array[MeshInstance3D] = []
var _trail_overlay_timer: int = 0
var _mat_xray: StandardMaterial3D
var _game_tick: int = 0
## **Inspector**: selected worker **`sim_id`**, or **−1** if none.
var _selected_worker_sim_id: int = -1
var _game_day: int = 0
var _peak_workers: int = 0
var _first_workers_emerged: bool = false
var _colony_stage: String = "Founding"
var _queen_alive: bool = true
var _initial_terrain_ready: bool = false
## Phase 1 (scene parse in loading_screen.gd) occupies 0–30%. Phase 2 (terrain gen, already done
## in WorldManager._ready) is 30–35%. Phase 3 (chunk mesh builds) is 35–90%. Phase 4 (colony
## systems init) is 90–100%.
const _P2_START := 30.0
const _P2_END := 35.0
const _P3_START := 35.0
const _P3_END := 90.0
const _P4_START := 90.0
var _load_phase: int = 2


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_sand_step = _SandStepScript.new() as RefCounted
	_mat = StandardMaterial3D.new()
	_mat.vertex_color_use_as_albedo = true
	_mat.roughness = 0.88
	_mat.metallic = 0.0
	_mat_xray = StandardMaterial3D.new()
	_mat_xray.vertex_color_use_as_albedo = true
	_mat_xray.roughness = 0.88
	_mat_xray.metallic = 0.0
	_mat_xray.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_xray.albedo_color = Color(1.0, 1.0, 1.0, _Const.XRAY_SAND_ALPHA)
	_mat_xray.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_xray.render_priority = -1
	for cz in range(world.chunks_z):
		for cx in range(world.chunks_x):
			var mi := MeshInstance3D.new()
			mi.material_override = _mat
			chunks_root.add_child(mi)
			mi.position = Vector3(float(cx * _Chunk.SIZE_X), 0.0, float(cz * _Chunk.SIZE_Z))
			_chunk_meshes[Vector2i(cx, cz)] = mi
	for k in _chunk_meshes:
		_initial_mesh_keys.append(k)
	colony_ants.process_mode = Node.PROCESS_MODE_DISABLED
	_load_phase = 2
	_set_load_progress(_P2_END)
	_set_load_status("Terrain generated. Building chunk meshes... (0/%d)" % _initial_mesh_keys.size())
	_load_phase = 3
	set_process(true)


func _setup_systems() -> void:
	_brood_manager = Node.new()
	_brood_manager.name = "BroodManager"
	_brood_manager.set_script(load("res://scripts/brood_manager.gd"))
	add_child(_brood_manager)

	_brood_renderer = Node3D.new()
	_brood_renderer.name = "BroodRenderer"
	_brood_renderer.set_script(load("res://scripts/brood_renderer.gd"))
	add_child(_brood_renderer)
	_brood_renderer.setup(_brood_manager)

	_pheromone_field = Node.new()
	_pheromone_field.name = "PheromoneField"
	_pheromone_field.set_script(load("res://scripts/pheromone_field.gd"))
	add_child(_pheromone_field)

	_footprint_field = Node.new()
	_footprint_field.name = "FootprintField"
	_footprint_field.set_script(load("res://scripts/footprint_field.gd"))
	add_child(_footprint_field)

	_food_store = Node.new()
	_food_store.name = "ColonyFoodStore"
	_food_store.set_script(load("res://scripts/colony_food_store.gd"))
	add_child(_food_store)

	_nest_builder = Node.new()
	_nest_builder.name = "NestBuilder"
	_nest_builder.set_script(load("res://scripts/nest_builder.gd"))
	add_child(_nest_builder)

	_building_pheromone = Node.new()
	_building_pheromone.name = "BuildingPheromone"
	_building_pheromone.set_script(load("res://scripts/building_pheromone.gd"))
	add_child(_building_pheromone)

	_nest_manager = Node.new()
	_nest_manager.name = "NestManager"
	_nest_manager.set_script(load("res://scripts/nest_manager.gd"))
	add_child(_nest_manager)
	_nest_manager.bind_world(world)

	_hud = CanvasLayer.new()
	_hud.name = "ColonyHUD"
	_hud.set_script(load("res://scripts/colony_hud.gd"))
	add_child(_hud)

	_game_over = CanvasLayer.new()
	_game_over.name = "GameOver"
	_game_over.set_script(load("res://scripts/game_over.gd"))
	add_child(_game_over)

	_queen = Node3D.new()
	_queen.name = "Queen"
	_queen.set_script(load("res://scripts/queen_ant.gd"))
	add_child(_queen)
	_queen.setup(world, _nest_manager, _brood_manager)
	_queen.egg_laid.connect(_on_queen_egg_laid)
	_queen.queen_died.connect(_on_queen_died)
	_queen.founding_chamber_ready.connect(_on_founding_chamber_ready)

	_brood_manager.ant_eclosed.connect(_on_ant_eclosed)

	colony_ants.pheromone_field = _pheromone_field
	colony_ants.footprint_field = _footprint_field
	colony_ants.food_store = _food_store
	colony_ants.nest_manager = _nest_manager
	colony_ants.building_pheromone = _building_pheromone

	_init_food_spawning()


func _init_food_spawning() -> void:
	_food_sources.clear()
	_next_food_spawn_tick = _rng.randi_range(_Const.FOOD_SPAWN_FIRST_DELAY_MIN, _Const.FOOD_SPAWN_FIRST_DELAY_MAX)
	colony_ants.food_sources = _food_sources


func _food_spawn_ok_xy(wx: int, wz: int) -> bool:
	var ne: Vector3i = colony_ants.nest_entrance
	if ne != Vector3i.ZERO:
		var dx: int = wx - ne.x
		var dz: int = wz - ne.z
		if dx * dx + dz * dz < _Const.FOOD_SPAWN_MIN_DIST_FROM_NEST * _Const.FOOD_SPAWN_MIN_DIST_FROM_NEST:
			return false
	return true


func _try_spawn_food_source() -> bool:
	if _food_sources.size() >= _Const.FOOD_MAX_ACTIVE_SOURCES:
		return false
	var max_x: int = world.chunks_x * _Chunk.SIZE_X
	var max_z: int = world.chunks_z * _Chunk.SIZE_Z
	var margin: int = 16
	var x1: int = margin
	var x2: int = maxi(x1 + 1, max_x - margin - 1)
	var z1: int = margin
	var z2: int = maxi(z1 + 1, max_z - margin - 1)
	var types: Array[String] = ["aphid_colony", "dead_insect", "seed_cache"]
	for _attempt in range(48):
		var wx: int = _rng.randi_range(x1, x2)
		var wz: int = _rng.randi_range(z1, z2)
		if not _food_spawn_ok_xy(wx, wz):
			continue
		var sy: int = _surface_y(wx, wz)
		if sy < 0:
			continue
		var fs := Node3D.new()
		fs.name = "FoodSource_%d" % _game_tick
		fs.set_script(load("res://scripts/food_source.gd"))
		add_child(fs)
		fs.setup(types[_rng.randi_range(0, types.size() - 1)], wx, wz, sy, _rng)
		var spoil_dur: int = _rng.randi_range(_Const.FOOD_SPOIL_DURATION_TICKS_MIN, _Const.FOOD_SPOIL_DURATION_TICKS_MAX)
		if fs.has_method("begin_life"):
			fs.begin_life(_game_tick, spoil_dur)
		_food_sources.append(fs)
		return true
	return false


func _update_food_sources_at_tick() -> void:
	for i in range(_food_sources.size() - 1, -1, -1):
		var fs: Node3D = _food_sources[i]
		if not is_instance_valid(fs):
			_food_sources.remove_at(i)
			continue
		if fs.has_method("tick"):
			fs.tick(_game_tick)
		if fs.has_method("is_depleted") and fs.is_depleted():
			fs.queue_free()
			_food_sources.remove_at(i)
	if _food_sources.size() < _Const.FOOD_MAX_ACTIVE_SOURCES and _game_tick >= _next_food_spawn_tick:
		if _try_spawn_food_source():
			_next_food_spawn_tick = _game_tick + _rng.randi_range(_Const.FOOD_SPAWN_INTERVAL_TICKS_MIN, _Const.FOOD_SPAWN_INTERVAL_TICKS_MAX)
		else:
			_next_food_spawn_tick = _game_tick + 120


func _surface_y(wx: int, wz: int) -> int:
	return world.get_surface_y(wx, wz)


func _process(_delta: float) -> void:
	if _initial_mesh_idx < _initial_mesh_keys.size():
		var n: int = maxi(1, initial_load_chunks_per_frame)
		var end_i: int = mini(_initial_mesh_idx + n, _initial_mesh_keys.size())
		for i in range(_initial_mesh_idx, end_i):
			_rebuild_chunk_mesh(_initial_mesh_keys[i])
		_initial_mesh_idx = end_i
		var total: int = _initial_mesh_keys.size()
		var frac: float = float(_initial_mesh_idx) / float(maxi(total, 1))
		_set_load_progress(lerpf(_P3_START, _P3_END, frac))
		_set_load_status("Building chunk meshes... (%d/%d)" % [_initial_mesh_idx, total])
		return
	if not _initial_terrain_ready:
		_set_load_progress(_P4_START)
		_set_load_status("Initializing colony systems...")
		_finish_initial_terrain_load()
	set_process(false)


func _finish_initial_terrain_load() -> void:
	_set_load_status("Setting up queen, brood, food, pheromones...")
	_setup_systems()
	_set_load_progress(100.0)
	_set_load_status("Ready.")
	_initial_terrain_ready = true
	if _terrain_load_overlay:
		_terrain_load_overlay.queue_free()
	colony_ants.process_mode = Node.PROCESS_MODE_INHERIT
	if _day_night:
		_day_night.set_game_tick(_game_tick)


func _physics_process(_delta: float) -> void:
	if not _initial_terrain_ready:
		return
	PerfTrace.begin_frame()
	var suppress_sand: bool = (
		is_instance_valid(_queen)
		and _queen.has_method("sand_physics_suppressed")
		and _queen.sand_physics_suppressed()
	)
	var sand_us: int = 0
	## **`Engine.time_scale`** scales **`delta`** for nodes but does **not** add extra physics callbacks per real second, so tick-based sim ( **`_game_tick += 1`** ) must advance **`round(time_scale)`** sub-steps per frame to make **[F]** fast-forward affect ant-days and brood.
	var sim_steps: int = maxi(1, int(round(Engine.time_scale)))
	sim_steps = mini(sim_steps, _Const.FAST_FORWARD_SIM_STEPS_CAP)
	var t_sys := Time.get_ticks_usec()
	for _k in range(sim_steps):
		if _sand_step != null and not world.sand_idle and not suppress_sand:
			var t_s2 := Time.get_ticks_usec()
			_sand_step.step(world)
			sand_us += Time.get_ticks_usec() - t_s2
		_game_tick += 1
		if _day_night:
			_day_night.set_game_tick(_game_tick)
		_game_day = _game_tick / _Const.TICKS_PER_ANT_DAY
		var worker_n: int = colony_ants.get_worker_count() if colony_ants else 0
		if is_instance_valid(_queen) and _queen.has_method("care_for_brood"):
			_queen.care_for_brood(worker_n)
		if is_instance_valid(_queen) and _queen.has_method("apply_worker_trophallaxis"):
			_queen.apply_worker_trophallaxis(_food_store, worker_n)
		if worker_n > 0 and _brood_manager and _brood_manager.has_method("feed_all_larvae"):
			_brood_manager.call("feed_all_larvae", _Const.WORKER_BROOD_CARE_PER_TICK)
		if _brood_manager:
			_brood_manager.tick()
		if _pheromone_field:
			_pheromone_field.tick()
		if _footprint_field:
			_footprint_field.tick()
		if _building_pheromone:
			_building_pheromone.tick()
		_update_food_sources_at_tick()
	PerfTrace.set_sand_usec(sand_us)
	var t_meshq := Time.get_ticks_usec()
	if world.take_mesh_dirty():
		for ck in world.get_and_clear_dirty_chunks():
			_mesh_pending[ck] = true
	PerfTrace.set_mesh_dirty_usec(Time.get_ticks_usec() - t_meshq)
	var budget: int = maxi(1, _mesh_rebuild_budget())
	var t_rebuild := Time.get_ticks_usec()
	var rebuild_n: int = 0
	while budget > 0 and not _mesh_pending.is_empty():
		var keys: Array = _mesh_pending.keys()
		var k: Vector2i = keys[0] as Vector2i
		_mesh_pending.erase(k)
		_rebuild_chunk_mesh(k)
		rebuild_n += 1
		budget -= 1
	PerfTrace.set_mesh_rebuild_usec(Time.get_ticks_usec() - t_rebuild, rebuild_n)
	_update_colony_stage()
	_update_trail_overlay()
	_update_hud()
	PerfTrace.set_systems_usec(Time.get_ticks_usec() - t_sys)
	PerfTrace.set_context(
		_game_tick,
		_game_day,
		_mesh_pending.size(),
		world,
		_pheromone_field,
		_building_pheromone,
		colony_ants,
		_ff_tier > 0
	)


func _update_colony_stage() -> void:
	if not _queen_alive:
		return
	if _first_workers_emerged:
		_colony_stage = "Ergonomic"
	else:
		_colony_stage = "Founding"


func _format_clock_time(tick: int) -> String:
	var day_len: float = float(_Const.TICKS_PER_ANT_DAY)
	var t: float = fmod(float(tick), day_len) / day_len
	var total_min: int = int(round(t * 24.0 * 60.0)) % (24 * 60)
	var h: int = total_min / 60
	var m: int = total_min % 60
	return "%02d:%02d" % [h, m]


func _update_hud() -> void:
	if _hud == null:
		return
	var queen_energy: float = _queen.energy_reserve if is_instance_valid(_queen) else 0.0
	var sugar: float = _food_store.sugar if _food_store else 0.0
	var protein: float = _food_store.protein if _food_store else 0.0
	var workers: int = colony_ants.get_worker_count() if colony_ants else 0
	var brood_total: int = 0
	var eggs: int = 0
	var larvae: int = 0
	var pupae: int = 0
	if _brood_manager:
		var counts: Dictionary = _brood_manager.get_counts()
		brood_total = int(counts["total"])
		eggs = int(counts["eggs"])
		larvae = int(counts["larvae"])
		pupae = int(counts["pupae"])
	_peak_workers = maxi(_peak_workers, workers)
	_hud.xray_active = _xray_active
	_hud.pheromone_overlay_active = _pheromone_overlay_active
	_hud.fast_forward_multiplier = _ff_time_scale()
	_hud.update_data(
		_game_day,
		_format_clock_time(_game_tick),
		_colony_stage,
		queen_energy,
		sugar,
		protein,
		workers,
		brood_total
	)
	var nest_line: String = "—"
	if colony_ants and colony_ants.nest_entrance != Vector3i.ZERO:
		var ne: Vector3i = colony_ants.nest_entrance
		nest_line = "entrance (%d, %d), chamber y=%d" % [ne.x, ne.z, colony_ants.nest_chamber.y]
	var trail_n: int = _pheromone_field.debug_trail_cell_count() if _pheromone_field else 0
	var fp_n: int = 0
	if _footprint_field and _footprint_field.has_method("get_grid"):
		fp_n = int((_footprint_field.get_grid() as Dictionary).size())
	var build_n: int = _building_pheromone.debug_build_cell_count() if _building_pheromone else 0
	_hud.set_scientific_metrics(
		_game_tick,
		eggs,
		larvae,
		pupae,
		nest_line,
		_food_sources.size(),
		_peak_workers,
		trail_n,
		fp_n,
		build_n
	)
	if _selected_worker_sim_id >= 0 and colony_ants:
		var sel: Dictionary = colony_ants.get_ant_by_sim_id(_selected_worker_sim_id)
		if sel.is_empty():
			_selected_worker_sim_id = -1
			colony_ants.set_selected_ant_highlight({})
			_hud.set_ant_inspector({})
		else:
			_hud.set_ant_inspector(colony_ants.get_ant_inspector_snapshot(sel))


func _on_queen_egg_laid(count: int, is_trophic: bool) -> void:
	if _brood_manager:
		_brood_manager.add_eggs(count, is_trophic)


func _on_queen_died(cause: String) -> void:
	_queen_alive = false
	if _game_over:
		_game_over.show_game_over(cause, _game_day, _peak_workers)


func _on_founding_chamber_ready(chamber_center: Vector3i) -> void:
	if _brood_manager:
		_brood_manager.set_chamber_center(chamber_center)
	if _nest_builder:
		_nest_builder.setup(world, chamber_center)
	if _nest_manager:
		_nest_manager.setup(world, chamber_center, _building_pheromone)
	colony_ants.nest_entrance = Vector3i(chamber_center.x, _TerrainGen.SURFACE_BASE, chamber_center.z)
	colony_ants.nest_chamber = chamber_center
	## Used by **`sand_step`** to keep lateral spill from landing on the nest mouth ring.
	world.set("nest_spill_exclude_xz", Vector2i(chamber_center.x, chamber_center.z))


func _on_ant_eclosed(caste_destiny: String, pos: Vector3) -> void:
	if caste_destiny == "worker":
		if not _first_workers_emerged:
			_first_workers_emerged = true
			if is_instance_valid(_queen):
				_queen.transition_to_established()
		colony_ants.spawn_worker(pos, not _first_workers_emerged or colony_ants.get_worker_count() < 6)


func _unhandled_input(event: InputEvent) -> void:
	if not _initial_terrain_ready:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_X:
			_toggle_xray()
		elif event.keycode == KEY_F:
			_speed_up()
		elif event.keycode == KEY_S:
			_speed_down()
		elif event.keycode == KEY_P:
			_toggle_pheromone_overlay()
		elif event.keycode == KEY_ESCAPE:
			_clear_worker_selection()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if colony_ants and _colony_camera:
			var pick: Dictionary = colony_ants.try_pick_ant(_colony_camera, event.position, 36.0)
			if pick.is_empty():
				_clear_worker_selection()
			else:
				_selected_worker_sim_id = int(pick.get("sim_id", -1))
				colony_ants.set_selected_ant_highlight(pick)
				_hud.set_ant_inspector(colony_ants.get_ant_inspector_snapshot(pick))
			get_viewport().set_input_as_handled()


func _clear_worker_selection() -> void:
	_selected_worker_sim_id = -1
	if colony_ants:
		colony_ants.set_selected_ant_highlight({})
	if _hud:
		_hud.set_ant_inspector({})


func _ff_time_scale() -> float:
	if _ff_tier <= 0:
		return 1.0
	var i: int = _ff_tier - 1
	var speeds: Array = _Const.FAST_FORWARD_SPEEDS
	if i >= speeds.size():
		return 1.0
	return float(speeds[i])


func _mesh_rebuild_budget() -> int:
	var cap: int = maxi(1, max_mesh_rebuilds_per_physics_frame)
	var ts: float = Engine.time_scale
	if ts >= 60.0:
		return mini(cap, 1)
	if ts >= 20.0:
		return mini(cap, 2)
	return cap


func _speed_up() -> void:
	var max_tier: int = _Const.FAST_FORWARD_SPEEDS.size()
	if _ff_tier < max_tier:
		_ff_tier += 1
	Engine.time_scale = _ff_time_scale()


func _speed_down() -> void:
	if _ff_tier > 0:
		_ff_tier -= 1
	Engine.time_scale = _ff_time_scale()


func _toggle_pheromone_overlay() -> void:
	_pheromone_overlay_active = not _pheromone_overlay_active
	if not _pheromone_overlay_active:
		_clear_trail_overlay()


func _clear_trail_overlay() -> void:
	for mi in _trail_overlay_meshes:
		if is_instance_valid(mi):
			mi.queue_free()
	_trail_overlay_meshes.clear()


func _update_trail_overlay() -> void:
	if not _pheromone_overlay_active:
		return
	_trail_overlay_timer += 1
	if _trail_overlay_timer < 15:
		return
	_trail_overlay_timer = 0
	_clear_trail_overlay()
	var cs: float = float(_Const.PHEROMONE_CELL_SIZE)
	var quad := PlaneMesh.new()
	quad.size = Vector2(cs, cs)
	var mat_base := StandardMaterial3D.new()
	mat_base.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_base.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_base.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_base.render_priority = 2
	const Y_RECRUIT: float = 1.02
	const Y_FP: float = 1.08
	if _pheromone_field:
		var grid_t: Dictionary = _pheromone_field.get_grid()
		var base_col: Color = _Const.PHEROMONE_VIS_RECRUITMENT
		for cell in grid_t:
			var conc: float = float(grid_t[cell])
			if conc < 0.008:
				continue
			var wx: float = float(cell.x) * cs + cs * 0.5
			var wz: float = float(cell.y) * cs + cs * 0.5
			var sy: int = world.get_surface_y(int(wx), int(wz))
			if sy < 0:
				continue
			var mi := MeshInstance3D.new()
			mi.mesh = quad
			var m := mat_base.duplicate() as StandardMaterial3D
			var alpha: float = clampf(conc * 2.0, 0.08, 0.72)
			m.albedo_color = Color(base_col.r, base_col.g, base_col.b, alpha)
			mi.material_override = m
			mi.position = Vector3(wx, float(sy) + Y_RECRUIT, wz)
			add_child(mi)
			_trail_overlay_meshes.append(mi)
	if _footprint_field and _footprint_field.has_method("get_grid"):
		var grid_f: Dictionary = _footprint_field.get_grid()
		var base_fp: Color = _Const.PHEROMONE_VIS_FOOTPRINT
		for cell in grid_f:
			var conc_f: float = float(grid_f[cell])
			if conc_f < 0.004:
				continue
			var wx2: float = float(cell.x) * cs + cs * 0.5
			var wz2: float = float(cell.y) * cs + cs * 0.5
			var sy2: int = world.get_surface_y(int(wx2), int(wz2))
			if sy2 < 0:
				continue
			var mi2 := MeshInstance3D.new()
			mi2.mesh = quad
			var mf := mat_base.duplicate() as StandardMaterial3D
			var alpha_f: float = clampf(conc_f * 1.8, 0.06, 0.68)
			mf.albedo_color = Color(base_fp.r, base_fp.g, base_fp.b, alpha_f)
			mi2.material_override = mf
			mi2.position = Vector3(wx2, float(sy2) + Y_FP, wz2)
			add_child(mi2)
			_trail_overlay_meshes.append(mi2)
	if _building_pheromone and _building_pheromone.has_method("get_grid"):
		var grid_b: Dictionary = _building_pheromone.get_grid()
		var base_b: Color = _Const.PHEROMONE_VIS_BUILDING
		var box := BoxMesh.new()
		box.size = Vector3(0.82, 0.82, 0.82)
		for pos in grid_b:
			var cbuild: float = float(grid_b[pos])
			if cbuild < _Const.BUILD_PHEROMONE_MINIMUM * 0.5:
				continue
			var p3: Vector3i = pos as Vector3i
			var mb := mat_base.duplicate() as StandardMaterial3D
			var ab: float = clampf(cbuild * 1.4, 0.1, 0.85)
			mb.albedo_color = Color(base_b.r, base_b.g, base_b.b, ab)
			var mib := MeshInstance3D.new()
			mib.mesh = box
			mib.material_override = mb
			mib.position = Vector3(float(p3.x) + 0.5, float(p3.y) + 0.5, float(p3.z) + 0.5)
			add_child(mib)
			_trail_overlay_meshes.append(mib)


func _toggle_xray() -> void:
	_xray_active = not _xray_active
	var active_mat: StandardMaterial3D = _mat_xray if _xray_active else _mat
	for mi in _chunk_meshes.values():
		(mi as MeshInstance3D).material_override = active_mat


func _set_load_progress(pct: float) -> void:
	if _terrain_load_bar:
		_terrain_load_bar.value = clampf(pct, 0.0, 100.0)


func _set_load_status(text: String) -> void:
	if _terrain_load_status:
		_terrain_load_status.text = text


func _rebuild_chunk_mesh(k: Vector2i) -> void:
	var ch = world.get_chunk(k.x, k.y)
	if ch == null:
		return
	var mi: MeshInstance3D = _chunk_meshes.get(k)
	if mi == null:
		return
	var mesh: ArrayMesh = _MeshBuilder.build_chunk_mesh(world, ch)
	mi.mesh = mesh
	if mesh and mesh.get_surface_count() > 0:
		mi.custom_aabb = AABB(Vector3.ZERO, Vector3(float(_Chunk.SIZE_X), float(_Chunk.SIZE_Y), float(_Chunk.SIZE_Z)))
