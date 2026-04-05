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
const _FoodSourceScript = preload("res://scripts/food_source.gd")
const _BroodRendererScript = preload("res://scripts/brood_renderer.gd")
const _NestBuilderScript = preload("res://scripts/nest_builder.gd")
const _HudScript = preload("res://scripts/colony_hud.gd")
const _GameOverScript = preload("res://scripts/game_over.gd")
const _TerrainGen := preload("res://scripts/world/terrain_gen.gd")
const _SurfaceQuery := preload("res://scripts/world/surface_query.gd")
const _NestManagerScript = preload("res://scripts/nest_manager.gd")
const _BuildPheromoneScript = preload("res://scripts/building_pheromone.gd")

@export var initial_mesh_chunks_per_frame: int = 10
## Cap voxel mesh uploads per physics tick (sand/queen can dirty many chunks at once).
@export var max_mesh_rebuilds_per_physics_frame: int = 8

var _sand_step: RefCounted
@onready var world: Node = $WorldManager
@onready var chunks_root: Node3D = $Chunks
@onready var colony_ants: Node3D = $ColonyAnts

var _chunk_meshes: Dictionary = {}
var _mat: StandardMaterial3D
var _initial_mesh_keys: Array[Vector2i] = []
var _initial_mesh_idx: int = 0

var _queen: Node3D
var _brood_manager: Node
var _brood_renderer: Node3D
var _pheromone_field: Node
var _food_store: Node
var _food_sources: Array[Node3D] = []
var _nest_builder: Node
var _nest_manager: Node
var _building_pheromone: Node
var _hud: CanvasLayer
var _game_over: CanvasLayer
var _rng: RandomNumberGenerator

var _mesh_pending: Dictionary = {}
var _xray_active: bool = false
var _mat_xray: StandardMaterial3D
var _game_tick: int = 0
var _game_day: int = 0
var _peak_workers: int = 0
var _first_workers_emerged: bool = false
var _colony_stage: String = "Founding"
var _queen_alive: bool = true


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
			mi.position = Vector3.ZERO
			_chunk_meshes[Vector2i(cx, cz)] = mi
	for k in _chunk_meshes:
		_initial_mesh_keys.append(k)
	_setup_systems()
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
	_queen.setup(world, _nest_manager)
	_queen.egg_laid.connect(_on_queen_egg_laid)
	_queen.queen_died.connect(_on_queen_died)
	_queen.founding_chamber_ready.connect(_on_founding_chamber_ready)

	_brood_manager.ant_eclosed.connect(_on_ant_eclosed)

	colony_ants.pheromone_field = _pheromone_field
	colony_ants.food_store = _food_store
	colony_ants.nest_manager = _nest_manager
	colony_ants.building_pheromone = _building_pheromone

	_spawn_food_sources()


func _spawn_food_sources() -> void:
	var count: int = _rng.randi_range(_Const.FOOD_SOURCE_COUNT_MIN, _Const.FOOD_SOURCE_COUNT_MAX)
	var max_x: int = world.chunks_x * _Chunk.SIZE_X
	var max_z: int = world.chunks_z * _Chunk.SIZE_Z
	var types: Array[String] = ["aphid_colony", "dead_insect", "seed_cache"]
	for i in range(count):
		var wx: int = _rng.randi_range(20, max_x - 20)
		var wz: int = _rng.randi_range(20, max_z - 20)
		var sy: int = _surface_y(wx, wz)
		if sy < 0:
			continue
		var fs := Node3D.new()
		fs.name = "FoodSource_%d" % i
		fs.set_script(load("res://scripts/food_source.gd"))
		add_child(fs)
		fs.setup(types[i % types.size()], wx, wz, sy)
		_food_sources.append(fs)
	colony_ants.food_sources = _food_sources


func _surface_y(wx: int, wz: int) -> int:
	return _SurfaceQuery.surface_block_y(world, wx, wz)


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
			_mesh_pending[ck] = true
	var budget: int = maxi(1, max_mesh_rebuilds_per_physics_frame)
	while budget > 0 and not _mesh_pending.is_empty():
		var keys: Array = _mesh_pending.keys()
		var k: Vector2i = keys[0] as Vector2i
		_mesh_pending.erase(k)
		_rebuild_chunk_mesh(k)
		budget -= 1
	_game_tick += 1
	_game_day = _game_tick / _Const.TICKS_PER_ANT_DAY
	if _brood_manager:
		_brood_manager.tick()
	if _pheromone_field:
		_pheromone_field.tick()
	if _building_pheromone:
		_building_pheromone.tick()
	for fs in _food_sources:
		if is_instance_valid(fs):
			fs.tick()
	_update_colony_stage()
	if _game_tick % 60 == 0:
		_update_hud()


func _update_colony_stage() -> void:
	if not _queen_alive:
		return
	if _first_workers_emerged:
		_colony_stage = "Ergonomic"
	else:
		_colony_stage = "Founding"


func _update_hud() -> void:
	if _hud == null:
		return
	var queen_energy: float = _queen.energy_reserve if is_instance_valid(_queen) else 0.0
	var sugar: float = _food_store.sugar if _food_store else 0.0
	var protein: float = _food_store.protein if _food_store else 0.0
	var workers: int = colony_ants.get_worker_count() if colony_ants else 0
	var brood_total: int = 0
	if _brood_manager:
		var counts: Dictionary = _brood_manager.get_counts()
		brood_total = int(counts["total"])
	_peak_workers = maxi(_peak_workers, workers)
	_hud.update_data(_game_day, _colony_stage, queen_energy, sugar, protein, workers, brood_total)


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


func _on_ant_eclosed(caste_destiny: String, pos: Vector3) -> void:
	if caste_destiny == "worker":
		if not _first_workers_emerged:
			_first_workers_emerged = true
			if is_instance_valid(_queen):
				_queen.transition_to_established()
		colony_ants.spawn_worker(pos, not _first_workers_emerged or colony_ants.get_worker_count() < 6)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_X:
			_toggle_xray()


func _toggle_xray() -> void:
	_xray_active = not _xray_active
	var active_mat: StandardMaterial3D = _mat_xray if _xray_active else _mat
	for mi in _chunk_meshes.values():
		(mi as MeshInstance3D).material_override = active_mat


func _rebuild_chunk_mesh(k: Vector2i) -> void:
	var ch = world.get_chunk(k.x, k.y)
	if ch == null:
		return
	var mi: MeshInstance3D = _chunk_meshes.get(k)
	if mi == null:
		return
	var mesh: ArrayMesh = _MeshBuilder.build_chunk_mesh(world, ch)
	mi.mesh = mesh
