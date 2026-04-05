extends Node3D
## Queen ant for Lasius niger: opening cinematic (fly-in, wing shed, search, dig, claustral) and ongoing lifecycle.

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")
const _AntModelScript = preload("res://scripts/colony_ant_model.gd")
const _TerrainGen := preload("res://scripts/world/terrain_gen.gd")
const _SurfaceQuery := preload("res://scripts/world/surface_query.gd")
const _SpoilDeposit := preload("res://scripts/spoil_deposit.gd")

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
enum _QueenDigSub { APPROACH, DIG_ACT, CARRY_UP }

const _QUEEN_DIG_SENTINEL := Vector3i(-99999, -99999, -99999)
const _NEIGH6: Array[Vector3i] = [
	Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
	Vector3i(0, 1, 0), Vector3i(0, -1, 0),
	Vector3i(0, 0, 1), Vector3i(0, 0, -1),
]

var _dig_phase: int = 0  # 0=shaft, 1=chamber, 2=seal
var _dig_timer: float = 0.0
var _dig_sub: int = _QueenDigSub.APPROACH
var _dig_path: Array[Vector3i] = []
var _dig_path_idx: int = 0
var _pending_voxel: Vector3i = Vector3i.ZERO
var _dig_act_ticks: int = 0
var _dig_act_max_ticks: int = 1
## Integer cell the queen occupies during excavation (pathfinding / carry).
var _queen_cell: Vector3i = Vector3i.ZERO
var _shaft_layer_queue: Array[Vector3i] = []
var _carry_visual: MeshInstance3D
var _founding_chamber_center: Vector3i = Vector3i.ZERO
var _shaft_start_xz: Vector2i = Vector2i.ZERO
## Surface block Y at shaft center when digging starts (stable for whole shaft; avoids `get_surface_y` jumping after the hole is carved).
var _shaft_top_y: int = 0
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


## Inclusive range [lo, hi) for shaft dx/dz so an even `FOUNDING_SHAFT_WIDTH` is centered on `(_wx, _wz)`.
func _founding_shaft_lo() -> int:
	var w: int = _Const.FOUNDING_SHAFT_WIDTH
	return -w / 2 + 1


func _founding_shaft_hi() -> int:
	var w: int = _Const.FOUNDING_SHAFT_WIDTH
	return w / 2 + 1


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
	_carry_visual = MeshInstance3D.new()
	var carry_mesh := BoxMesh.new()
	carry_mesh.size = Vector3(0.55, 0.55, 0.55)
	_carry_visual.mesh = carry_mesh
	var carry_mat := StandardMaterial3D.new()
	carry_mat.albedo_color = Color(0.92, 0.82, 0.62)
	carry_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_carry_visual.material_override = carry_mat
	_carry_visual.position = Vector3(0, 0.55, 0.45)
	_carry_visual.visible = false
	_ant_mesh.add_child(_carry_visual)
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
	if _world.has_method("get_surface_y"):
		return _world.get_surface_y(wx, wz)
	return _SurfaceQuery.surface_block_y(_world, wx, wz)


## While true, `main_controller` skips falling-sand so loose sand cannot refill the shaft between dig ticks.
func sand_physics_suppressed() -> bool:
	return state == QueenState.DIGGING


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
	var sy0: int = _surface_y(_wx, _wz)
	if sy0 < 0:
		sy0 = _TerrainGen.SURFACE_BASE - 1
	_shaft_top_y = sy0
	_shaft_depth_dug = 0
	_shaft_layer_queue.clear()
	_dig_phase = 0
	_dig_timer = 0.0
	# Stand in the open air cell above the surface block (same feet height as search / `_place_on_surface`).
	_queen_cell = Vector3i(_wx, _shaft_top_y + 1, _wz)
	_apply_queen_cell_pos()
	_set_state(QueenState.DIGGING)
	var first: Vector3i = _pop_next_dig_voxel()
	if first == _QUEEN_DIG_SENTINEL:
		_seal_entrance()
		return
	_start_dig_cycle(first)


func _process_digging(delta: float) -> void:
	_dig_timer += delta
	match _dig_sub:
		_QueenDigSub.APPROACH:
			if _dig_timer < _Const.WORKER_MOVE_INTERVAL:
				return
			_dig_timer = 0.0
			_step_approach()
		_QueenDigSub.DIG_ACT:
			if _dig_timer < _Const.QUEEN_DIG_ACT_TICK_INTERVAL:
				return
			_dig_timer = 0.0
			_dig_act_ticks += 1
			if _dig_act_ticks >= _dig_act_max_ticks:
				_complete_dig_act()
		_QueenDigSub.CARRY_UP:
			if _dig_timer < _Const.WORKER_MOVE_INTERVAL:
				return
			_dig_timer = 0.0
			_step_carry_up()


