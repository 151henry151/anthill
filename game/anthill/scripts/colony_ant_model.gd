extends RefCounted
class_name ColonyAntModel
## Procedural low-poly ant for colony view: abdomen segments, waist, thorax, head, antennae, six legs.

const _LegPairsZ := [-0.35, 0.25, 0.85]


func build_ant() -> Node3D:
	var root := Node3D.new()
	root.name = "ColonyAnt"

	# High-contrast black on sand; unshaded + emission so near-black albedo stays visible.
	var mat_body: StandardMaterial3D = _mat_black()
	var mat_leg: StandardMaterial3D = _mat_black(0.92)
	var mat_antenna: StandardMaterial3D = _mat_black(0.88)

	# +Z = head direction, -Z = rear. Body sits above y=0 (sand surface).
	# Rear abdomen (largest segment)
	_add_sphere(root, Vector3(0.0, 0.95, -3.15), 1.05, mat_body)
	# Mid abdomen
	_add_sphere(root, Vector3(0.0, 1.0, -1.75), 0.82, mat_body)
	# Petiole (narrow waist)
	_add_cylinder(root, Vector3(0.0, 1.02, -0.75), Vector3(90, 0, 0), 0.32, 0.55, mat_body)
	# Thorax
	_add_box(root, Vector3(0.0, 1.08, 0.15), Vector3(1.35, 0.75, 1.15), mat_body)
	# Head
	_add_sphere(root, Vector3(0.0, 1.12, 1.42), 0.52, mat_body)

	# Antennae — forward / outward from head
	_add_cylinder(root, Vector3(-0.38, 1.35, 1.78), Vector3(35, -15, -20), 0.1, 2.0, mat_antenna)
	_add_cylinder(root, Vector3(0.38, 1.35, 1.78), Vector3(35, 15, 20), 0.1, 2.0, mat_antenna)

	# Six legs — three pairs along thorax / petiole
	for z in _LegPairsZ:
		_add_leg_pair(root, z, mat_leg)

	return root


## `shade` slightly scales emission so legs/antennae read apart from the body.
static func _mat_black(shade: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.02, 0.02, 0.02)
	m.emission_enabled = true
	# Pure black albedo is invisible with zero emission; keep ants reading as black on tan sand.
	var e: float = 0.22 * shade
	m.emission = Color(e, e, e)
	return m


static func _add_sphere(parent: Node3D, pos: Vector3, radius: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	mi.mesh = s
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)


static func _add_box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)


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
	c.bottom_radius = radius * 1.08
	c.height = height
	mi.mesh = c
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)


static func _add_leg_pair(parent: Node3D, z: float, mat: Material) -> void:
	# Left leg — splay down and outward (-X)
	var left := MeshInstance3D.new()
	var cyl_l := CylinderMesh.new()
	cyl_l.top_radius = 0.14
	cyl_l.bottom_radius = 0.2
	cyl_l.height = 2.35
	left.mesh = cyl_l
	left.material_override = mat
	left.position = Vector3(-0.85, 0.55, z)
	left.rotation_degrees = Vector3(58.0, -25.0, -35.0)
	parent.add_child(left)
	# Right leg — mirror
	var right := MeshInstance3D.new()
	var cyl_r := CylinderMesh.new()
	cyl_r.top_radius = 0.14
	cyl_r.bottom_radius = 0.2
	cyl_r.height = 2.35
	right.mesh = cyl_r
	right.material_override = mat
	right.position = Vector3(0.85, 0.55, z)
	right.rotation_degrees = Vector3(58.0, 25.0, 35.0)
	parent.add_child(right)
