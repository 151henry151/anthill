extends Camera3D
## Top-down colony view: you do not control individual ants — pan/zoom to survey the nest later.
## (Food / queen / colony policy UI will layer on this.)

@export var look_at_xz: Vector2 = Vector2(48.0, 48.0)
@export var height: float = 72.0
## Vertical world units in view (Godot ortho `size` = full height). ~viewport_height / size ≈ pixels per grain tall; ~180 → ~4 px/grain at 720p.
@export var ortho_size: float = 180.0
@export var pan_speed: float = 0.28
## Multiplier for ortho size; lower = smoother / less jumpy pan.
@export var pan_pixels_to_world: float = 0.011
@export var pan_relative_max: float = 72.0
@export var zoom_step: float = 6.0
@export var min_zoom: float = 14.0
@export var max_zoom: float = 240.0


func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	size = ortho_size
	position = Vector3(look_at_xz.x, height, look_at_xz.y)
	# Slight tilt so height steps and faces read as 3D; straight-down + unshaded reads as a flat sheet.
	rotation_degrees = Vector3(-78.0, 0.0, 0.0)
	current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(event: InputEvent) -> void:
	# Root `Window` in 4.2.x does not expose `gui_get_hovered_control`; skip GUI hit-testing here.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			size = clampf(size - zoom_step, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			size = clampf(size + zoom_step, min_zoom, max_zoom)
	if event is InputEventMouseMotion:
		var pan_mask: int = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_MIDDLE
		if event.button_mask & pan_mask:
			var rel := event.relative
			rel.x = clampf(rel.x, -pan_relative_max, pan_relative_max)
			rel.y = clampf(rel.y, -pan_relative_max, pan_relative_max)
			var pan_scale: float = size * pan_pixels_to_world * pan_speed
			var basis_xz := _ground_pan_axes()
			var right_h: Vector3 = basis_xz[0]
			var forward_h: Vector3 = basis_xz[1]
			# Grab-map: drag moves the ground with the cursor (camera moves opposite on screen axes).
			position -= right_h * rel.x * pan_scale
			position -= forward_h * rel.y * pan_scale


func _ground_pan_axes() -> Array[Vector3]:
	# Screen-aligned pan on the XZ plane (tilted camera: world X/Z alone feels wrong / jittery).
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
