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


func debug_build_cell_count() -> int:
	return _build_grid.size()


func get_grid() -> Dictionary:
	return _build_grid


func tick() -> void:
	advance_ticks(1)


func advance_ticks(steps: int) -> void:
	if steps < 1:
		return
	_evap_timer += steps
	var interval: int = _Const.BUILD_PHEROMONE_EVAPORATION_INTERVAL_TICKS
	var n_evap: int = _evap_timer / interval
	if n_evap < 1:
		return
	_evap_timer %= interval
	var factor: float = pow(float(_Const.BUILD_PHEROMONE_EVAPORATION_RATE), float(n_evap))
	var thr: float = _Const.BUILD_PHEROMONE_MINIMUM
	var keys: Array = _build_grid.keys()
	for k in keys:
		if not _build_grid.has(k):
			continue
		var nv: float = float(_build_grid[k]) * factor
		if nv < thr:
			_build_grid.erase(k)
		else:
			_build_grid[k] = minf(nv, 1.0)
