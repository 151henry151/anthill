extends CanvasLayer
## Scientific colony readout: population, time, resources, pheromone legend, per-worker inspector.


var _stage_label: Label
var _day_label: Label
var _queen_label: Label
var _food_label: Label
var _pop_label: Label
var _mode_label: Label
var _sci_labels: Array[Label] = []
var _panel: PanelContainer
var _legend_panel: PanelContainer
var _ant_panel: PanelContainer
var _ant_text: Label

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

## Extended metrics (set by **`set_scientific_metrics`**).
var _sim_tick: int = 0
var _eggs: int = 0
var _larvae: int = 0
var _pupae: int = 0
var _nest_line: String = "—"
var _food_sources_n: int = 0
var _peak_workers: int = 0
var _trail_cells: int = 0
var _fp_cells: int = 0
var _alarm_cells: int = 0
var _build_cells: int = 0


func _ready() -> void:
	layer = 10
	_panel = PanelContainer.new()
	var sb_main := StyleBoxFlat.new()
	sb_main.bg_color = Color(0, 0, 0, 0.52)
	sb_main.set_corner_radius_all(6)
	sb_main.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", sb_main)
	_panel.position = Vector2(10, 40)
	add_child(_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	_panel.add_child(vbox)
	_stage_label = _mk_label(vbox)
	_day_label = _mk_label(vbox)
	_queen_label = _mk_label(vbox)
	_food_label = _mk_label(vbox)
	_pop_label = _mk_label(vbox)
	for _i in range(5):
		var sl := _mk_label(vbox)
		sl.add_theme_font_size_override("font_size", 12)
		sl.add_theme_color_override("font_color", Color(0.78, 0.82, 0.76))
		_sci_labels.append(sl)
	_mode_label = _mk_label(vbox)
	_mode_label.add_theme_font_size_override("font_size", 12)
	_update_display()

	_legend_panel = PanelContainer.new()
	var sb_leg := StyleBoxFlat.new()
	sb_leg.bg_color = Color(0, 0, 0, 0.52)
	sb_leg.set_corner_radius_all(6)
	sb_leg.set_content_margin_all(10)
	_legend_panel.add_theme_stylebox_override("panel", sb_leg)
	_legend_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_legend_panel.offset_left = -280.0
	_legend_panel.offset_right = -10.0
	_legend_panel.offset_top = 40.0
	_legend_panel.offset_bottom = 240.0
	_legend_panel.visible = false
	var leg_v := VBoxContainer.new()
	leg_v.add_theme_constant_override("separation", 6)
	_legend_panel.add_child(leg_v)
	var leg_title := _mk_label(leg_v)
	leg_title.text = "Pheromone field view [P]"
	leg_title.add_theme_font_size_override("font_size", 13)
	_add_legend_row(leg_v, SimParams.PHEROMONE_VIS_RECRUITMENT, "Recruitment trail (2D, attractive)")
	_add_legend_row(leg_v, SimParams.PHEROMONE_VIS_FOOTPRINT, "Footprint / CHC (2D, substrate)")
	_add_legend_row(leg_v, SimParams.PHEROMONE_VIS_BUILDING, "Nest construction (3D voxels)")
	_add_legend_row(leg_v, SimParams.PHEROMONE_VIS_ALARM, "Alarm / Dufour (2D, stress)")
	add_child(_legend_panel)

	_ant_panel = PanelContainer.new()
	var sb_ant := StyleBoxFlat.new()
	sb_ant.bg_color = Color(0, 0, 0, 0.55)
	sb_ant.set_corner_radius_all(6)
	sb_ant.set_content_margin_all(10)
	_ant_panel.add_theme_stylebox_override("panel", sb_ant)
	_ant_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_ant_panel.offset_left = -360.0
	_ant_panel.offset_right = -10.0
	_ant_panel.offset_top = -300.0
	_ant_panel.offset_bottom = -10.0
	_ant_panel.visible = false
	var av := VBoxContainer.new()
	av.add_theme_constant_override("separation", 4)
	_ant_panel.add_child(av)
	var ah := _mk_label(av)
	ah.text = "Worker inspector (right-click)"
	ah.add_theme_font_size_override("font_size", 13)
	_ant_text = _mk_label(av)
	_ant_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ant_text.custom_minimum_size = Vector2(300, 0)
	add_child(_ant_panel)


func _mk_label(parent: Node) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 0.88))
	parent.add_child(lbl)
	return lbl


func _add_legend_row(parent: Node, col: Color, text: String) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	var sq := ColorRect.new()
	sq.custom_minimum_size = Vector2(18, 18)
	sq.color = Color(col.r, col.g, col.b, 0.92)
	parent.add_child(hb)
	hb.add_child(sq)
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_size_override("font_size", 11)
	lb.add_theme_color_override("font_color", Color(0.88, 0.9, 0.84))
	lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(lb)


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


func set_scientific_metrics(
	p_tick: int,
	p_eggs: int,
	p_larvae: int,
	p_pupae: int,
	p_nest_line: String,
	p_food_sources: int,
	p_peak_workers: int,
	p_trail_cells: int,
	p_fp_cells: int,
	p_alarm_cells: int,
	p_build_cells: int
) -> void:
	_sim_tick = p_tick
	_eggs = p_eggs
	_larvae = p_larvae
	_pupae = p_pupae
	_nest_line = p_nest_line
	_food_sources_n = p_food_sources
	_peak_workers = p_peak_workers
	_trail_cells = p_trail_cells
	_fp_cells = p_fp_cells
	_alarm_cells = p_alarm_cells
	_build_cells = p_build_cells
	_update_display()


