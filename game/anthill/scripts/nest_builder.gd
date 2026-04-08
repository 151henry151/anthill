extends Node
## Blueprint chambers (brood, storage, rest) dug by workers only on **exposed** sand (adjacent to existing air).
## Voxels must be reachable from the current **`dig_front`** frontier; interior sand is skipped until a face opens.

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")

const _NEIGH6: Array[Vector3i] = [
	Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
	Vector3i(0, 1, 0), Vector3i(0, -1, 0),
	Vector3i(0, 0, 1), Vector3i(0, 0, -1),
]

var _world: Node
var _founding_chamber: Vector3i = Vector3i.ZERO
## Horizontal reference for sorting (grow galleries from the founding chamber center).
var _sort_origin_xz: Vector2i = Vector2i.ZERO
var _blueprints: Array[Dictionary] = []
var _current_blueprint_idx: int = 0
var _rng: RandomNumberGenerator


func setup(world: Node, founding_chamber: Vector3i) -> void:
	_world = world
	_founding_chamber = founding_chamber
	_sort_origin_xz = Vector2i(founding_chamber.x, founding_chamber.z)
	if _rng == null:
		_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_generate_blueprints()


func _world_max_xz() -> Vector2i:
	var cx: Variant = _world.get("chunks_x") if _world else null
	var cz: Variant = _world.get("chunks_z") if _world else null
	if cx == null or cz == null:
		return Vector2i(512, 512)
	return Vector2i(int(cx) * _Chunk.SIZE_X, int(cz) * _Chunk.SIZE_Z)


func _clamp_blueprint_center(center: Vector3i, sz: Vector3i, fc_y: int, max_xz: Vector2i) -> Vector3i:
	var hx: int = sz.x / 2
	var hy: int = sz.y / 2
	var hz: int = sz.z / 2
	var cx: int = clampi(center.x, hx + 2, maxi(0, max_xz.x - hx - 3))
	var cz: int = clampi(center.z, hz + 2, maxi(0, max_xz.y - hz - 3))
	var cy: int = clampi(center.y, hy + 2, _Chunk.SIZE_Y - hy - 4)
	cy = clampi(cy, fc_y - 3, fc_y + 3)
	return Vector3i(cx, cy, cz)


func _append_blueprint(name: String, center: Vector3i, size: Vector3i) -> void:
	var fc_y: int = _founding_chamber.y
	var max_xz: Vector2i = _world_max_xz()
	var c: Vector3i = _clamp_blueprint_center(center, size, fc_y, max_xz)
	_blueprints.append({
		"name": name,
		"center": c,
		"size": size,
		"dug": false,
	})


func _generate_blueprints() -> void:
	_blueprints.clear()
	var fc := _founding_chamber
	## Three chambers at ~120° with jitter and a random global rotation (not fixed +X / −X / +Z).
	var global_rot: float = _rng.randf() * _Const.NEST_BLUEPRINT_GLOBAL_ROT_MAX
	var slot_sep: float = 6.28318530718 / 3.0
	var specs: Array = [
		{"name": "brood_chamber", "sx": Vector2i(4, 6), "sy": Vector2i(2, 4), "sz": Vector2i(4, 6)},
		{"name": "food_storage", "sx": Vector2i(3, 5), "sy": Vector2i(2, 3), "sz": Vector2i(3, 4)},
		{"name": "worker_rest", "sx": Vector2i(3, 5), "sy": Vector2i(2, 3), "sz": Vector2i(3, 5)},
	]
	for i in range(specs.size()):
		var ang: float = global_rot + float(i) * slot_sep + _rng.randf_range(-_Const.NEST_BLUEPRINT_ANGLE_JITTER, _Const.NEST_BLUEPRINT_ANGLE_JITTER)
		var dist: int = _rng.randi_range(_Const.NEST_BLUEPRINT_DIST_MIN, _Const.NEST_BLUEPRINT_DIST_MAX)
		var ox: int = int(round(cos(ang) * float(dist)))
		var oz: int = int(round(sin(ang) * float(dist)))
		var dy: int = _rng.randi_range(-1, 1)
		var sp: Dictionary = specs[i]
		var sx: int = _rng.randi_range(int(sp["sx"].x), int(sp["sx"].y))
		var sy: int = _rng.randi_range(int(sp["sy"].x), int(sp["sy"].y))
		var sz: int = _rng.randi_range(int(sp["sz"].x), int(sp["sz"].y))
		var center := Vector3i(fc.x + ox, fc.y + dy, fc.z + oz)
		var size := Vector3i(sx, sy, sz)
		_append_blueprint(str(sp["name"]), center, size)
	if _rng.randf() < _Const.NEST_BLUEPRINT_SPUR_PROB:
		var spur_ang: float = _rng.randf() * 6.28318530718
		var spur_d: int = _rng.randi_range(2, 5)
		var sox: int = int(round(cos(spur_ang) * float(spur_d)))
		var soz: int = int(round(sin(spur_ang) * float(spur_d)))
		var spur_c := Vector3i(fc.x + sox, fc.y + _rng.randi_range(-1, 1), fc.z + soz)
		var spur_sz := Vector3i(_rng.randi_range(2, 3), 2, _rng.randi_range(2, 3))
		_append_blueprint("gallery_spur", spur_c, spur_sz)
	_current_blueprint_idx = 0


