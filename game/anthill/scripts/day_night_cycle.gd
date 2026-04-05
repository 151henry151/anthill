extends Node
## Drives sun direction, directional light, and ambient/sky from game tick (one day per ant-day).

const _Const := preload("res://scripts/constants.gd")

@onready var _sun: DirectionalLight3D = $"../DirectionalLight3D"
@onready var _world_env: WorldEnvironment = $"../WorldEnvironment"

var _env: Environment
var _bg_day: Color


func _ready() -> void:
	if _world_env and _world_env.environment:
		_env = _world_env.environment
		_bg_day = _env.background_color


func set_game_tick(tick: int) -> void:
	var day_len: float = float(_Const.TICKS_PER_ANT_DAY)
	var t: float = fmod(float(tick), day_len) / day_len
	var azimuth: float = t * TAU
	var elevation: float = sin(t * TAU) * deg_to_rad(52.0)
	var sun_dir: Vector3 = Vector3(
		cos(elevation) * sin(azimuth),
		sin(elevation),
		cos(elevation) * cos(azimuth)
	).normalized()
	var up: Vector3 = Vector3.UP
	if absf(sun_dir.dot(up)) > 0.95:
		up = Vector3.RIGHT
	var p: Vector3 = _sun.global_position
	_sun.look_at(p - sun_dir * 1000.0, up)
	var sun_above: float = clampf(sun_dir.y, 0.0, 1.0)
	var day_mix: float = smoothstep(0.0, 0.22, sun_above)
	_sun.light_energy = lerpf(0.05, 1.12, day_mix)
	_sun.light_color = Color(1.0, 0.97, 0.88).lerp(Color(0.5, 0.62, 0.92), 1.0 - day_mix)
	if _env:
		_env.ambient_light_energy = lerpf(0.5, 0.2, day_mix)
		var night_bg := Color(0.05, 0.07, 0.11, 1.0)
		_env.background_color = night_bg.lerp(_bg_day, day_mix)