func set_ant_inspector(inspector: Dictionary) -> void:
	if inspector.is_empty():
		_ant_panel.visible = false
		_ant_text.text = ""
		return
	_ant_panel.visible = true
	var lines: PackedStringArray = []
	lines.append("ID %d · %s" % [int(inspector.get("sim_id", 0)), String(inspector.get("state_name", "?"))])
	lines.append("Position (wx,wz): %d, %d" % [int(inspector.get("wx", 0)), int(inspector.get("wz", 0))])
	lines.append("Age: %d ticks (%.2f ant days)" % [int(inspector.get("age_ticks", 0)), float(inspector.get("age_ant_days", 0.0))])
	var caste: String = "nanitic" if bool(inspector.get("is_nanitic", false)) else "worker"
	lines.append("Caste: %s" % caste)
	lines.append("Health: %.0f%% · metabolic reserve: %.0f%%" % [
		float(inspector.get("health", 1.0)) * 100.0,
		float(inspector.get("metabolic_reserve", 1.0)) * 100.0,
	])
	if bool(inspector.get("carrying_food", false)):
		lines.append("Crop load: %.0f%% · cargo: %s" % [
			float(inspector.get("crop_load", 0.0)) * 100.0,
			String(inspector.get("food_type", "")),
		])
	else:
		lines.append("Crop load: 0% (not carrying)")
	lines.append("Heading: %.0f°" % float(inspector.get("heading_deg", 0.0)))
	var dn: float = float(inspector.get("dist_to_nest", -1.0))
	if dn >= 0.0:
		lines.append("Dist. to nest entrance: %.1f voxels" % dn)
	lines.append("Trail sample (recruitment): %.4f" % float(inspector.get("trail_sample", 0.0)))
	lines.append("Footprint sample (CHC): %.4f" % float(inspector.get("footprint_sample", 0.0)))
	lines.append("Alarm sample (Dufour): %.4f" % float(inspector.get("alarm_sample", 0.0)))
	if bool(inspector.get("knows_food_site", false)):
		lines.append(
			"Memory: (%d,%d) quality %.2f · last trip quality %.2f"
			% [int(inspector.get("memory_wx", 0)), int(inspector.get("memory_wz", 0)), float(inspector.get("memory_quality", 0.0)), float(inspector.get("last_food_quality", 1.0))]
		)
	lines.append(
		"Forager: %s · move interval: %.2fs · recruit deposit proximity: %.2f"
		% [
			"experienced" if bool(inspector.get("is_experienced_forager", false)) else "naive",
			float(inspector.get("move_interval_eff", 0.45)),
			float(inspector.get("recruit_deposit_proximity_mult", 1.0)),
		]
	)
	_ant_text.text = "\n".join(lines)


func _update_display() -> void:
	if _stage_label == null:
		return
	_stage_label.text = "Colony: %s" % colony_stage
	_day_label.text = "Ant day %d · %s local" % [game_day, clock_time]
	_day_label.tooltip_text = "Simulation clock: one ant-day = %d ticks (see constants)." % SimParams.TICKS_PER_ANT_DAY
	var qc: String = "OK" if queen_energy > 0.5 else ("Low" if queen_energy > 0.2 else "Critical")
	_queen_label.text = "Queen reserve: %s (%.0f%%)" % [qc, queen_energy * 100.0]
	var s_tgt: float = SimParams.FOOD_STORE_TARGET_SUGAR
	var p_tgt: float = SimParams.FOOD_STORE_TARGET_PROTEIN
	var sp: float = clampf(sugar / maxf(0.001, s_tgt), 0.0, 9.99) * 100.0
	var pp: float = clampf(protein / maxf(0.001, p_tgt), 0.0, 9.99) * 100.0
	_food_label.text = "Stores — sugar: %.2f / %.0f (%.1f%%) · protein: %.2f / %.0f (%.1f%%)" % [
		sugar, s_tgt, sp, protein, p_tgt, pp
	]
	_pop_label.text = "Workers: %d (peak %d) · brood total: %d" % [worker_count, _peak_workers, brood_count]
	if _sci_labels.size() >= 5:
		_sci_labels[0].text = "Sim tick: %d · brood: %d eggs, %d larvae, %d pupae" % [_sim_tick, _eggs, _larvae, _pupae]
		_sci_labels[1].text = "Nest: %s" % _nest_line
		_sci_labels[2].text = "Active food patches: %d" % _food_sources_n
		_sci_labels[3].text = "Pheromone grid cells — trail: %d · footprint: %d · alarm: %d · building: %d" % [_trail_cells, _fp_cells, _alarm_cells, _build_cells]
		_sci_labels[4].text = "Voxel: 1 unit ≈ %.1f mm (grain-scale fiction)" % SimParams.MM_PER_UNIT
	var modes: Array[String] = []
	if fast_forward_multiplier > 1.001:
		modes.append("%.0fx >>" % fast_forward_multiplier)
	if xray_active:
		modes.append("[X] X-ray terrain")
	if pheromone_overlay_active:
		modes.append("[P] Pheromone fields")
	_mode_label.text = " · ".join(modes) if not modes.is_empty() else "Controls: [P] fields · [X] x-ray · [F]/[S] speed · right-click worker"
	_legend_panel.visible = pheromone_overlay_active
