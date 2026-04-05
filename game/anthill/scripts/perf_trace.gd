extends Node
## Optional colony perf / memory tracing. Disable with env **`ANTHILL_PERF_TRACE=0`**.
## Writes **`user://anthill_perf.log`** (and prints slow frames). Flush runs on **`SceneTree.physics_frame`** so **`Main`**, **`ColonyAnts`**, and **`Queen`** timings land in one line.

const LOG_REL := "user://anthill_perf.log"

var enabled: bool = true

var _active: bool = false
var _tick: int = 0
var _day: int = 0
var _sand_us: int = 0
var _mesh_dirty_us: int = 0
var _mesh_rebuild_us: int = 0
var _mesh_rebuild_n: int = 0
var _systems_us: int = 0
var _ants_us: int = 0
var _queen_us: int = 0

var _pending_mesh: int = 0
var _sand_cols: int = 0
var _surf_cache: int = 0
var _trail_cells: int = 0
var _build_cells: int = 0
var _workers: int = 0
var _fast_forward: bool = false
var _time_scale: float = 1.0

var _last_rss_mb: float = -1.0
var _period: int = 30


func _ready() -> void:
	if OS.get_environment("ANTHILL_PERF_TRACE") == "0":
		enabled = false
		return
	var pe: String = OS.get_environment("ANTHILL_PERF_TRACE_PERIOD")
	if pe.is_valid_int() and int(pe) > 0:
		_period = int(pe)
	if not get_tree().physics_frame.is_connected(_on_physics_frame):
		get_tree().physics_frame.connect(_on_physics_frame)


func begin_frame() -> void:
	if not enabled:
		return
	_active = true
	_sand_us = 0
	_mesh_dirty_us = 0
	_mesh_rebuild_us = 0
	_mesh_rebuild_n = 0
	_systems_us = 0
	_ants_us = 0
	_queen_us = 0


func set_sand_usec(us: int) -> void:
	_sand_us = us


func set_mesh_dirty_usec(us: int) -> void:
	_mesh_dirty_us = us


func set_mesh_rebuild_usec(us: int, chunks: int) -> void:
	_mesh_rebuild_us = us
	_mesh_rebuild_n = chunks


func set_systems_usec(us: int) -> void:
	_systems_us = us


func set_ants_usec(us: int) -> void:
	_ants_us = us


func set_queen_usec(us: int) -> void:
	_queen_us = us


func set_context(
	tick: int,
	day: int,
	pending_mesh: int,
	world: Node,
	trail_field: Node,
	build_field: Node,
	ants: Node,
	fast_forward: bool
) -> void:
	_tick = tick
	_day = day
	_pending_mesh = pending_mesh
	_time_scale = Engine.time_scale
	_fast_forward = fast_forward
	_sand_cols = 0
	_surf_cache = 0
	_trail_cells = 0
	_build_cells = 0
	_workers = 0
	if world:
		if world.has_method("debug_sand_column_count"):
			_sand_cols = int(world.call("debug_sand_column_count"))
		if world.has_method("debug_surface_cache_size"):
			_surf_cache = int(world.call("debug_surface_cache_size"))
	if trail_field and trail_field.has_method("debug_trail_cell_count"):
		_trail_cells = int(trail_field.call("debug_trail_cell_count"))
	if build_field and build_field.has_method("debug_build_cell_count"):
		_build_cells = int(build_field.call("debug_build_cell_count"))
	if ants and ants.has_method("get_worker_count"):
		_workers = int(ants.call("get_worker_count"))


func _on_physics_frame() -> void:
	if not enabled or not _active:
		return
	var total_us: int = _sand_us + _mesh_dirty_us + _mesh_rebuild_us + _systems_us + _ants_us + _queen_us
	var rss_mb: float = _read_vm_rss_mb()
	var mem_static: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	var rss_delta: String = ""
	if _last_rss_mb >= 0.0 and rss_mb >= 0.0:
		rss_delta = " rss_delta_mb=%.1f" % (rss_mb - _last_rss_mb)
	if rss_mb >= 0.0:
		_last_rss_mb = rss_mb

	var warn: bool = total_us > 20000
	var periodic: bool = _period > 0 and _tick > 0 and _tick % _period == 0
	if not warn and not periodic:
		return

	var line: String = (
		"perf tick=%d day=%d ff=%s scale=%.2f sand_us=%d meshq_us=%d rebuild_us=%d rebuild_n=%d sys_us=%d ants_us=%d queen_us=%d total_us=%d pending_mesh=%d sand_cols=%d surf_cache=%d trail_cells=%d build_cells=%d workers=%d rss_mb=%.1f%s mem_static_mb=%.1f"
		% [
			_tick,
			_day,
			_fast_forward,
			_time_scale,
			_sand_us,
			_mesh_dirty_us,
			_mesh_rebuild_us,
			_mesh_rebuild_n,
			_systems_us,
			_ants_us,
			_queen_us,
			total_us,
			_pending_mesh,
			_sand_cols,
			_surf_cache,
			_trail_cells,
			_build_cells,
			_workers,
			rss_mb,
			rss_delta,
			mem_static / 1048576.0,
		]
	)
	if warn:
		line = "WARN " + line
		print(line)
	_append_log(line)


func _read_vm_rss_mb() -> float:
	if OS.get_name() != "Linux":
		return -1.0
	var f: FileAccess = FileAccess.open("/proc/self/status", FileAccess.READ)
	if f == null:
		return -1.0
	while not f.eof_reached():
		var s: String = f.get_line()
		if s.begins_with("VmRSS:"):
			var parts: PackedStringArray = s.split()
			if parts.size() >= 2:
				var kb: int = int(parts[1])
				return float(kb) / 1024.0
	return -1.0


func _append_log(line: String) -> void:
	var path: String = LOG_REL
	var f: FileAccess
	if FileAccess.file_exists(path):
		f = FileAccess.open(path, FileAccess.READ_WRITE)
		if f:
			f.seek_end()
	else:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(line + "\n")
	f.close()
