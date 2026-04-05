extends Node3D
## Queen ant for Lasius niger: opening cinematic (fly-in, wing shed, search, dig, claustral) and ongoing lifecycle.

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")
const _AntModelScript = preload("res://scripts/colony_ant_model.gd")
const _TerrainGen := preload("res://scripts/world/terrain_gen.gd")
const _SurfaceQuery := preload("res://scripts/world/surface_query.gd")

signal egg_laid(count: int, is_trophic: bool)
signal queen_died(cause: String)
signal founding_chamber_ready(chamber_center: Vector3i)
signal queen_state_changed(new_state: int)

enum QueenState {
	FLYING_IN,
	WING_SHEDDING,
	SEARCHING,
	DIGGING,
	CLAUSTRAL,
	ESTABLISHED,
	REPRODUCTIVE,
}

var state: int = QueenState.FLYING_IN
var energy_reserve: float = 1.0
var hunger: float = 0.0
var age_ticks: int = 0
var has_wings: bool = true

var _world: Node
var _rng: RandomNumberGenerator
var _ant_builder: RefCounted
var _ant_mesh: Node3D
var _wing_meshes: Array[MeshInstance3D] = []

## Cinematic state
var _fly_start_pos: Vector3
var _fly_end_pos: Vector3
var _fly_elapsed: float = 0.0
var _search_elapsed: float = 0.0
var _search_duration: float = 15.0
var _search_dir: Vector2 = Vector2.ZERO

## Digging state
var _dig_target: Vector3i = Vector3i.ZERO
var _dig_phase: int = 0  # 0=shaft, 1=chamber, 2=seal
var _dig_timer: float = 0.0
var _founding_chamber_center: Vector3i = Vector3i.ZERO
var _shaft_start_xz: Vector2i = Vector2i.ZERO
var _shaft_depth_dug: int = 0
var _chamber_voxels_to_dig: Array[Vector3i] = []
var _chamber_dig_idx: int = 0

## Egg laying state
var _egg_timer_ticks: int = 0
var _first_egg_batch_laid: bool = false

## Ant position in world coords
var _wx: int = 0
var _wz: int = 0
var _nest_manager: Node

const _ANT_LOCAL_Y_MIN: float = -0.28


func setup(world: Node, nest_manager: Node = null) -> void:
	_world = world
	_nest_manager = nest_manager
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_ant_builder = _AntModelScript.new() as RefCounted
	_search_duration = _rng.randf_range(_Const.QUEEN_SEARCH_DURATION_MIN, _Const.QUEEN_SEARCH_DURATION_MAX)
	_build_queen_mesh()
	_setup_fly_in()


func _build_queen_mesh() -> void:
	_ant_mesh = _ant_builder.build_ant()
	_ant_mesh.scale = Vector3.ONE * _Const.QUEEN_VISUAL_SCALE
	add_child(_ant_mesh)
	_add_wings()


func _add_wings() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.88, 0.92, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for sx in [-1.0, 1.0]:
		var wing := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.22, 0.005, 0.35)
		wing.mesh = bm
		wing.material_override = mat
		wing.position = Vector3(sx * 0.12, 0.16, -0.05)
		wing.rotation_degrees = Vector3(8.0, sx * 15.0, sx * 12.0)
		_ant_mesh.add_child(wing)
		_wing_meshes.append(wing)


func _setup_fly_in() -> void:
	var max_x: int = _world.chunks_x * _Chunk.SIZE_X
	var max_z: int = _world.chunks_z * _Chunk.SIZE_Z
	var cx: float = float(max_x) * 0.5
	var cz: float = float(max_z) * 0.5
	var land_x: float = cx + _rng.randf_range(-40.0, 40.0)
	var land_z: float = cz + _rng.randf_range(-40.0, 40.0)
	_wx = int(land_x)
	_wz = int(land_z)
	_wx = clampi(_wx, 10, max_x - 10)
	_wz = clampi(_wz, 10, max_z - 10)
	var sy: int = _surface_y(_wx, _wz)
	if sy < 0:
		sy = _TerrainGen.SURFACE_BASE
	var surface_top: float = float(sy) + 1.0
	_fly_end_pos = Vector3(float(_wx) + 0.5, surface_top - _ANT_LOCAL_Y_MIN * _Const.QUEEN_VISUAL_SCALE, float(_wz) + 0.5)
	_fly_start_pos = _fly_end_pos + Vector3(_rng.randf_range(-80.0, 80.0), 120.0, _rng.randf_range(-80.0, 80.0))
	position = _fly_start_pos
	_fly_elapsed = 0.0


func _surface_y(wx: int, wz: int) -> int:
	return _SurfaceQuery.surface_block_y(_world, wx, wz)


func _physics_process(delta: float) -> void:
	age_ticks += 1
	match state:
		QueenState.FLYING_IN:
			_process_fly_in(delta)
		QueenState.WING_SHEDDING:
			_process_wing_shed(delta)
		QueenState.SEARCHING:
			_process_searching(delta)
		QueenState.DIGGING:
			_process_digging(delta)
		QueenState.CLAUSTRAL:
			_process_claustral(delta)
		QueenState.ESTABLISHED:
			_process_established(delta)


