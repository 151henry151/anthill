extends Node
## Manages nest architecture: blueprint chambers and worker dig targets.

const _Const := preload("res://scripts/constants.gd")

var _world: Node
var _founding_chamber: Vector3i = Vector3i.ZERO
var _blueprints: Array[Dictionary] = []
var _current_blueprint_idx: int = 0


func setup(world: Node, founding_chamber: Vector3i) -> void:
	_world = world
	_founding_chamber = founding_chamber
	_generate_blueprints()


func _generate_blueprints() -> void:
	_blueprints.clear()
	var fc := _founding_chamber
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


func get_next_dig_target() -> Variant:
	while _current_blueprint_idx < _blueprints.size():
		var bp: Dictionary = _blueprints[_current_blueprint_idx]
		if bool(bp["dug"]):
			_current_blueprint_idx += 1
			continue
		var center: Vector3i = bp["center"]
		var sz: Vector3i = bp["size"]
		var hx: int = sz.x / 2
		var hy: int = sz.y / 2
		var hz: int = sz.z / 2
		for dx in range(-hx, hx + 1):
			for dy in range(-hy, hy + 1):
				for dz in range(-hz, hz + 1):
					var p := Vector3i(center.x + dx, center.y + dy, center.z + dz)
					if _world and _world.get_block(p.x, p.y, p.z) != _Const.BLOCK_AIR:
						return p
		bp["dug"] = true
		_current_blueprint_idx += 1
	return null


func has_work() -> bool:
	return get_next_dig_target() != null
