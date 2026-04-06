extends CanvasLayer
## Minimal HUD: colony stage, ant-day counter, queen status, food bars, population.

const _Const := preload("res://scripts/constants.gd")

var _stage_label: Label
var _day_label: Label
var _queen_label: Label
var _food_label: Label
var _pop_label: Label
var _mode_label: Label
var _panel: PanelContainer

var game_day: int = 0
var clock_time: String = "00:00"
var colony_stage: String = "Founding"
var queen_energy: float = 1.0
var sugar: float = 0.0
var protein: float = 0.0
var worker_count: int = 0
var brood_count: int = 0
var xray_active: bool = false
var pheromone_overlay_active: bool = false
## **1.0** = normal; **>1** shows fast-forward in the mode line.
var fast_forward_multiplier: float = 1.0


func _ready() -> void:
	layer = 10
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.45)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_panel.add_child(vbox)
	_stage_label = _mk_label(vbox)
	_day_label = _mk_label(vbox)
	_queen_label = _mk_label(vbox)
	_food_label = _mk_label(vbox)
	_pop_label = _mk_label(vbox)
	_mode_label = _mk_label(vbox)
	_panel.position = Vector2(10, 40)
	_update_display()


func _mk_label(parent: VBoxContainer) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 0.88))
	parent.add_child(lbl)
	return lbl


func update_data(
	p_day: int,
	p_clock: String,
	p_stage: String,
	p_queen_energy: float,
	p_sugar: float,
	p_protein: float,
	p_workers: int,
	p_brood: int
) -> void:
	game_day = p_day
	clock_time = p_clock
	colony_stage = p_stage
	queen_energy = p_queen_energy
	sugar = p_sugar
	protein = p_protein
	worker_count = p_workers
	brood_count = p_brood
	_update_display()


func _update_display() -> void:
	if _stage_label == null:
		return
	_stage_label.text = colony_stage
	_day_label.text = "Day %d · %s" % [game_day, clock_time]
	var qc: String = "OK" if queen_energy > 0.5 else ("Low" if queen_energy > 0.2 else "Critical")
	_queen_label.text = "Queen: %s (%.0f%%)" % [qc, queen_energy * 100.0]
	_food_label.text = "Sugar: %.0f%% | Protein: %.0f%%" % [sugar * 100.0, protein * 100.0]
	_pop_label.text = "%d workers | %d brood" % [worker_count, brood_count]
	var modes: Array[String] = []
	if fast_forward_multiplier > 1.001:
		modes.append("%.0fx >>" % fast_forward_multiplier)
	if xray_active:
		modes.append("[X] X-RAY")
	if pheromone_overlay_active:
		modes.append("[P] TRAILS")
	_mode_label.text = "  ".join(modes) if not modes.is_empty() else ""
