extends Node
## Colony-level nest construction manager: compaction, dig front, reservations, volume, navigation.

const _Const := preload("res://scripts/constants.gd")
const _TerrainGen := preload("res://scripts/world/terrain_gen.gd")
const _SurfaceQuery := preload("res://scripts/world/surface_query.gd")
const _SpoilDeposit := preload("res://scripts/spoil_deposit.gd")

var _world: Node
var nest_entrance: Vector3i = Vector3i.ZERO
var queen_chamber: Vector3i = Vector3i.ZERO
var _dig_front: Array[Vector3i] = []
var _dig_front_set: Dictionary = {}
var _reserved_voxels: Dictionary = {}
var _nest_air_volume: int = 0
var _nest_interior_cache: Dictionary = {}
var _interior_dirty: bool = true
var _rng: RandomNumberGenerator
var _building_pheromone: Node


## Call as soon as the node exists — **before** the queen digs (she invokes **`compact_around`** during the shaft/chamber phase). Full **`setup`** still runs at **`founding_chamber_ready`** with the real chamber center.
func bind_world(world: Node) -> void:
	_world = world


func setup(world: Node, founding_chamber: Vector3i, building_pheromone: Node) -> void:
	_world = world
	queen_chamber = founding_chamber
	_building_pheromone = building_pheromone
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	var sy: int = _SurfaceQuery.surface_block_y(world, founding_chamber.x, founding_chamber.z)
	if sy < 0:
		sy = _TerrainGen.SURFACE_BASE
	nest_entrance = Vector3i(founding_chamber.x, sy, founding_chamber.z)
	_interior_dirty = true
	_rebuild_dig_front()


func compact_around(pos: Vector3i) -> void:
	if _world == null:
		return
	var r: int = _Const.COMPACTION_RADIUS
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if dx == 0 and dy == 0 and dz == 0:
					continue
				var n := Vector3i(pos.x + dx, pos.y + dy, pos.z + dz)
				if _world.get_block(n.x, n.y, n.z) == _Const.BLOCK_SAND:
					_world.set_block(n.x, n.y, n.z, _Const.BLOCK_PACKED_SAND)


func on_voxel_removed(pos: Vector3i) -> void:
	if _world == null:
		return
	compact_around(pos)
	_nest_air_volume += 1
	_interior_dirty = true
	if _dig_front_set.has(pos):
		_dig_front_set.erase(pos)
		_dig_front.erase(pos)
	for offset in [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,1,0), Vector3i(0,-1,0), Vector3i(0,0,1), Vector3i(0,0,-1)]:
		var n: Vector3i = pos + offset
		var bt: int = _world.get_block(n.x, n.y, n.z)
		if (bt == _Const.BLOCK_SAND or bt == _Const.BLOCK_PACKED_SAND) and not _dig_front_set.has(n):
			if n.y >= (_TerrainGen.SURFACE_BASE - _Const.MAX_DIG_DEPTH):
				_dig_front.append(n)
				_dig_front_set[n] = true


func on_voxel_placed(pos: Vector3i) -> void:
	_interior_dirty = true
	if _dig_front_set.has(pos):
		_dig_front_set.erase(pos)
		_dig_front.erase(pos)


func get_dig_target(ant: Node3D) -> Variant:
	if _dig_front.is_empty():
		return null
	var best_score: float = -INF
	var best_voxel: Variant = null
	var sample_count: int = mini(_dig_front.size(), 60)
	var surface_y: float = float(_TerrainGen.SURFACE_BASE)
	for _i in range(sample_count):
		var idx: int = _rng.randi_range(0, _dig_front.size() - 1)
		var v: Vector3i = _dig_front[idx]
		if _reserved_voxels.has(v):
			continue
		var bt: int = _world.get_block(v.x, v.y, v.z)
		if bt != _Const.BLOCK_SAND and bt != _Const.BLOCK_PACKED_SAND:
			continue
		var score: float = 0.0
		score += _Const.DEPTH_WEIGHT * (surface_y - float(v.y))
		var air_count: int = 0
		for offset in [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1)]:
			if _world.get_block(v.x + offset.x, v.y + offset.y, v.z + offset.z) == _Const.BLOCK_AIR:
				air_count += 1
		if air_count <= 1:
			score += _Const.TUNNEL_CONTINUE_BONUS
		if _nest_air_volume < _Const.CHAMBER_THRESHOLD:
			var dx: float = float(v.x - queen_chamber.x)
			var dz: float = float(v.z - queen_chamber.z)
			score += _Const.RADIAL_OUTWARD_BIAS * sqrt(dx * dx + dz * dz) * 0.05
		else:
			if air_count <= 1:
				score += _Const.TUNNEL_EXTEND_BIAS
		score += _rng.randf_range(-_Const.NOISE_AMPLITUDE, _Const.NOISE_AMPLITUDE)
		if score > best_score:
			best_score = score
			best_voxel = v
	return best_voxel


