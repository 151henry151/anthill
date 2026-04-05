extends Node
## Tracks all eggs, larvae, and pupae. Emits signals when brood develops.

const _Const := preload("res://scripts/constants.gd")

signal ant_eclosed(caste_destiny: String, position: Vector3)
signal brood_changed()

var _brood: Array[Dictionary] = []
var _chamber_center: Vector3 = Vector3.ZERO
var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()


func set_chamber_center(center: Vector3i) -> void:
	_chamber_center = Vector3(float(center.x), float(center.y), float(center.z))


func add_eggs(count: int, is_trophic: bool, caste_destiny: String = "worker") -> void:
	for i in range(count):
		var offset := Vector3(
			_rng.randf_range(-1.5, 1.5),
			_rng.randf_range(-0.5, 0.5),
			_rng.randf_range(-1.5, 1.5)
		)
		_brood.append({
			"type": "egg",
			"caste_destiny": caste_destiny,
			"is_trophic": is_trophic,
			"age_ticks": 0,
			"nutrition": 1.0 if not is_trophic else 0.0,
			"position": _chamber_center + offset,
		})
	brood_changed.emit()


func tick() -> void:
	var to_remove: Array[int] = []
	var idx: int = 0
	for b in _brood:
		b["age_ticks"] = int(b["age_ticks"]) + 1
		var btype: String = b["type"]
		var age: int = int(b["age_ticks"])
		if btype == "egg" and age >= _Const.EGG_DURATION_TICKS:
			if bool(b["is_trophic"]):
				to_remove.append(idx)
			else:
				b["type"] = "larva"
				b["age_ticks"] = 0
				b["nutrition"] = 0.5
		elif btype == "larva":
			var nutr: float = float(b["nutrition"])
			nutr -= 0.0001
			b["nutrition"] = maxf(nutr, 0.0)
			if nutr <= 0.0:
				to_remove.append(idx)
			elif age >= _Const.LARVA_DURATION_TICKS and nutr > 0.2:
				b["type"] = "pupa"
				b["age_ticks"] = 0
		elif btype == "pupa" and age >= _Const.PUPA_DURATION_TICKS:
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
