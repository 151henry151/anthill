extends Control
## First scene: threaded load of `main.tscn` with a visible progress bar.

const MAIN_SCENE := "res://scenes/main.tscn"

@onready var _bar: ProgressBar = $Center/VBox/ProgressBar
@onready var _title: Label = $Center/VBox/Title


func _ready() -> void:
	ResourceLoader.load_threaded_request(MAIN_SCENE)


func _process(_delta: float) -> void:
	var progress: Array = []
	var st := ResourceLoader.load_threaded_get_status(MAIN_SCENE, progress)
	match st:
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			var scene: PackedScene = ResourceLoader.load_threaded_get(MAIN_SCENE) as PackedScene
			if scene == null:
				_title.text = "ANTHILL"
				_title.text += "\n(load error)"
				return
			_bar.value = 100.0
			get_tree().change_scene_to_packed(scene)
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var p: float = 0.0
			if progress.size() > 0:
				p = float(progress[0])
			_bar.value = clampf(p * 100.0, 0.0, 100.0)
		ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
			_title.text = "ANTHILL\n(load failed)"
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			set_process(false)
			_title.text = "ANTHILL\n(invalid scene)"
		_:
			pass