func _start_dig_cycle(v: Vector3i) -> void:
	_pending_voxel = v
	var goals: Dictionary = {}
	for off in _NEIGH6:
		var n: Vector3i = v + off
		if _world.get_block(n.x, n.y, n.z) == _Const.BLOCK_AIR:
			goals[n] = true
	if goals.is_empty():
		_dig_sub = _QueenDigSub.DIG_ACT
		_queen_cell = v
		_apply_queen_cell_pos()
		_begin_dig_act_ticks()
		return
	if goals.has(_queen_cell):
		_dig_sub = _QueenDigSub.DIG_ACT
		_queen_cell = v
		_apply_queen_cell_pos()
		_begin_dig_act_ticks()
		return
	var path: Array[Vector3i] = _bfs_path_air(_queen_cell, goals)
	if path.is_empty():
		_dig_sub = _QueenDigSub.DIG_ACT
		_queen_cell = v
		_apply_queen_cell_pos()
		_begin_dig_act_ticks()
		return
	_dig_path = path
	_dig_path_idx = 0
	_dig_sub = _QueenDigSub.APPROACH
	_dig_timer = _Const.WORKER_MOVE_INTERVAL


func _step_approach() -> void:
	if _dig_path_idx >= _dig_path.size():
		_dig_sub = _QueenDigSub.DIG_ACT
		_queen_cell = _pending_voxel
		_apply_queen_cell_pos()
		_begin_dig_act_ticks()
		return
	var prev: Vector3i = _queen_cell
	var next: Vector3i = _dig_path[_dig_path_idx]
	_dig_path_idx += 1
	_queen_cell = next
	_apply_queen_cell_pos()
	var dx: int = next.x - prev.x
	var dz: int = next.z - prev.z
	if _ant_mesh and (dx != 0 or dz != 0):
		_ant_mesh.rotation.y = atan2(float(dx), float(dz))


func _begin_dig_act_ticks() -> void:
	_dig_act_ticks = 0
	_dig_timer = _Const.QUEEN_DIG_ACT_TICK_INTERVAL
	var bt: int = _world.get_block(_pending_voxel.x, _pending_voxel.y, _pending_voxel.z)
	if _nest_manager:
		_dig_act_max_ticks = maxi(1, _nest_manager.dig_duration_for(bt))
	else:
		_dig_act_max_ticks = maxi(1, _Const.DIG_ACT_DURATION_TICKS)


func _complete_dig_act() -> void:
	var v: Vector3i = _pending_voxel
	if _world.get_block(v.x, v.y, v.z) != _Const.BLOCK_AIR:
		_world.set_block(v.x, v.y, v.z, _Const.BLOCK_AIR)
		if _nest_manager:
			_nest_manager.on_voxel_removed(v)
	if _carry_visual:
		_carry_visual.visible = true
	_queen_cell = v
	_apply_queen_cell_pos()
	_start_carry_up(v)


func _start_carry_up(from_air: Vector3i) -> void:
	if _nest_manager and _nest_manager.has_method("get_path_to_surface"):
		_dig_path = _nest_manager.get_path_to_surface(from_air)
	else:
		_dig_path = []
	_dig_path_idx = 0
	_dig_sub = _QueenDigSub.CARRY_UP
	_dig_timer = _Const.WORKER_MOVE_INTERVAL
	if _dig_path.is_empty():
		_deposit_and_continue()


func _step_carry_up() -> void:
	if _dig_path_idx >= _dig_path.size():
		_deposit_and_continue()
		return
	var prev: Vector3i = _queen_cell
	var next: Vector3i = _dig_path[_dig_path_idx]
	_dig_path_idx += 1
	_queen_cell = next
	_apply_queen_cell_pos()
	var dx: int = next.x - prev.x
	var dz: int = next.z - prev.z
	if _ant_mesh and (dx != 0 or dz != 0):
		_ant_mesh.rotation.y = atan2(float(dx), float(dz))


func _deposit_and_continue() -> void:
	var dep: Vector3i = _choose_queen_deposit_pos()
	if _world.get_block(dep.x, dep.y, dep.z) == _Const.BLOCK_AIR:
		_world.set_block(dep.x, dep.y, dep.z, _Const.BLOCK_SAND)
	if _carry_visual:
		_carry_visual.visible = false
	var sy: int = _surface_y(dep.x, dep.z)
	if sy >= 0:
		_queen_cell = Vector3i(dep.x, sy + 1, dep.z)
		_apply_queen_cell_pos()
	var next_v: Vector3i = _pop_next_dig_voxel()
	if next_v == _QUEEN_DIG_SENTINEL:
		_seal_entrance()
		return
	_start_dig_cycle(next_v)


