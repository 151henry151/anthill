extends RefCounted
class_name ColonyAntModel

## Procedural ant for colony view: hymenopteran layout (+Z = head), ~realistic proportions at small scale.
## Local body length (gaster rear → head front) is **MODEL_BODY_LENGTH**; scale root by **~3** for **~3** voxels long.

const MODEL_BODY_LENGTH := 1.0

const _MatBody := 1.0
const _MatLeg := 0.9
const _MatAnt := 0.85


func build_ant() -> Node3D:
	var root := Node3D.new()
	root.name = "ColonyAnt"

	var mat_body: StandardMaterial3D = _mat_black(_MatBody)
	var mat_leg: StandardMaterial3D = _mat_black(_MatLeg)
	var mat_ant: StandardMaterial3D = _mat_black(_MatAnt)

	# --- Body axis +Z = anterior (head). Sand plane y = 0; body clears the ground. ---
	# Gaster (oval): largest segment, tapers toward waist
	var gaster := _mk_sphere(0.14, mat_body)
	gaster.position = Vector3(0.0, 0.11, -0.33)
	gaster.scale = Vector3(1.05, 0.78, 1.25)
	root.add_child(gaster)

	# Petiole “node” (narrow waist)
	_add_cylinder(
		root, Vector3(0.0, 0.11, -0.17), Vector3(90, 0, 0), 0.028, 0.09, mat_body
	)

	# Thorax + propodeum (mesosoma)
	var thorax := _mk_sphere(0.11, mat_body)
	thorax.position = Vector3(0.0, 0.12, 0.02)
	thorax.scale = Vector3(1.15, 0.88, 1.05)
	root.add_child(thorax)

	# Head
	var head := _mk_sphere(0.075, mat_body)
	head.position = Vector3(0.0, 0.125, 0.36)
	head.scale = Vector3(0.95, 0.92, 1.0)
	root.add_child(head)

	# Compound eyes (lateral bumps)
	var eye_l := _mk_sphere(0.028, mat_body)
	eye_l.position = Vector3(-0.07, 0.14, 0.34)
	root.add_child(eye_l)
	var eye_r := _mk_sphere(0.028, mat_body)
	eye_r.position = Vector3(0.07, 0.14, 0.34)
	root.add_child(eye_r)

	# Mandibles (short chevrons)
	_add_cylinder(root, Vector3(-0.038, 0.105, 0.448), Vector3(72, 0, -16), 0.018, 0.055, mat_body)
	_add_cylinder(root, Vector3(0.038, 0.105, 0.448), Vector3(72, 0, 16), 0.018, 0.055, mat_body)

	# Antennae: scape + funiculus (geniculate), thin
	for sx in [-1.0, 1.0]:
		var base := Vector3(sx * 0.06, 0.155, 0.39)
		_add_cylinder(root, base, Vector3(15, sx * 38, 8), 0.018, 0.09, mat_ant)
		var elbow := base + Vector3(sx * 0.1, 0.04, 0.06)
		_add_cylinder(root, elbow, Vector3(22, sx * 12, 35), 0.012, 0.11, mat_ant)

	# Six legs: three pairs on thorax (thin femur + tibia)
	var leg_z: Array[float] = [-0.02, 0.04, 0.1]
	var spread: Array[float] = [-8.0, 0.0, 10.0]
	for i in range(3):
		_leg_side(root, 1.0, leg_z[i], spread[i], mat_leg)
		_leg_side(root, -1.0, leg_z[i], spread[i], mat_leg)

	return root


static func _mk_sphere(radius: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	mi.mesh = s
	mi.material_override = mat
	return mi


static func _leg_side(root: Node3D, side: float, z: float, yaw_off: float, mat: Material) -> void:
	# side: +1 = left (+X), -1 = right
	var attach := Vector3(side * 0.11, 0.11, z)
	# Femur (out and down)
	var fem := MeshInstance3D.new()
	var cf := CylinderMesh.new()
	cf.top_radius = 0.02
	cf.bottom_radius = 0.024
	cf.height = 0.16
	fem.mesh = cf
	fem.material_override = mat
	fem.position = attach + Vector3(side * 0.04, -0.02, 0.0)
	fem.rotation_degrees = Vector3(52.0 + yaw_off * 0.15, side * -22.0, side * 38.0)
	root.add_child(fem)
	# Tibia (to ground)
	var tip := fem.position + Vector3(side * 0.1, -0.11, 0.04)
	var tib := MeshInstance3D.new()
	var ct := CylinderMesh.new()
	ct.top_radius = 0.016
	ct.bottom_radius = 0.014
	ct.height = 0.2
	tib.mesh = ct
	tib.material_override = mat
	tib.position = tip
	tib.rotation_degrees = Vector3(68.0 + yaw_off * 0.2, side * -12.0, side * 25.0)
	root.add_child(tib)


static func _add_cylinder(
	parent: Node3D,
	pos: Vector3,
	rot_deg: Vector3,
	radius: float,
	height: float,
	mat: Material
) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius * 1.05
	c.height = height
	mi.mesh = c
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)


## `shade` slightly scales emission so legs/antennae read apart from the body.
static func _mat_black(shade: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.02, 0.02, 0.02)
	m.emission_enabled = true
	var e: float = 0.22 * shade
	m.emission = Color(e, e, e)
	return m
