extends Camera3D
## Orthographic colony view: left-drag orbits the camera around a ground pivot; middle-drag pans; wheel zooms.

@export var look_at_xz: Vector2 = Vector2(48.0, 48.0)
## Distance from pivot to camera (world units).
@export var orbit_radius: float = 75.0
## Azimuth around world Y through the pivot (degrees).
@export var yaw_deg: float = 0.0
## Polar angle from +Y (0 = camera on +Y above pivot; larger = lower toward horizon).
@export var orbit_phi_deg: float = 12.0
## Vertical world units in view (Godot ortho `size` = full height). ~viewport_height / size ≈ pixels per grain tall.
@export var ortho_size: float = 180.0
@export var pan_speed: float = 0.28
@export var pan_pixels_to_world: float = 0.011
@export var pan_relative_max: float = 72.0
@export var orbit_sensitivity: float = 0.22
@export var zoom_step: float = 6.0
@export var min_zoom: float = 14.0
@export var max_zoom: float = 240.0

var pivot: Vector3 = Vector3.ZERO


func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	size = ortho_size
	pivot = Vector3(look_at_xz.x, 0.0, look_at_xz.y)
	_apply_orbit()
	current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			size = clampf(size - zoom_step, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			size = clampf(size + zoom_step, min_zoom, max_zoom)
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
