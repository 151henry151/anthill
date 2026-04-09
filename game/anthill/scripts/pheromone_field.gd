extends Node
## 2D grid overlay of trail pheromone concentration on the world XZ plane. **Diffusion** between cells each update models spreading chemical; **evaporation** removes it.


var _trail_grid: Dictionary = {}
var _evap_timer: int = 0

## 4-neighbor offsets on **pheromone cells** (not voxels).
var _card4: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
]


func deposit(wx: int, wz: int, amount: float) -> void:
	var cell := _to_cell(wx, wz)
	var current: float = _trail_grid.get(cell, 0.0)
	_trail_grid[cell] = minf(current + amount, 1.0)


func sample(wx: int, wz: int) -> float:
	return _trail_grid.get(_to_cell(wx, wz), 0.0)


func sample_directional(wx: int, wz: int, heading_rad: float) -> Array[float]:
	var samples: Array[float] = []
	var cs: int = SimParams.PHEROMONE_CELL_SIZE
	for angle_off in [-0.5, 0.0, 0.5]:
		var a: float = heading_rad + angle_off
		var sx: int = wx + int(round(cos(a) * float(cs * 2)))
		var sz: int = wz + int(round(sin(a) * float(cs * 2)))
		samples.append(sample(sx, sz))
	return samples


func tick() -> void:
	advance_ticks(1)


func _one_evaporation_pass() -> void:
	var to_remove: Array[Vector2i] = []
	for cell in _trail_grid:
		_trail_grid[cell] = float(_trail_grid[cell]) * SimParams.PHEROMONE_EVAPORATION_RATE
		if float(_trail_grid[cell]) < SimParams.PHEROMONE_MINIMUM_THRESHOLD:
			to_remove.append(cell)
	for cell in to_remove:
		_trail_grid.erase(cell)


## Batched simulation ticks: at most **`PHEROMONE_MAX_DIFFUSION_PASSES_PER_FRAME`** full Laplacian steps; extra intervals apply evaporation-only compounding (keeps large **`sim_steps`** affordable).
func advance_ticks(steps: int) -> void:
	if steps < 1:
		return
	_evap_timer += steps
	var interval: int = SimParams.PHEROMONE_EVAPORATION_INTERVAL_TICKS
	var due: int = _evap_timer / interval
	if due < 1:
		return
	_evap_timer %= interval
	var max_d: int = SimParams.PHEROMONE_MAX_DIFFUSION_PASSES_PER_FRAME
	var diffuse_runs: int = mini(due, max_d)
	for _i in range(diffuse_runs):
		_diffuse_laplacian_4()
		_one_evaporation_pass()
	var evap_only: int = due - diffuse_runs
	if evap_only > 0:
		var factor: float = pow(float(SimParams.PHEROMONE_EVAPORATION_RATE), float(evap_only))
		var thr: float = SimParams.PHEROMONE_MINIMUM_THRESHOLD
		var keys: Array = _trail_grid.keys()
		for k in keys:
			if not _trail_grid.has(k):
				continue
			var nv: float = float(_trail_grid[k]) * factor
			if nv < thr:
				_trail_grid.erase(k)
			else:
				_trail_grid[k] = minf(nv, 1.0)


func _diffuse_laplacian_4() -> void:
	var lam: float = SimParams.PHEROMONE_DIFFUSION_LAMBDA
	if lam <= 0.0 or _trail_grid.is_empty():
		return
	var old: Dictionary = _trail_grid.duplicate(true)
	var cells_set: Dictionary = {}
	for c in old:
		cells_set[c] = true
		for d in _card4:
			cells_set[c + d] = true
	var new_grid: Dictionary = {}
	for c in cells_set:
		var v: float = float(old.get(c, 0.0))
		var sum_nb: float = 0.0
		for d in _card4:
			sum_nb += float(old.get(c + d, 0.0))
		var vn: float = (1.0 - 4.0 * lam) * v + lam * sum_nb
		if vn >= SimParams.PHEROMONE_MINIMUM_THRESHOLD * 0.5:
			new_grid[c] = minf(vn, 1.0)
	_trail_grid = new_grid


func debug_trail_cell_count() -> int:
	return _trail_grid.size()


func get_grid() -> Dictionary:
	return _trail_grid


func _to_cell(wx: int, wz: int) -> Vector2i:
	var cs: int = SimParams.PHEROMONE_CELL_SIZE
	return Vector2i(int(floor(float(wx) / float(cs))), int(floor(float(wz) / float(cs))))
