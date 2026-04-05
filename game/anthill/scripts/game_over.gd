extends CanvasLayer
## Game over overlay: shows cause of death, stats, and a retry button.

signal retry_pressed()

var _panel: PanelContainer
var _cause_label: Label
var _stats_label: Label
var _retry_btn: Button


func _ready() -> void:
	layer = 20
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.1, 0.08, 0.92)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(24)
	_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(vbox)
	var title := Label.new()
	title.text = "Colony Lost"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	_cause_label = Label.new()
	_cause_label.add_theme_font_size_override("font_size", 16)
	_cause_label.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75))
	_cause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_cause_label)
	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 14)
	_stats_label.add_theme_color_override("font_color", Color(0.7, 0.68, 0.62))
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_stats_label)
	_retry_btn = Button.new()
	_retry_btn.text = "Try Again"
	_retry_btn.pressed.connect(_on_retry)
	vbox.add_child(_retry_btn)


func show_game_over(cause: String, days_survived: int, peak_workers: int) -> void:
	_cause_label.text = cause
	_stats_label.text = "Days survived: %d\nPeak workers: %d" % [days_survived, peak_workers]
	visible = true
	get_tree().paused = true


func _on_retry() -> void:
	get_tree().paused = false
	retry_pressed.emit()
	get_tree().reload_current_scene()
