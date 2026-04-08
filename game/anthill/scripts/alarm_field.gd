extends Node
## **Undecane**-like alarm signal (Dufour gland fiction): fast-decay 2D field at recruitment resolution.

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
	if _evap_timer < _Const.ALARM_EVAPORATION_INTERVAL_TICKS:
		return
	_evap_timer = 0
	var to_remove: Array[Vector2i] = []
	for cell in _grid:
		_grid[cell] = float(_grid[cell]) * _Const.ALARM_EVAPORATION_RATE
		if float(_grid[cell]) < _Const.ALARM_MINIMUM_THRESHOLD:
			to_remove.append(cell)
	for cell in to_remove:
		_grid.erase(cell)


func get_grid() -> Dictionary:
	return _grid


func debug_alarm_cell_count() -> int:
	return _grid.size()


func _to_cell(wx: int, wz: int) -> Vector2i:
	var cs: int = _Const.PHEROMONE_CELL_SIZE
	return Vector2i(int(floor(float(wx) / float(cs))), int(floor(float(wz) / float(cs))))