func reserve_voxel(voxel: Vector3i, ant: Node3D) -> void:
	_reserved_voxels[voxel] = ant


func release_voxel(voxel: Vector3i) -> void:
	_reserved_voxels.erase(voxel)


func get_nest_air_volume() -> int:
	return _nest_air_volume


func choose_deposit_position(entrance: Vector3i) -> Vector3i:
	var best_score: float = -INF
	var best_pos: Vector3i = Vector3i(entrance.x + 3, entrance.y, entrance.z)
	var radius: int = _Const.SPOIL_DEPOSIT_RADIUS
	for _i in range(20):
		var off: Vector2i = _SpoilDeposit.random_offset_disk(_rng, radius, _Const.SPOIL_DEPOSIT_INNER_CLEAR)
		var dx: int = off.x
		var dz: int = off.y
		var wx: int = entrance.x + dx
		var wz: int = entrance.z + dz
		var sy: int = _SurfaceQuery.surface_block_y(_world, wx, wz)
		if sy < 0:
			continue
		if sy - _TerrainGen.SURFACE_BASE > _Const.MAX_SPOIL_HEIGHT:
			continue
		var score: float = 0.0
		if _building_pheromone:
			score += _building_pheromone.get_build_pheromone(Vector3i(wx, sy + 1, wz)) * 3.0
		score += _rng.randf_range(-0.5, 0.5)
		if score > best_score:
			best_score = score
			best_pos = Vector3i(wx, sy + 1, wz)
	return best_pos


func get_path_to_surface(from: Vector3i) -> Array[Vector3i]:
	var path: Array[Vector3i] = []
	var current: Vector3i = from
	var surface_y: int = _TerrainGen.SURFACE_BASE + 5
	var visited: Dictionary = {}
	for _step in range(200):
		if current.y >= surface_y:
			break
		visited[current] = true
		var best: Vector3i = current
		var best_y: int = current.y
		for offset in [Vector3i(0,1,0), Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1), Vector3i(1,1,0), Vector3i(-1,1,0), Vector3i(0,1,1), Vector3i(0,1,-1)]:
			var n: Vector3i = current + offset
			if visited.has(n):
				continue
			if _world.get_block(n.x, n.y, n.z) == _Const.BLOCK_AIR:
				if n.y > best_y or (n.y == best_y and _rng.randf() < 0.3):
					best_y = n.y
					best = n
		if best == current:
			break
		path.append(best)
		current = best
	return path


func dig_duration_for(block_type: int) -> int:
	if block_type == _Const.BLOCK_PACKED_SAND:
		return _Const.DIG_ACT_DURATION_TICKS * _Const.PACKED_SAND_DIG_MULTIPLIER
	elif block_type == _Const.BLOCK_SAND:
		return _Const.DIG_ACT_DURATION_TICKS
	return 0


func _rebuild_dig_front() -> void:
	_dig_front.clear()
	_dig_front_set.clear()
	_nest_air_volume = 0
	var visited: Dictionary = {}
	var queue: Array[Vector3i] = [queen_chamber]
	visited[queen_chamber] = true
	while not queue.is_empty():
		var pos: Vector3i = queue.pop_front()
		if _world.get_block(pos.x, pos.y, pos.z) != _Const.BLOCK_AIR:
			continue
		_nest_air_volume += 1
		for offset in [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,1,0), Vector3i(0,-1,0), Vector3i(0,0,1), Vector3i(0,0,-1)]:
			var n: Vector3i = pos + offset
			if visited.has(n):
				continue
			visited[n] = true
			var bt: int = _world.get_block(n.x, n.y, n.z)
			if bt == _Const.BLOCK_AIR:
				queue.append(n)
			elif (bt == _Const.BLOCK_SAND or bt == _Const.BLOCK_PACKED_SAND) and not _dig_front_set.has(n):
				if n.y >= (_TerrainGen.SURFACE_BASE - _Const.MAX_DIG_DEPTH):
					_dig_front.append(n)
					_dig_front_set[n] = true