func _set_state(s: int) -> void:
	state = s
	queen_state_changed.emit(s)


func _process_fly_in(delta: float) -> void:
	_fly_elapsed += delta
	var t: float = clampf(_fly_elapsed / _Const.QUEEN_FLY_IN_DURATION, 0.0, 1.0)
	var ease_t: float = t * t * (3.0 - 2.0 * t)
	position = _fly_start_pos.lerp(_fly_end_pos, ease_t)
	if t >= 1.0:
		position = _fly_end_pos
		_spawn_dust_puff()
		_set_state(QueenState.WING_SHEDDING)
		_fly_elapsed = 0.0


func _spawn_dust_puff() -> void:
	var puff := GPUParticles3D.new()
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 2.0
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 8.0
	mat.gravity = Vector3(0, -12, 0)
	mat.damping_min = 2.0
	mat.damping_max = 5.0
	mat.scale_min = 0.5
	mat.scale_max = 2.0
	mat.color = Color(0.82, 0.74, 0.58, 0.7)
	puff.process_material = mat
	puff.amount = 20
	puff.lifetime = 1.2
	puff.one_shot = true
	puff.emitting = true
	var draw_pass := SphereMesh.new()
	draw_pass.radius = 0.3
	draw_pass.height = 0.6
	puff.draw_pass_1 = draw_pass
	add_child(puff)
	puff.position = Vector3.ZERO
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(puff.queue_free)


func _process_wing_shed(delta: float) -> void:
	_fly_elapsed += delta
	var t: float = clampf(_fly_elapsed / _Const.QUEEN_WING_SHED_DURATION, 0.0, 1.0)
	for w in _wing_meshes:
		if is_instance_valid(w):
			w.position.y -= delta * 0.04
			var mat: StandardMaterial3D = w.material_override as StandardMaterial3D
			if mat:
				mat.albedo_color.a = maxf(0.0, 0.45 * (1.0 - t))
	if t >= 1.0:
		for w in _wing_meshes:
			if is_instance_valid(w):
				w.queue_free()
		_wing_meshes.clear()
		has_wings = false
		_set_state(QueenState.SEARCHING)
		_search_elapsed = 0.0
		_search_dir = Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)).normalized()


func _process_searching(delta: float) -> void:
	_search_elapsed += delta
	if _search_elapsed >= _search_duration:
		_begin_digging()
		return
	_dig_timer += delta
	if _dig_timer < _Const.QUEEN_SEARCH_MOVE_INTERVAL:
		return
	_dig_timer = 0.0
	if _rng.randf() < 0.3:
		_search_dir = _search_dir.rotated(_rng.randf_range(-1.0, 1.0))
	var dx: int = 1 if _search_dir.x > 0.3 else (-1 if _search_dir.x < -0.3 else 0)
	var dz: int = 1 if _search_dir.y > 0.3 else (-1 if _search_dir.y < -0.3 else 0)
	if dx == 0 and dz == 0:
		dx = 1
	var nwx: int = _wx + dx
	var nwz: int = _wz + dz
	var max_x: int = _world.chunks_x * _Chunk.SIZE_X
	var max_z: int = _world.chunks_z * _Chunk.SIZE_Z
	if nwx < 5 or nwz < 5 or nwx >= max_x - 5 or nwz >= max_z - 5:
		_search_dir = -_search_dir
		return
	var sy: int = _surface_y(nwx, nwz)
	if sy < 0:
		return
	_wx = nwx
	_wz = nwz
	_place_on_surface(sy)


func _place_on_surface(sy: int) -> void:
	var surface_top: float = float(sy) + 1.0
	position = Vector3(float(_wx) + 0.5, surface_top - _ANT_LOCAL_Y_MIN * _Const.QUEEN_VISUAL_SCALE, float(_wz) + 0.5)
	if _ant_mesh:
		_ant_mesh.rotation.y = atan2(_search_dir.x, _search_dir.y)


func _begin_digging() -> void:
	_shaft_start_xz = Vector2i(_wx, _wz)
	_shaft_depth_dug = 0
	_dig_phase = 0
	_dig_timer = 0.0
	_set_state(QueenState.DIGGING)


func _process_digging(delta: float) -> void:
	_dig_timer += delta
	if _dig_timer < _Const.QUEEN_DIG_INTERVAL:
		return
	_dig_timer = 0.0

	if _dig_phase == 0:
		_dig_shaft_step()
	elif _dig_phase == 1:
		_dig_chamber_step()
	elif _dig_phase == 2:
		_seal_entrance()


