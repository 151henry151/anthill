extends Camera3D
## Orthographic colony view: left-drag orbits the camera around a ground pivot; middle-drag pans; wheel zooms.

const _Chunk := preload("res://scripts/world/chunk_data.gd")

@export var look_at_xz: Vector2 = Vector2(272.0, 272.0)
## Distance from pivot to camera (world units); larger worlds need a wider default orbit.
@export var orbit_radius: float = 120.0
## Azimuth around world Y through the pivot (degrees).
@export var yaw_deg: float = 0.0
## Polar angle from +Y (0 = camera on +Y above pivot; larger = lower toward horizon).
@export var orbit_phi_deg: float = 12.0
## Vertical world units in view (Godot ortho `size` = full height). ~viewport_height / size ≈ pixels per grain tall.
@export var ortho_size: float = 220.0
@export var pan_speed: float = 0.28
@export var pan_pixels_to_world: float = 0.011
@export var pan_relative_max: float = 72.0
@export var orbit_sensitivity: float = 0.22
@export var zoom_step: float = 8.0
@export var min_zoom: float = 14.0
## Ortho `size` is vertical world units. Centered pivot needs **`size` ≥ ~770** for diagonal corners; panned near an edge can need **~1500+** (furthest world point from pivot up to **~768** in XZ).
@export var max_zoom: float = 3200.0

var pivot: Vector3 = Vector3.ZERO


func _ready() -> void:
	var wm: Node = $"../WorldManager"
	var half_x: float = float(wm.chunks_x * _Chunk.SIZE_X) * 0.5
	var half_z: float = float(wm.chunks_z * _Chunk.SIZE_Z) * 0.5
	look_at_xz = Vector2(half_x, half_z)
	projection = PROJECTION_ORTHOGONAL
	size = ortho_size
	pivot = Vector3(look_at_xz.x, 0.0, look_at_xz.y)
	_apply_orbit()
	_sync_clip_to_world_aabb()
	current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			size = clampf(size - zoom_step, min_zoom, max_zoom)
			_sync_clip_to_world_aabb()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			size = clampf(size + zoom_step, min_zoom, max_zoom)
			_sync_clip_to_world_aabb()
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		var rel: Vector2 = motion.relative
		rel.x = clampf(rel.x, -pan_relative_max, pan_relative_max)
		rel.y = clampf(rel.y, -pan_relative_max, pan_relative_max)
		var pan_scale: float = size * pan_pixels_to_world * pan_speed
		var basis_xz := _ground_pan_axes()
		var right_h: Vector3 = basis_xz[0]
		var forward_h: Vector3 = basis_xz[1]
		if motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			yaw_deg -= rel.x * orbit_sensitivity
			orbit_phi_deg = clampf(orbit_phi_deg + rel.y * orbit_sensitivity, 4.0, 89.0)
			_apply_orbit()
		elif motion.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			var delta: Vector3 = -right_h * rel.x * pan_scale - forward_h * rel.y * pan_scale
			pivot.x += delta.x
			pivot.z += delta.z
			_apply_orbit()


func _apply_orbit() -> void:
	var theta: float = deg_to_rad(yaw_deg)
	var phi: float = deg_to_rad(orbit_phi_deg)
	var sinp: float = sin(phi)
	var cosp: float = cos(phi)
	var off := Vector3(
		orbit_radius * sinp * sin(theta),
		orbit_radius * cosp,
		orbit_radius * sinp * cos(theta)
	)
	position = pivot + off
	look_at(pivot, Vector3.UP)
	_sync_clip_to_world_aabb()


func _ground_pan_axes() -> Array[Vector3]:
	var r := global_transform.basis.x
	var r_h := Vector3(r.x, 0.0, r.z)
	if r_h.length_squared() < 1e-10:
		r_h = Vector3.RIGHT
	else:
		r_h = r_h.normalized()
	var f := -global_transform.basis.z
	var f_h := Vector3(f.x, 0.0, f.z)
	if f_h.length_squared() < 1e-10:
		f_h = Vector3.FORWARD
	else:
		f_h = f_h.normalized()
	return [r_h, f_h]


func _sync_clip_to_world_aabb() -> void:
	# `far`/`near` must contain every voxel corner for the *current* yaw/phi/pivot — rotation changes depth along
	# the view axis, so a size-only heuristic misses and the far plane can cut the ground (often a horizontal edge).
	var wm: Node = $"../WorldManager"
	var max_x: float = float(wm.chunks_x * _Chunk.SIZE_X)
	var max_z: float = float(wm.chunks_z * _Chunk.SIZE_Z)
	var max_y: float = float(_Chunk.SIZE_Y)
	var corners: Array[Vector3] = [
		Vector3(0.0, 0.0, 0.0),
		Vector3(max_x, 0.0, 0.0),
		Vector3(0.0, 0.0, max_z),
		Vector3(max_x, 0.0, max_z),
		Vector3(0.0, max_y, 0.0),
		Vector3(max_x, max_y, 0.0),
		Vector3(0.0, max_y, max_z),
		Vector3(max_x, max_y, max_z),
	]
	var cam_pos: Vector3 = global_position
	var forward: Vector3 = -global_transform.basis.z
	var min_front: float = INF
	var max_front: float = -INF
	for p in corners:
		var d: float = (p - cam_pos).dot(forward)
		if d > 0.0:
			min_front = minf(min_front, d)
			max_front = maxf(max_front, d)
	var margin: float = 256.0
	if max_front > 0.0:
		far = max_front + margin
	else:
		far = maxf(12000.0, size * 40.0)
	if min_front < INF and min_front > 0.0:
		near = minf(0.05, maxf(0.001, min_front * 0.25))
	else:
		near = 0.05
