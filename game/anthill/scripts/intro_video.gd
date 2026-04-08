extends Control
## Plays the intro **Ogg Theora** clip (transcoded from **`res://assets/intro/Isolating_the_Negative_Feedback_Loop_in_Ant_Foraging.mp4`**; Godot plays **.ogv** only).
## Skips to **`loading_screen.tscn`** on any key, mouse button, gamepad button, or touch.

const LOADING_SCENE := "res://scenes/loading_screen.tscn"
const INTRO_STREAM := "res://assets/intro/intro.ogv"

@onready var _player: VideoStreamPlayer = $VideoStreamPlayer

var _left: bool = false


func _ready() -> void:
	var stream_res := load(INTRO_STREAM) as VideoStream
	if stream_res == null:
		push_error("intro_video: missing or invalid stream at %s" % INTRO_STREAM)
		_go_to_loading()
		return
	_player.stream = stream_res
	_player.finished.connect(_go_to_loading, CONNECT_ONE_SHOT)
	_player.play()


func _input(event: InputEvent) -> void:
	if _left:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		_go_to_loading()
	elif event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
		_go_to_loading()
	elif event is InputEventJoypadButton and event.pressed:
		get_viewport().set_input_as_handled()
		_go_to_loading()
	elif event is InputEventScreenTouch and event.pressed:
		get_viewport().set_input_as_handled()
		_go_to_loading()


func _go_to_loading() -> void:
	if _left:
		return
	_left = true
	if is_instance_valid(_player):
		_player.stop()
	if not is_inside_tree():
		return
	var err := get_tree().change_scene_to_file(LOADING_SCENE)
	if err != OK:
		push_error("intro_video: failed to load %s (err %s)" % [LOADING_SCENE, err])