func _dig_shaft_step() -> void:
	if _shaft_depth_dug >= _Const.FOUNDING_SHAFT_DEPTH:
		_prepare_chamber_dig()
		return
	var sy: int = _surface_y(_shaft_start_xz.x, _shaft_start_xz.y)
	if sy < 0:
		sy = _TerrainGen.SURFACE_BASE - 1
	var target_y: int = sy - _shaft_depth_dug
	if target_y < 1:
		_prepare_chamber_dig()
		return
	var hw: int = _Const.FOUNDING_SHAFT_WIDTH / 2
	for dx in range(-hw, hw):
		for dz in range(-hw, hw):
			var wx: int = _shaft_start_xz.x + dx
			var wz: int = _shaft_start_xz.y + dz
			if _world.get_block(wx, target_y, wz) != _Const.BLOCK_AIR:
				_world.set_block(wx, target_y, wz, _Const.BLOCK_AIR)
				if _nest_manager:
					_nest_manager.compact_around(Vector3i(wx, target_y, wz))
	_shaft_depth_dug += 1
	position = Vector3(float(_shaft_start_xz.x) + 0.5, float(target_y) + 0.5, float(_shaft_start_xz.y) + 0.5)


func _prepare_chamber_dig() -> void:
	_dig_phase = 1
	var sy: int = _surface_y(_shaft_start_xz.x, _shaft_start_xz.y)
	if sy < 0:
		sy = _TerrainGen.SURFACE_BASE - 1
	var shaft_bottom_y: int = sy - _shaft_depth_dug + 1
	var ch_size: Vector3i = _Const.FOUNDING_CHAMBER_SIZE
	var cx: int = _shaft_start_xz.x - ch_size.x / 2
	var cy: int = shaft_bottom_y - ch_size.y
	var cz: int = _shaft_start_xz.y - ch_size.z / 2
	_founding_chamber_center = Vector3i(cx + ch_size.x / 2, cy + ch_size.y / 2, cz + ch_size.z / 2)
	_chamber_voxels_to_dig.clear()
	for dx in range(ch_size.x):
		for dy in range(ch_size.y):
			for dz in range(ch_size.z):
				_chamber_voxels_to_dig.append(Vector3i(cx + dx, cy + dy, cz + dz))
	_chamber_dig_idx = 0


func _dig_chamber_step() -> void:
	if _chamber_dig_idx >= _chamber_voxels_to_dig.size():
		_dig_phase = 2
		return
	var p: Vector3i = _chamber_voxels_to_dig[_chamber_dig_idx]
	if _world.get_block(p.x, p.y, p.z) != _Const.BLOCK_AIR:
		_world.set_block(p.x, p.y, p.z, _Const.BLOCK_AIR)
		if _nest_manager:
			_nest_manager.compact_around(p)
	_chamber_dig_idx += 1
	position = Vector3(float(p.x) + 0.5, float(p.y) + 0.5, float(p.z) + 0.5)


func _seal_entrance() -> void:
	var sy: int = _surface_y(_shaft_start_xz.x, _shaft_start_xz.y)
	if sy >= 0:
		_world.set_block(_shaft_start_xz.x, sy + 1, _shaft_start_xz.y, _Const.BLOCK_SAND)
	position = Vector3(
		float(_founding_chamber_center.x) + 0.5,
		float(_founding_chamber_center.y) + 0.5,
		float(_founding_chamber_center.z) + 0.5
	)
	_set_state(QueenState.CLAUSTRAL)
	_egg_timer_ticks = 0
	founding_chamber_ready.emit(_founding_chamber_center)


func _process_claustral(_delta: float) -> void:
	energy_reserve -= _Const.QUEEN_CLAUSTRAL_ENERGY_DRAIN_PER_TICK
	if energy_reserve <= 0.0:
		energy_reserve = 0.0
		queen_died.emit("Colony failed to establish. 99% of queens never found a colony.")
		return
	_egg_timer_ticks += 1
	if not _first_egg_batch_laid and _egg_timer_ticks >= _Const.TICKS_PER_ANT_DAY:
		_lay_claustral_eggs()
		_first_egg_batch_laid = true
		_egg_timer_ticks = 0
	elif _first_egg_batch_laid and _egg_timer_ticks >= _Const.QUEEN_CLAUSTRAL_EGG_INTERVAL_TICKS:
		_lay_claustral_eggs()
		_egg_timer_ticks = 0


func _lay_claustral_eggs() -> void:
	var batch: int = _rng.randi_range(_Const.QUEEN_CLAUSTRAL_EGG_BATCH_MIN, _Const.QUEEN_CLAUSTRAL_EGG_BATCH_MAX)
	var trophic_count: int = maxi(1, batch / 3)
	var worker_count: int = batch - trophic_count
	if trophic_count > 0:
		egg_laid.emit(trophic_count, true)
	if worker_count > 0:
		egg_laid.emit(worker_count, false)


func _process_established(_delta: float) -> void:
	_egg_timer_ticks += 1
	if _egg_timer_ticks >= _Const.QUEEN_ESTABLISHED_EGG_INTERVAL_TICKS:
		var batch: int = _rng.randi_range(4, 10)
		egg_laid.emit(batch, false)
		_egg_timer_ticks = 0


func transition_to_established() -> void:
	if state == QueenState.CLAUSTRAL:
		_set_state(QueenState.ESTABLISHED)
		_egg_timer_ticks = 0


func get_chamber_center() -> Vector3i:
	return _founding_chamber_center
