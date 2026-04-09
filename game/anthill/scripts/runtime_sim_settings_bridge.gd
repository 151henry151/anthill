extends Node
## Forwards **F10** while the tree may be paused; **`main_controller`** assigns **`main_controller`** before **`add_child`**.

var main_controller: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if main_controller == null:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode != KEY_F10:
		return
	if main_controller.has_method("open_runtime_sim_settings"):
		main_controller.call("open_runtime_sim_settings")
		get_viewport().set_input_as_handled()
