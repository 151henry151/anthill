extends Node
## Passive **cuticular hydrocarbon** footprint marking (**Lasius niger**): deposited from tarsi while walking; long-lived vs recruitment trail; supports **negative chemotaxis** (prefer less-marked substrate).

const _Const := preload("res://scripts/constants.gd")

var _grid: Dictionary = {}
var _evap_timer: int = 0


func deposit(wx: int, wz: int, amount: float) -> void:
	var cell := _to_cell(wx, wz)
	var current: float = _grid.get(cell, 0.0)
	_grid[cell] = minf(current + amount, 1.0)


func sample(wx: int, wz: int) -> float:
	return _grid.get(_to_cell(wx, wz), 0.0)


func tick() -> void:
	_evap_timer += 1
	if _evap_timer < _Const.FOOTPRINT_EVAPORATION_INTERVAL_TICKS:
		return
	_evap_timer = 0
	var to_remove: Array[Vector2i] = []
	for cell in _grid:
		_grid[cell] = float(_grid[cell]) * _Const.FOOTPRINT_EVAPORATION_RATE
		if float(_grid[cell]) < _Const.FOOTPRINT_MINIMUM_THRESHOLD:
			to_remove.append(cell)
	for cell in to_remove:
		_grid.erase(cell)


func get_grid() -> Dictionary:
	return _grid


func _to_cell(wx: int, wz: int) -> Vector2i:
	var cs: int = _Const.PHEROMONE_CELL_SIZE
	return Vector2i(int(floor(float(wx) / float(cs))), int(floor(float(wz) / float(cs))))
