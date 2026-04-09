extends Control
## Full-screen editor for **`SimParams`** before **`loading_screen.tscn`** loads **`main.tscn`**.

const LOADING_SCENE := "res://scenes/loading_screen.tscn"
## Matches getter-only properties in **`simulation_parameters.gd`** (derived from other fields).
const _DERIVED_READONLY: Array[String] = [
	"MM_PER_UNIT",
	"TICKS_PER_ANT_DAY",
	"EGG_DURATION_TICKS",
	"LARVA_DURATION_TICKS",
	"PUPA_DURATION_TICKS",
	"QUEEN_CLAUSTRAL_EGG_INTERVAL_TICKS",
	"QUEEN_ESTABLISHED_EGG_INTERVAL_TICKS",
	"QUEEN_CLAUSTRAL_ENERGY_DRAIN_PER_TICK",
	"YOUNG_WORKER_AGE_THRESHOLD",
	"CALLOW_DARKEN_TICKS",
	"FOOD_SPOIL_DURATION_TICKS_MIN",
	"FOOD_SPOIL_DURATION_TICKS_MAX",
]

@onready var _form_vbox: VBoxContainer = $MarginContainer/VBox/ScrollContainer/FormVBox
@onready var _reset_btn: Button = $MarginContainer/VBox/ButtonRow/ResetDefaults
@onready var _start_btn: Button = $MarginContainer/VBox/ButtonRow/StartSimulation


func _ready() -> void:
	_reset_btn.pressed.connect(_on_reset_defaults)
	_start_btn.pressed.connect(_on_start_simulation)
	_rebuild_form()


func _on_reset_defaults() -> void:
	SimParams.reset_to_reference_defaults()
	_rebuild_form()


func _on_start_simulation() -> void:
	_apply_controls_to_sim_params()
	var err := get_tree().change_scene_to_file(LOADING_SCENE)
	if err != OK:
		push_error("simulation_settings: failed to load %s (err %s)" % [LOADING_SCENE, err])


func _rebuild_form() -> void:
	for c in _form_vbox.get_children():
		c.queue_free()
	var names: Array[String] = _list_sim_param_property_names()
	names.sort()
	for prop_name in names:
		_add_row(prop_name)