func _adjacent_to_air(p: Vector3i) -> bool:
	for d in _NEIGH6:
		var n := Vector3i(p.x + d.x, p.y + d.y, p.z + d.z)
		if _world.get_block(n.x, n.y, n.z) == _Const.BLOCK_AIR:
			return true
	return false


func _blueprint_all_air(bp: Dictionary) -> bool:
	var center: Vector3i = bp["center"]
	var sz: Vector3i = bp["size"]
	var hx: int = sz.x / 2
	var hy: int = sz.y / 2
	var hz: int = sz.z / 2
	for dx in range(-hx, hx + 1):
		for dy in range(-hy, hy + 1):
			for dz in range(-hz, hz + 1):
				var p := Vector3i(center.x + dx, center.y + dy, center.z + dz)
				if _world.get_block(p.x, p.y, p.z) != _Const.BLOCK_AIR:
					return false
	return true


func _refresh_blueprint_completion() -> void:
	for bp in _blueprints:
		if bool(bp["dug"]):
			continue
		if _blueprint_all_air(bp):
			bp["dug"] = true


func _collect_exposed_in_blueprint(bp: Dictionary, nest_manager: Node) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var center: Vector3i = bp["center"]
	var sz: Vector3i = bp["size"]
	var hx: int = sz.x / 2
	var hy: int = sz.y / 2
	var hz: int = sz.z / 2
	for dx in range(-hx, hx + 1):
		for dy in range(-hy, hy + 1):
			for dz in range(-hz, hz + 1):
				var p := Vector3i(center.x + dx, center.y + dy, center.z + dz)
				var bt: int = _world.get_block(p.x, p.y, p.z)
				if bt != _Const.BLOCK_SAND and bt != _Const.BLOCK_PACKED_SAND:
					continue
				if not _adjacent_to_air(p):
					continue
				if nest_manager and nest_manager.has_method("is_voxel_reserved") and nest_manager.is_voxel_reserved(p):
					continue
				out.append(p)
	return out


func _horiz_manhattan(p: Vector3i) -> int:
	return absi(p.x - _sort_origin_xz.x) + absi(p.z - _sort_origin_xz.y)


## Prefer voxels **closer** to the founding chamber in XZ (connect galleries first), then lower **depth cost** (higher **y** when y is up).
func _sort_candidates(candidates: Array[Vector3i]) -> void:
	candidates.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		var ma: int = _horiz_manhattan(a)
		var mb: int = _horiz_manhattan(b)
		if ma != mb:
			return ma < mb
		return a.y > b.y
	)


## Next blueprint dig target, or **`null`** if blueprints are empty / waiting for exposure. Pass **`nest_manager`** for reservations.
func get_next_dig_target(nest_manager: Node) -> Variant:
	if _world == null:
		return null
	_refresh_blueprint_completion()
	for bp_idx in range(_blueprints.size()):
		var bp: Dictionary = _blueprints[bp_idx]
		if bool(bp["dug"]):
			continue
		if _blueprint_all_air(bp):
			bp["dug"] = true
			continue
		var candidates: Array[Vector3i] = _collect_exposed_in_blueprint(bp, nest_manager)
		if candidates.is_empty():
			continue
		_sort_candidates(candidates)
		return candidates[0]
	return null


func has_work() -> bool:
	if _world == null:
		return false
	_refresh_blueprint_completion()
	## Peek without **`nest_manager`**: ignore reservations (still useful for “is any blueprint exposed?”).
	var nm: Node = null
	for bp in _blueprints:
		if bool(bp["dug"]):
			continue
		if _blueprint_all_air(bp):
			continue
		var c: Array[Vector3i] = _collect_exposed_in_blueprint(bp, nm)
		if not c.is_empty():
			return true
	return false


## Horizontal projection bonus for **`nest_manager.get_dig_target`**: reward frontier sand that lies **outward** from the founding chamber toward an **incomplete** blueprint center (tunnels reach planned chambers sooner than pure lateral noise).
func score_blueprint_lead(v: Vector3i) -> float:
	if _world == null or _blueprints.is_empty():
		return 0.0
	_refresh_blueprint_completion()
	var best: float = 0.0
	var fc: Vector3i = _founding_chamber
	for bp in _blueprints:
		if bool(bp["dug"]):
			continue
		var center: Vector3i = bp["center"]
		var dx: float = float(center.x - fc.x)
		var dz: float = float(center.z - fc.z)
		var len_h: float = sqrt(dx * dx + dz * dz)
		if len_h < 0.75:
			continue
		dx /= len_h
		dz /= len_h
		var vx: float = float(v.x - fc.x)
		var vz: float = float(v.z - fc.z)
		var proj: float = vx * dx + vz * dz
		if proj > 0.0:
			best = maxf(best, proj * _Const.NEST_BLUEPRINT_LEAD_WEIGHT)
	return best