func _choose_queen_deposit_pos() -> Vector3i:
	var r: int = _Const.SPOIL_DEPOSIT_RADIUS
	var inner_clear: float = _Const.SPOIL_DEPOSIT_INNER_CLEAR
	for _i in range(40):
		var off: Vector2i = _SpoilDeposit.random_offset_disk(_rng, r, inner_clear)
		var wx: int = _shaft_start_xz.x + off.x
		var wz: int = _shaft_start_xz.y + off.y
		var sy: int = _surface_y(wx, wz)
		if sy < 0:
			continue
		return Vector3i(wx, sy + 1, wz)
	var sy0: int = _surface_y(_shaft_start_xz.x, _shaft_start_xz.y)
	if sy0 < 0:
		sy0 = _TerrainGen.SURFACE_BASE
	var fallback: Vector2i = _SpoilDeposit.random_offset_disk(_rng, r, inner_clear)
	return Vector3i(_shaft_start_xz.x + fallback.x, sy0 + 1, _shaft_start_xz.y + fallback.y)


## `_queen_cell` is the voxel index of the cell the queen occupies (usually air). The model origin is the
## body center with feet near local **`_ANT_LOCAL_Y_MIN` × scale**, so we must not use raw voxel centers on Y
## (that buried the mesh one voxel deep inside solid terrain).
func _apply_queen_cell_pos() -> void:
	var c: Vector3i = _queen_cell
	position = Vector3(
		float(c.x) + 0.5,
		float(c.y) - _ANT_LOCAL_Y_MIN * _Const.QUEEN_VISUAL_SCALE,
		float(c.z) + 0.5
	)


func _bfs_path_air(from: Vector3i, goals: Dictionary) -> Array[Vector3i]:
	if goals.has(from):
		return []
	var q: Array[Vector3i] = [from]
	var came_from: Dictionary = {}
	came_from[from] = from
	var head: int = 0
	while head < q.size():
		var cur: Vector3i = q[head]
		head += 1
		for off in _NEIGH6:
			var n: Vector3i = cur + off
			if came_from.has(n):
				continue
			if _world.get_block(n.x, n.y, n.z) != _Const.BLOCK_AIR:
				continue
			came_from[n] = cur
			if goals.has(n):
				return _reconstruct_bfs_path(came_from, from, n)
			q.append(n)
	return []


func _reconstruct_bfs_path(came_from: Dictionary, from: Vector3i, to: Vector3i) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var cur: Vector3i = to
	while cur != from:
		out.push_front(cur)
		cur = came_from[cur]
	return out


func _refill_shaft_queue_if_needed() -> void:
	var lo: int = _founding_shaft_lo()
	var hi: int = _founding_shaft_hi()
	while _shaft_layer_queue.is_empty() and _shaft_depth_dug < _Const.FOUNDING_SHAFT_DEPTH:
		var y: int = _shaft_top_y - _shaft_depth_dug
		if y < 1:
			_shaft_depth_dug += 1
			continue
		for dx in range(lo, hi):
			for dz in range(lo, hi):
				var v := Vector3i(_shaft_start_xz.x + dx, y, _shaft_start_xz.y + dz)
				if _world.get_block(v.x, v.y, v.z) != _Const.BLOCK_AIR:
					_shaft_layer_queue.append(v)
		if _shaft_layer_queue.is_empty():
			_shaft_depth_dug += 1


func _pop_next_shaft_voxel() -> Vector3i:
	_refill_shaft_queue_if_needed()
	if _shaft_layer_queue.is_empty():
		return _QUEEN_DIG_SENTINEL
	return _shaft_layer_queue.pop_front()


func _pop_next_dig_voxel() -> Vector3i:
	if _dig_phase == 0:
		var v: Vector3i = _pop_next_shaft_voxel()
		if v != _QUEEN_DIG_SENTINEL:
			return v
		_prepare_chamber_dig()
		_dig_phase = 1
	if _dig_phase == 1:
		while _chamber_dig_idx < _chamber_voxels_to_dig.size():
			var c: Vector3i = _chamber_voxels_to_dig[_chamber_dig_idx]
			_chamber_dig_idx += 1
			if _world.get_block(c.x, c.y, c.z) != _Const.BLOCK_AIR:
				return c
		_dig_phase = 2
	return _QUEEN_DIG_SENTINEL


func _prepare_chamber_dig() -> void:
	var sy: int = _shaft_top_y
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


func _seal_entrance() -> void:
	# Plug the full shaft mouth with packed sand so loose sand physics cannot refill the shaft.
	var lo: int = _founding_shaft_lo()
	var hi: int = _founding_shaft_hi()
	for dx in range(lo, hi):
		for dz in range(lo, hi):
			var wx: int = _shaft_start_xz.x + dx
			var wz: int = _shaft_start_xz.y + dz
			if _world.get_block(wx, _shaft_top_y, wz) == _Const.BLOCK_AIR:
				_world.set_block(wx, _shaft_top_y, wz, _Const.BLOCK_PACKED_SAND)
				if _nest_manager:
					_nest_manager.compact_around(Vector3i(wx, _shaft_top_y, wz))
	_queen_cell = _founding_chamber_center
	_apply_queen_cell_pos()
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
