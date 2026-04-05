extends Camera3D
## Top-down colony view: you do not control individual ants — pan/zoom to survey the nest later.
## (Food / queen / colony policy UI will layer on this.)

@export var look_at_xz: Vector2 = Vector2(48.0, 48.0)
@export var height: float = 72.0
## Vertical world units in view (Godot ortho `size` = full height). ~viewport_height / size ≈ pixels per grain tall; ~180 → ~4 px/grain at 720p.
@export var ortho_size: float = 180.0
@export var pan_speed: float = 0.35
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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			size = clampf(size - zoom_step, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			size = clampf(size + zoom_step, min_zoom, max_zoom)
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			var s: float = size * 0.02
			position.x -= event.relative.x * s * pan_speed
			position.z -= event.relative.y * s * pan_speed
