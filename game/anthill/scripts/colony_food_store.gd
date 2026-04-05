extends Node
## Colony-level food resource tracker: sugar and protein reserves.

const _Const := preload("res://scripts/constants.gd")

signal food_critical(food_type: String)
signal food_changed()

var sugar: float = 0.0
var protein: float = 0.0


func add_food(food_type: String, amount: float) -> void:
	if food_type == "sugar" or food_type == "carbohydrate":
		sugar += amount
	elif food_type == "protein":
		protein += amount
	food_changed.emit()


func consume(food_type: String, amount: float) -> float:
	var available: float = sugar if food_type == "sugar" else protein
	var taken: float = minf(amount, available)
	if food_type == "sugar" or food_type == "carbohydrate":
		sugar -= taken
	elif food_type == "protein":
		protein -= taken
	food_changed.emit()
	_check_critical()
	return taken


func _check_critical() -> void:
	if sugar < _Const.FOOD_CRITICAL_THRESHOLD:
		food_critical.emit("sugar")
	if protein < _Const.FOOD_CRITICAL_THRESHOLD:
		food_critical.emit("protein")


func has_food() -> bool:
	return sugar > 0.001 or protein > 0.001
