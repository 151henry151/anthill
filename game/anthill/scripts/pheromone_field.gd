extends Node
## 2D grid overlay of trail pheromone concentration on the world XZ plane.

const _Const := preload("res://scripts/constants.gd")

var _trail_grid: Dictionary = {}
var _evap_timer: int = 0


func deposit(wx: int, wz: int, amount: float) -> void:
	var cell := _to_cell(wx, wz)
	var current: float = _trail_grid.get(cell, 0.0)
	_trail_grid[cell] = minf(current + amount, 1.0)


func sample(wx: int, wz: int) -> float:
	return _trail_grid.get(_to_cell(wx, wz), 0.0)


func sample_directional(wx: int, wz: int, heading_rad: float) -> Array[float]:
	var samples: Array[float] = []
	var cs: int = _Const.PHEROMONE_CELL_SIZE
	for angle_off in [-0.5, 0.0, 0.5]:
		var a: float = heading_rad + angle_off
		var sx: int = wx + int(round(cos(a) * float(cs * 2)))
		var sz: int = wz + int(round(sin(a) * float(cs * 2)))
		samples.append(sample(sx, sz))
	return samples


func tick() -> void:
	_evap_timer += 1
	if _evap_timer < _Const.PHEROMONE_EVAPORATION_INTERVAL_TICKS:
		return
	_evap_timer = 0
	var to_remove: Array[Vector2i] = []
	for cell in _trail_grid:
		_trail_grid[cell] = float(_trail_grid[cell]) * _Const.PHEROMONE_EVAPORATION_RATE
		if float(_trail_grid[cell]) < _Const.PHEROMONE_MINIMUM_THRESHOLD:
			to_remove.append(cell)
	for cell in to_remove:
		_trail_grid.erase(cell)


func get_grid() -> Dictionary:
	return _trail_grid


func _to_cell(wx: int, wz: int) -> Vector2i:
	var cs: int = _Const.PHEROMONE_CELL_SIZE
	return Vector2i(int(floor(float(wx) / float(cs))), int(floor(float(wz) / float(cs))))
