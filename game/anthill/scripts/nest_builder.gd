extends Node
## Blueprint chambers (brood, storage, rest) dug by workers only on **exposed** sand (adjacent to existing air).
## Voxels must be reachable from the current **`dig_front`** frontier; interior sand is skipped until a face opens.

const _Const := preload("res://scripts/constants.gd")

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


func setup(world: Node, founding_chamber: Vector3i) -> void:
	_world = world
	_founding_chamber = founding_chamber
	_sort_origin_xz = Vector2i(founding_chamber.x, founding_chamber.z)
	_generate_blueprints()


func _generate_blueprints() -> void:
	_blueprints.clear()
	var fc := _founding_chamber
	## Offset galleries from the founding chamber so workers widen the nest instead of only deepening the shaft.
	_blueprints.append({
		"name": "brood_chamber",
		"center": Vector3i(fc.x + 5, fc.y, fc.z),
		"size": Vector3i(5, 3, 5),
		"dug": false,
	})
	_blueprints.append({
		"name": "food_storage",
		"center": Vector3i(fc.x - 5, fc.y, fc.z),
		"size": Vector3i(4, 3, 3),
		"dug": false,
	})
	_blueprints.append({
		"name": "worker_rest",
		"center": Vector3i(fc.x, fc.y, fc.z + 6),
		"size": Vector3i(4, 3, 4),
		"dug": false,
	})
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
