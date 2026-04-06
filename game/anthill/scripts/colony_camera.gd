extends Camera3D
## Orthographic colony view: left-drag orbits around a ground pivot; middle-drag pans; wheel zooms.

const _Chunk := preload("res://scripts/world/chunk_data.gd")
const _TerrainGen := preload("res://scripts/world/terrain_gen.gd")

@export var look_at_xz: Vector2 = Vector2(272.0, 272.0)
@export var orbit_radius: float = 120.0
@export var yaw_deg: float = 0.0
@export var orbit_phi_deg: float = 12.0
@export var ortho_size: float = 220.0
@export var pan_speed: float = 0.28
@export var pan_pixels_to_world: float = 0.011
@export var pan_relative_max: float = 72.0
@export var orbit_sensitivity: float = 0.22
@export var zoom_step: float = 8.0
@export var min_zoom: float = 14.0
@export var max_zoom: float = 3200.0

var pivot: Vector3 = Vector3.ZERO
var _size_user: float = 220.0
var _orbiting: bool = false
var _panning: bool = false
var _last_wheel_ms: int = 0
## World diagonal for orbit_radius and clip-plane sizing.
var _world_diag: float = 800.0
## Keyboard pan/orbit rates (units per second).
@export var kb_pan_speed: float = 180.0
@export var kb_orbit_speed: float = 60.0
@export var kb_zoom_step: float = 20.0


func _ready() -> void:
	var wm: Node = $"../WorldManager"
	var half_x: float = float(wm.chunks_x * _Chunk.SIZE_X) * 0.5
	var half_z: float = float(wm.chunks_z * _Chunk.SIZE_Z) * 0.5
	look_at_xz = Vector2(half_x, half_z)
	var max_x: float = float(wm.chunks_x * _Chunk.SIZE_X)
	var max_z: float = float(wm.chunks_z * _Chunk.SIZE_Z)
	_world_diag = Vector2(max_x, max_z).length()
	orbit_radius = _world_diag * 0.8
	projection = PROJECTION_ORTHOGONAL
	keep_aspect = KEEP_HEIGHT
	_size_user = ortho_size
	pivot = Vector3(look_at_xz.x, float(_TerrainGen.SURFACE_BASE), look_at_xz.y)
	_apply_orbit()
	current = true
	get_viewport().physics_object_picking = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Use `_input` (not `_unhandled_input`) so middle-button and wheel events are seen before the viewport/GUI pipeline can mark them handled.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_orbiting = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var now: int = Time.get_ticks_msec()
			if now - _last_wheel_ms < 40:
				return
			_last_wheel_ms = now
			var f: float = maxf(mb.factor, 1.0)
			var step: float = zoom_step * f
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_size_user = clampf(_size_user - step, min_zoom, max_zoom)
			else:
				_size_user = clampf(_size_user + step, min_zoom, max_zoom)
			_apply_orbit()
			get_viewport().set_input_as_handled()
	elif event is InputEventPanGesture:
		var pg: InputEventPanGesture = event
		var dz: float = clampf(-pg.delta.y - pg.delta.x, -4.0, 4.0)
		if absf(dz) > 0.05:
			_size_user = clampf(_size_user + dz * zoom_step * 0.28, min_zoom, max_zoom)
			_apply_orbit()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		var orbit_now: bool = _orbiting or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		var pan_now: bool = _panning or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
		if not orbit_now and not pan_now:
			return
		var rel: Vector2 = motion.relative
		rel.x = clampf(rel.x, -pan_relative_max, pan_relative_max)
		rel.y = clampf(rel.y, -pan_relative_max, pan_relative_max)
		if orbit_now:
			yaw_deg -= rel.x * orbit_sensitivity
			orbit_phi_deg = clampf(orbit_phi_deg + rel.y * orbit_sensitivity, 4.0, 89.0)
			_apply_orbit()
			get_viewport().set_input_as_handled()
		elif pan_now:
			var pan_scale: float = _size_user * pan_pixels_to_world * pan_speed
			var axes := _ground_pan_axes()
			var right_h: Vector3 = axes[0]
			var forward_h: Vector3 = axes[1]
			var delta: Vector3 = right_h * rel.x * pan_scale + forward_h * rel.y * pan_scale
			pivot.x += delta.x
			pivot.z += delta.z
			_apply_orbit()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var ctrl: bool = Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META)
	if ctrl:
		var orbit_d := Vector2.ZERO
		if Input.is_key_pressed(KEY_LEFT):
			orbit_d.x += 1.0
		if Input.is_key_pressed(KEY_RIGHT):
			orbit_d.x -= 1.0
		if Input.is_key_pressed(KEY_UP):
			orbit_d.y -= 1.0
		if Input.is_key_pressed(KEY_DOWN):
			orbit_d.y += 1.0
		if orbit_d != Vector2.ZERO:
			yaw_deg += orbit_d.x * kb_orbit_speed * delta
			orbit_phi_deg = clampf(orbit_phi_deg + orbit_d.y * kb_orbit_speed * delta, 4.0, 89.0)
			_apply_orbit()
		if Input.is_key_pressed(KEY_EQUAL):
			_size_user = clampf(_size_user - kb_zoom_step * delta * 30.0, min_zoom, max_zoom)
			_apply_orbit()
		if Input.is_key_pressed(KEY_MINUS):
			_size_user = clampf(_size_user + kb_zoom_step * delta * 30.0, min_zoom, max_zoom)
			_apply_orbit()
	else:
		var pan_d := Vector2.ZERO
		if Input.is_key_pressed(KEY_LEFT):
			pan_d.x -= 1.0
		if Input.is_key_pressed(KEY_RIGHT):
			pan_d.x += 1.0
		if Input.is_key_pressed(KEY_UP):
			pan_d.y -= 1.0
		if Input.is_key_pressed(KEY_DOWN):
			pan_d.y += 1.0
		if pan_d != Vector2.ZERO:
			var axes := _ground_pan_axes()
			var move: Vector3 = axes[0] * pan_d.x + axes[1] * pan_d.y
			pivot.x += move.x * kb_pan_speed * delta
			pivot.z += move.z * kb_pan_speed * delta
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
	size = _size_user
	near = 0.01
	far = orbit_radius * 2.0 + _world_diag


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
