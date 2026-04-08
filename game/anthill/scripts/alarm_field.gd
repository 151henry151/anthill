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
	advance_ticks(1)


func advance_ticks(steps: int) -> void:
	if steps < 1:
		return
	_evap_timer += steps
	var interval: int = _Const.ALARM_EVAPORATION_INTERVAL_TICKS
	var n_evap: int = _evap_timer / interval
	if n_evap < 1:
		return
	_evap_timer %= interval
	var factor: float = pow(float(_Const.ALARM_EVAPORATION_RATE), float(n_evap))
	var thr: float = _Const.ALARM_MINIMUM_THRESHOLD
	var keys: Array = _grid.keys()
	for k in keys:
		if not _grid.has(k):
			continue
		var nv: float = float(_grid[k]) * factor
		if nv < thr:
			_grid.erase(k)
		else:
			_grid[k] = nv


func get_grid() -> Dictionary:
	return _grid


func debug_alarm_cell_count() -> int:
	return _grid.size()


func _to_cell(wx: int, wz: int) -> Vector2i:
	var cs: int = _Const.PHEROMONE_CELL_SIZE
	return Vector2i(int(floor(float(wx) / float(cs))), int(floor(float(wz) / float(cs))))
