extends Node
## Tracks all eggs, larvae, and pupae. Emits signals when brood develops.


signal ant_eclosed(caste_destiny: String, position: Vector3)
signal brood_changed()

var _brood: Array[Dictionary] = []
## Fallback when **`set_chamber_floor`** has not run (editor tests).
var _chamber_center: Vector3 = Vector3.ZERO
## World-space origin on the **chamber floor** (from **`queen.get_brood_placement_origin()`**).
var _floor_origin: Vector3 = Vector3.ZERO
var _use_floor_origin: bool = false
var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()


func set_chamber_center(center: Vector3i) -> void:
	_use_floor_origin = false
	_chamber_center = Vector3(float(center.x), float(center.y), float(center.z))


## Prefer this after founding: brood meshes sit **on** the excavated floor, not at the chamber bbox center.
func set_chamber_floor(origin: Vector3) -> void:
	_floor_origin = origin
	_use_floor_origin = true
	_reposition_brood_to_floor()


func _reposition_brood_to_floor() -> void:
	for b in _brood:
		b["position"] = _random_brood_position()
	brood_changed.emit()


func _random_brood_position() -> Vector3:
	var ox: float = _rng.randf_range(-1.4, 1.4)
	var oy: float = _rng.randf_range(0.0, 0.1)
	var oz: float = _rng.randf_range(-1.4, 1.4)
	if _use_floor_origin:
		return _floor_origin + Vector3(ox, oy, oz)
	return _chamber_center + Vector3(ox, _rng.randf_range(-0.2, 0.15), oz)


func add_eggs(count: int, is_trophic: bool, caste_destiny: String = "worker") -> void:
	for i in range(count):
		_brood.append({
			"type": "egg",
			"caste_destiny": caste_destiny,
			"is_trophic": is_trophic,
			"age_ticks": 0,
			"nutrition": 1.0 if not is_trophic else 0.0,
			"position": _random_brood_position(),
		})
	brood_changed.emit()


func tick() -> void:
	var to_remove: Array[int] = []
	var idx: int = 0
	for b in _brood:
		b["age_ticks"] = int(b["age_ticks"]) + 1
		var btype: String = b["type"]
		var age: int = int(b["age_ticks"])
		if btype == "egg" and age >= SimParams.EGG_DURATION_TICKS:
			if bool(b["is_trophic"]):
				to_remove.append(idx)
			else:
				b["type"] = "larva"
				b["age_ticks"] = 0
				b["nutrition"] = 0.5
				b["position"] = b["position"] + Vector3(0.0, 0.04, 0.0)
		elif btype == "larva":
			var nutr: float = float(b["nutrition"])
			nutr -= 0.0001
			b["nutrition"] = maxf(nutr, 0.0)
			if nutr <= 0.0:
				to_remove.append(idx)
			elif age >= SimParams.LARVA_DURATION_TICKS and nutr > 0.2:
				b["type"] = "pupa"
				b["age_ticks"] = 0
				b["position"] = b["position"] + Vector3(0.0, 0.06, 0.0)
		elif btype == "pupa" and age >= SimParams.PUPA_DURATION_TICKS:
			ant_eclosed.emit(String(b["caste_destiny"]), b["position"] as Vector3)
			to_remove.append(idx)
		idx += 1
	to_remove.reverse()
	for ri in to_remove:
		_brood.remove_at(ri)
	if not to_remove.is_empty():
		brood_changed.emit()


func feed_larva(amount: float) -> bool:
	for b in _brood:
		if b["type"] == "larva" and float(b["nutrition"]) < 0.8:
			b["nutrition"] = minf(float(b["nutrition"]) + amount, 1.0)
			return true
	return false


func feed_all_larvae(amount_each: float) -> void:
	for b in _brood:
		if b["type"] == "larva":
			b["nutrition"] = minf(float(b["nutrition"]) + amount_each, 1.0)


func count_larvae() -> int:
	var n: int = 0
	for b in _brood:
		if b["type"] == "larva":
			n += 1
	return n


func consume_trophic_egg() -> bool:
	for i in range(_brood.size()):
		if _brood[i]["type"] == "egg" and bool(_brood[i]["is_trophic"]):
			_brood.remove_at(i)
			brood_changed.emit()
			return true
	return false


func get_brood() -> Array[Dictionary]:
	return _brood


func get_counts() -> Dictionary:
	var eggs: int = 0
	var larvae: int = 0
	var pupae: int = 0
	for b in _brood:
		match b["type"]:
			"egg":
				eggs += 1
			"larva":
				larvae += 1
			"pupa":
				pupae += 1
	return {"eggs": eggs, "larvae": larvae, "pupae": pupae, "total": eggs + larvae + pupae}
