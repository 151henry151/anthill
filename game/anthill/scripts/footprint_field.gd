extends Node
## Passive **cuticular hydrocarbon** footprint marking (**Lasius niger**): deposited from tarsi while walking; long-lived vs recruitment trail; supports **negative chemotaxis** (prefer less-marked substrate).


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


## Batched update: **`steps`** simulation ticks of timer (one grid pass; compound decay when multiple evaporation intervals elapse).
func advance_ticks(steps: int) -> void:
	if steps < 1:
		return
	_evap_timer += steps
	var interval: int = SimParams.FOOTPRINT_EVAPORATION_INTERVAL_TICKS
	var n_evap: int = _evap_timer / interval
	if n_evap < 1:
		return
	_evap_timer %= interval
	var factor: float = pow(float(SimParams.FOOTPRINT_EVAPORATION_RATE), float(n_evap))
	var thr: float = SimParams.FOOTPRINT_MINIMUM_THRESHOLD
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


func _to_cell(wx: int, wz: int) -> Vector2i:
	var cs: int = SimParams.PHEROMONE_CELL_SIZE
	return Vector2i(int(floor(float(wx) / float(cs))), int(floor(float(wz) / float(cs))))
