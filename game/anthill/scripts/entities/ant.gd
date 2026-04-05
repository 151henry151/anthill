extends CharacterBody3D
## Reserved for future **AI** ant bodies — not a player avatar. Colony play is top-down; you do not drive ants.

const _Const := preload("res://scripts/constants.gd")

var world: Node
var carried: int = _Const.BLOCK_AIR

@export var move_speed: float = 10.0
@export var sprint_mult: float = 1.6
@export var jump_velocity: float = 5.0
@export var mouse_sensitivity: float = 0.0025

@onready var _cam: Camera3D = $Camera3D


func _ready() -> void:
	if _cam:
		_cam.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_cam.rotate_x(-event.relative.y * mouse_sensitivity)
		_cam.rotation.x = clampf(_cam.rotation.x, deg_to_rad(-70.0), deg_to_rad(70.0))
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.physical_keycode == KEY_E and world:
			_try_grab()
		if event.physical_keycode == KEY_Q and world:
			_try_place()


func _physics_process(delta: float) -> void:
	if world == null:
		return
	var on_floor := is_on_floor()
	var sp := sprint_mult if Input.is_key_pressed(KEY_SHIFT) else 1.0
	var dir := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		dir -= transform.basis.z
	if Input.is_physical_key_pressed(KEY_S):
		dir += transform.basis.z
	if Input.is_physical_key_pressed(KEY_A):
		dir -= transform.basis.x
	if Input.is_physical_key_pressed(KEY_D):
		dir += transform.basis.x
	dir.y = 0.0
	if dir.length_squared() > 0.0001:
		dir = dir.normalized() * move_speed * sp
	velocity.x = dir.x
	velocity.z = dir.z
	if on_floor and Input.is_physical_key_pressed(KEY_SPACE):
		velocity.y = jump_velocity
	else:
		velocity.y -= 24.0 * delta
	move_and_slide()
	if global_position.y < 1.0:
		global_position.y = 1.0
		velocity.y = 0.0


func _try_grab() -> void:
	if carried != _Const.BLOCK_AIR:
		return
	var hit := _ray_voxel_hit(4.0)
	if hit.x < -90000:
		return
	if world.get_block(hit.x, hit.y, hit.z) == _Const.BLOCK_SAND:
		world.set_block(hit.x, hit.y, hit.z, _Const.BLOCK_AIR)
		carried = _Const.BLOCK_SAND


func _try_place() -> void:
	if carried != _Const.BLOCK_SAND:
		return
	var p := global_position + Vector3.UP * 0.5 - transform.basis.z * 1.8
	var c := Vector3i(int(floor(p.x)), int(floor(p.y)), int(floor(p.z)))
	if world.get_block(c.x, c.y, c.z) == _Const.BLOCK_AIR:
		world.set_block(c.x, c.y, c.z, _Const.BLOCK_SAND)
		carried = _Const.BLOCK_AIR


func _ray_voxel_hit(max_dist: float) -> Vector3i:
	var from := _cam.global_position
	var dir := (-_cam.global_transform.basis.z).normalized()
	var step := 0.12
	var t := 0.0
	while t < max_dist:
		var p := from + dir * t
		var c := Vector3i(int(floor(p.x)), int(floor(p.y)), int(floor(p.z)))
		var id := world.get_block(c.x, c.y, c.z)
		if id != _Const.BLOCK_AIR:
			return c
		t += step
	return Vector3i(-99999, -99999, -99999)