func _list_sim_param_property_names() -> Array[String]:
	var out: Array[String] = []
	for p in SimParams.get_property_list():
		var n: String = String(p.name)
		if n.begins_with("_") or n == "script":
			continue
		if int(p.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		out.append(n)
	return out


func _add_row(prop_name: String) -> void:
	var pinfo: Dictionary = _property_info(prop_name)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name_lbl := Label.new()
	name_lbl.text = prop_name
	name_lbl.custom_minimum_size.x = 320
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(name_lbl)
	var readonly: bool = _is_readonly_name(prop_name, pinfo)
	var type: int = int(pinfo.get("type", TYPE_NIL))
	if readonly:
		var v_lbl := Label.new()
		v_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v_lbl.text = str(SimParams.get(prop_name))
		v_lbl.name = "ValueLabel"
		row.add_child(v_lbl)
	else:
		var editor: Control = _make_editor(prop_name, type)
		editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(editor)
	_form_vbox.add_child(row)


func _property_info(prop_name: String) -> Dictionary:
	for p in SimParams.get_property_list():
		if String(p.name) == prop_name:
			return p
	return {}


func _is_readonly_name(prop_name: String, pinfo: Dictionary) -> bool:
	if prop_name in _DERIVED_READONLY:
		return true
	return (int(pinfo.get("usage", 0)) & PROPERTY_USAGE_READ_ONLY) != 0


func _make_editor(prop_name: String, type: int) -> Control:
	var cur: Variant = SimParams.get(prop_name)
	match type:
		TYPE_BOOL:
			var cb := CheckBox.new()
			cb.button_pressed = bool(cur)
			cb.toggled.connect(func(on: bool) -> void: SimParams.set(prop_name, on))
			return cb
		TYPE_INT:
			var sb := SpinBox.new()
			sb.min_value = -2147483648
			sb.max_value = 2147483647
			sb.step = 1
			sb.rounded = true
			sb.value = int(cur)
			sb.value_changed.connect(func(v: float) -> void: SimParams.set(prop_name, int(v)))
			return sb
		TYPE_FLOAT:
			var sb2 := SpinBox.new()
			sb2.min_value = -1e12
			sb2.max_value = 1e12
			sb2.step = 0.0001
			sb2.value = float(cur)
			sb2.value_changed.connect(func(v: float) -> void: SimParams.set(prop_name, v))
			return sb2
		TYPE_COLOR:
			var cp := ColorPickerButton.new()
			cp.color = cur as Color
			cp.edit_alpha = true
			cp.color_changed.connect(func(c: Color) -> void: SimParams.set(prop_name, c))
			return cp
		TYPE_VECTOR3I:
			var le := LineEdit.new()
			var v3: Vector3i = cur as Vector3i
			le.text = "%d,%d,%d" % [v3.x, v3.y, v3.z]
			le.placeholder_text = "x,y,z"
			le.text_submitted.connect(func(_t: String) -> void: _apply_vector3i_line(prop_name, le))
			le.focus_exited.connect(func() -> void: _apply_vector3i_line(prop_name, le))
			return le
		_:
			if cur is Array:
				var le2 := LineEdit.new()
				le2.text = _array_floats_to_csv(cur as Array)
				le2.placeholder_text = "comma-separated floats"
				le2.text_submitted.connect(func(_t: String) -> void: _apply_array_line(prop_name, le2))
				le2.focus_exited.connect(func() -> void: _apply_array_line(prop_name, le2))
				return le2
			var fallback := LineEdit.new()
			fallback.text = str(cur)
			fallback.text_submitted.connect(func(t: String) -> void: SimParams.set(prop_name, t))
			return fallback


func _apply_vector3i_line(prop_name: String, le: LineEdit) -> void:
	var parts: PackedStringArray = le.text.split(",")
	if parts.size() != 3:
		return
	SimParams.set(prop_name, Vector3i(int(parts[0].strip_edges()), int(parts[1].strip_edges()), int(parts[2].strip_edges())))


func _apply_array_line(prop_name: String, le: LineEdit) -> void:
	var parts: PackedStringArray = le.text.split(",")
	var arr: Array[float] = []
	for s in parts:
		var t: String = s.strip_edges()
		if t.is_empty():
			continue
		arr.append(float(t))
	SimParams.set(prop_name, arr)


func _array_floats_to_csv(a: Array) -> String:
	var bits: PackedStringArray = []
	for x in a:
		bits.append(str(float(x)))
	return ",".join(bits)


func _apply_controls_to_sim_params() -> void:
	# Values are already pushed on edit for interactive controls; re-read vector/array line edits from tree.
	for row in _form_vbox.get_children():
		if not row is HBoxContainer:
			continue
		var h: HBoxContainer = row as HBoxContainer
		if h.get_child_count() < 2:
			continue
		var lbl: Label = h.get_child(0) as Label
		if lbl == null:
			continue
		var prop_name: String = lbl.text
		var pinfo: Dictionary = _property_info(prop_name)
		if _is_readonly_name(prop_name, pinfo):
			continue
		var ed: Control = h.get_child(1) as Control
		if ed is LineEdit and SimParams.get(prop_name) is Vector3i:
			_apply_vector3i_line(prop_name, ed as LineEdit)
		elif ed is LineEdit and SimParams.get(prop_name) is Array:
			_apply_array_line(prop_name, ed as LineEdit)


func _process(_delta: float) -> void:
	# Keep derived (read-only) labels in sync when independent vars change.
	for row in _form_vbox.get_children():
		if not row is HBoxContainer:
			continue
		var h: HBoxContainer = row as HBoxContainer
		if h.get_child_count() < 2:
			continue
		var lbl: Label = h.get_child(0) as Label
		if lbl == null:
			continue
		var prop_name: String = lbl.text
		var pinfo: Dictionary = _property_info(prop_name)
		if not _is_readonly_name(prop_name, pinfo):
			continue
		var v_lbl: Label = h.get_child(1) as Label
		if v_lbl and str(v_lbl.name) == "ValueLabel":
			v_lbl.text = str(SimParams.get(prop_name))
