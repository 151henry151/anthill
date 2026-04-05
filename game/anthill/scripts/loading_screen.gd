extends Control
## First scene: threaded load of `main.tscn` with a visible progress bar and status text.

const MAIN_SCENE := "res://scenes/main.tscn"
## Phase 1 (scene parse) occupies 0–30% of the total bar.
const PHASE1_WEIGHT := 0.30

@onready var _bar: ProgressBar = $LoadingPanel/Center/VBox/ProgressBar
@onready var _title: Label = $LoadingPanel/Center/VBox/Title
@onready var _status: Label = $LoadingPanel/Center/VBox/StatusLabel


func _ready() -> void:
	ResourceLoader.load_threaded_request(MAIN_SCENE)
	_set_status("Loading scene resources...")


func _process(_delta: float) -> void:
	var progress: Array = []
	var st := ResourceLoader.load_threaded_get_status(MAIN_SCENE, progress)
	match st:
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			_set_progress(PHASE1_WEIGHT * 100.0)
			_set_status("Scene loaded. Generating terrain...")
			var scene: PackedScene = ResourceLoader.load_threaded_get(MAIN_SCENE) as PackedScene
			if scene == null:
				_title.text = "ANTHILL"
				_set_status("ERROR: scene load returned null")
				return
			get_tree().change_scene_to_packed(scene)
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var p: float = 0.0
			if progress.size() > 0:
				p = float(progress[0])
			_set_progress(p * PHASE1_WEIGHT * 100.0)
			if p < 0.3:
				_set_status("Parsing scene tree...")
			elif p < 0.7:
				_set_status("Loading scripts and resources...")
			else:
				_set_status("Compiling shaders...")
		ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
			_set_status("ERROR: scene load failed")
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			set_process(false)
			_set_status("ERROR: invalid scene resource")
		_:
			pass


func _set_progress(pct: float) -> void:
	if _bar:
		_bar.value = clampf(pct, 0.0, 100.0)


func _set_status(text: String) -> void:
	if _status:
		_status.text = text
