extends Node
## 3D building pheromone field for stigmergic construction coordination.

const _Const := preload("res://scripts/constants.gd")

var _build_grid: Dictionary = {}
var _evap_timer: int = 0


func get_build_pheromone(pos: Vector3i) -> float:
	return _build_grid.get(pos, 0.0)


func add_build_pheromone(pos: Vector3i, amount: float) -> void:
	var current: float = _build_grid.get(pos, 0.0)
	_build_grid[pos] = minf(current + amount, 1.0)
	for offset in [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,1,0), Vector3i(0,-1,0), Vector3i(0,0,1), Vector3i(0,0,-1)]:
		var n: Vector3i = pos + offset
		var nc: float = _build_grid.get(n, 0.0)
		_build_grid[n] = minf(nc + amount * 0.5, 1.0)


func evaporate_step() -> void:
	var to_remove: Array[Vector3i] = []
	for pos in _build_grid:
		_build_grid[pos] = float(_build_grid[pos]) * _Const.BUILD_PHEROMONE_EVAPORATION_RATE
		if float(_build_grid[pos]) < _Const.BUILD_PHEROMONE_MINIMUM:
			to_remove.append(pos)
	for pos in to_remove:
		_build_grid.erase(pos)


func debug_build_cell_count() -> int:
	return _build_grid.size()


func get_grid() -> Dictionary:
	return _build_grid


func tick() -> void:
	_evap_timer += 1
	if _evap_timer >= _Const.BUILD_PHEROMONE_EVAPORATION_INTERVAL_TICKS:
		_evap_timer = 0
		evaporate_step()
