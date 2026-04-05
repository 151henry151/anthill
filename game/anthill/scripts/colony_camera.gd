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
## Upper bound for wheel intent; effective `size` may exceed this when the world AABB needs a wider ortho frustum.
@export var max_zoom: float = 3200.0

var pivot: Vector3 = Vector3.ZERO
## Wheel-only target; effective `size` is at least `_required_ortho_size()` so corners are not cut by ortho side planes.
var _size_user: float = 220.0
var _orbiting: bool = false
var _panning: bool = false


func _ready() -> void:
	var wm: Node = $"../WorldManager"
	var half_x: float = float(wm.chunks_x * _Chunk.SIZE_X) * 0.5
	var half_z: float = float(wm.chunks_z * _Chunk.SIZE_Z) * 0.5
	look_at_xz = Vector2(half_x, half_z)
	projection = PROJECTION_ORTHOGONAL
	_size_user = ortho_size
	pivot = Vector3(look_at_xz.x, 0.0, look_at_xz.y)
	_apply_orbit()
	current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_orbiting = event.pressed
			MOUSE_BUTTON_MIDDLE:
				_panning = event.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_size_user = clampf(_size_user - zoom_step, min_zoom, max_zoom)
					_apply_orbit()
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_size_user = clampf(_size_user + zoom_step, min_zoom, max_zoom)
					_apply_orbit()
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		var rel: Vector2 = motion.relative
		rel.x = clampf(rel.x, -pan_relative_max, pan_relative_max)
		rel.y = clampf(rel.y, -pan_relative_max, pan_relative_max)
		var pan_scale: float = size * pan_pixels_to_world * pan_speed
		var basis_xz := _ground_pan_axes()
		var right_h: Vector3 = basis_xz[0]
		var forward_h: Vector3 = basis_xz[1]
		if _orbiting:
			yaw_deg -= rel.x * orbit_sensitivity
			orbit_phi_deg = clampf(orbit_phi_deg + rel.y * orbit_sensitivity, 4.0, 89.0)
			_apply_orbit()
		elif _panning:
			# Screen/mouse Y is down-positive; move pivot so the ground follows the cursor (not inverted).
			var delta: Vector3 = right_h * rel.x * pan_scale + forward_h * rel.y * pan_scale
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
	_apply_ortho_size_and_clip()


func _viewport_aspect() -> float:
	var r: Vector2 = get_viewport().get_visible_rect().size
	if r.y <= 1e-6:
		return 1.0
	return r.x / r.y


func _world_aabb_corners() -> Array[Vector3]:
	var wm: Node = $"../WorldManager"
	var max_x: float = float(wm.chunks_x * _Chunk.SIZE_X)
	var max_z: float = float(wm.chunks_z * _Chunk.SIZE_Z)
	var max_y: float = float(_Chunk.SIZE_Y)
	return [
		Vector3(0.0, 0.0, 0.0),
		Vector3(max_x, 0.0, 0.0),
		Vector3(0.0, 0.0, max_z),
		Vector3(max_x, 0.0, max_z),
		Vector3(0.0, max_y, 0.0),
		Vector3(max_x, max_y, 0.0),
		Vector3(0.0, max_y, max_z),
		Vector3(max_x, max_y, max_z),
	]


## Smallest ortho `size` so all AABB corners fit inside the orthographic X/Y slab (rotation / corner views).
func _required_ortho_size() -> float:
	var inv: Transform3D = global_transform.affine_inverse()
	var aspect: float = _viewport_aspect()
	var max_abs_x: float = 0.0
	var max_abs_y: float = 0.0
	for p in _world_aabb_corners():
		var local: Vector3 = inv * p
		max_abs_x = maxf(max_abs_x, absf(local.x))
		max_abs_y = maxf(max_abs_y, absf(local.y))
	# Godot ortho: height = `size`, width = `size * aspect` (visible rect aspect).
	var need_y: float = 2.0 * max_abs_y
	var need_x: float = (2.0 * max_abs_x) / aspect
	return maxf(need_y, need_x)


func _apply_ortho_size_and_clip() -> void:
	var req: float = _required_ortho_size()
	var cap: float = maxf(max_zoom, req * 1.02)
	size = clampf(maxf(_size_user, req), min_zoom, cap)
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
	var corners: Array[Vector3] = _world_aabb_corners()
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
