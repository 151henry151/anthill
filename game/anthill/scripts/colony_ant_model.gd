extends RefCounted
class_name ColonyAntModel

## Hymenopteran worker layout (+Z = head). **`MODEL_BODY_LENGTH`** ≈ body axis; scale × **`~3`** ≈ **~3** voxels.
const MODEL_BODY_LENGTH := 1.0

var _cached_mesh: ArrayMesh
var _cached_mat: StandardMaterial3D


func build_ant() -> Node3D:
	if _cached_mesh:
		var root := Node3D.new()
		root.name = "ColonyAnt"
		var mi := MeshInstance3D.new()
		mi.mesh = _cached_mesh
		mi.material_override = _cached_mat
		root.add_child(mi)
		return root
	var root_full := _build_ant_parts()
	_cached_mesh = _merge_to_array_mesh(root_full)
	_cached_mat = _mat_exo(1.0)
	for c in root_full.get_children():
		c.queue_free()
	root_full.queue_free()
	var root := Node3D.new()
	root.name = "ColonyAnt"
	var mi := MeshInstance3D.new()
	mi.mesh = _cached_mesh
	mi.material_override = _cached_mat
	root.add_child(mi)
	return root


static func _merge_to_array_mesh(root: Node3D) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for child in root.get_children():
		if child is MeshInstance3D:
			var mi: MeshInstance3D = child
			if mi.mesh == null:
				continue
			var xform: Transform3D = mi.transform
			var arr: Array = mi.mesh.surface_get_arrays(0)
			if arr.is_empty():
				continue
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			if verts.is_empty():
				continue
			var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
			## Primitive meshes (Sphere/Cylinder/…) use **indexed** triangles. The merge optimization previously
			## walked **verts** in array order, which is not triangle order — wrong indices broke lighting/normals
			## and could make the merged ant effectively invisible. Expand **ARRAY_INDEX** when present.
			var idxs: PackedInt32Array = arr[Mesh.ARRAY_INDEX] as PackedInt32Array if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			if idxs.size() > 0:
				for ii in range(idxs.size()):
					var vi: int = int(idxs[ii])
					if vi < 0 or vi >= verts.size():
						continue
					if vi < norms.size():
						st.set_normal((xform.basis * norms[vi]).normalized())
					else:
						st.set_normal(Vector3.UP)
					st.add_vertex(xform * verts[vi])
			else:
				for vi in range(verts.size()):
					if vi < norms.size():
						st.set_normal((xform.basis * norms[vi]).normalized())
					else:
						st.set_normal(Vector3.UP)
					st.add_vertex(xform * verts[vi])
	return st.commit()


func _build_ant_parts() -> Node3D:
	var root := Node3D.new()
	root.name = "ColonyAnt"

	var mat_body: StandardMaterial3D = _mat_exo(1.0)
	var mat_leg: StandardMaterial3D = _mat_exo(0.92)
	var mat_ant: StandardMaterial3D = _mat_exo(0.88)

	# Gaster — dorsally arched oval (Formicidae-like bulk)
	var gaster := _mk_sphere(0.13, mat_body)
	gaster.position = Vector3(0.0, 0.12, -0.34)
	gaster.scale = Vector3(1.12, 0.72, 1.28)
	root.add_child(gaster)

	# Post-petiole scale (optional second node — many spp. have single petiole; reads as “wasp waist”)
	var postpet := _mk_sphere(0.045, mat_body)
	postpet.position = Vector3(0.0, 0.11, -0.21)
	postpet.scale = Vector3(0.9, 0.75, 1.1)
	root.add_child(postpet)

	# Petiole
	_add_cylinder(
		root, Vector3(0.0, 0.11, -0.165), Vector3(90, 0, 0), 0.024, 0.085, mat_body
	)

	# Thorax (alitrunk)
	var thorax := _mk_sphere(0.098, mat_body)
	thorax.position = Vector3(0.0, 0.125, 0.0)
	thorax.scale = Vector3(1.18, 0.9, 1.12)
	root.add_child(thorax)

	# Head — subglobular
	var head := _mk_sphere(0.068, mat_body)
	head.position = Vector3(0.0, 0.128, 0.34)
	head.scale = Vector3(0.98, 0.94, 1.05)
	root.add_child(head)

	# Eyes
	var eye_l := _mk_sphere(0.022, mat_body)
	eye_l.position = Vector3(-0.065, 0.138, 0.32)
	root.add_child(eye_l)
	var eye_r := _mk_sphere(0.022, mat_body)
	eye_r.position = Vector3(0.065, 0.138, 0.32)
	root.add_child(eye_r)

	# Mandibles
	_add_cylinder(root, Vector3(-0.032, 0.108, 0.418), Vector3(74, 0, -14), 0.014, 0.048, mat_body)
	_add_cylinder(root, Vector3(0.032, 0.108, 0.418), Vector3(74, 0, 14), 0.014, 0.048, mat_body)

	# Antennae — scape, pedicel, funiculus (3 segments, geniculate)
	for sx in [-1.0, 1.0]:
		var bx := Vector3(sx * 0.055, 0.15, 0.365)
		_add_cylinder(root, bx, Vector3(12, sx * 42, 6), 0.014, 0.065, mat_ant)
		var mid := bx + Vector3(sx * 0.08, 0.02, 0.04)
		_add_cylinder(root, mid, Vector3(8, sx * 20, 18), 0.01, 0.035, mat_ant)
		var tip := mid + Vector3(sx * 0.06, -0.01, 0.07)
		_add_cylinder(root, tip, Vector3(18, sx * 8, 38), 0.008, 0.095, mat_ant)

	# Six legs — femur / tibia / tarsus
	var leg_z: Array = [-0.03, 0.035, 0.095]
	var spread: Array = [-10.0, 0.0, 12.0]
	for i in range(3):
		_leg_pair(root, 1.0, leg_z[i], spread[i], mat_leg)
		_leg_pair(root, -1.0, leg_z[i], spread[i], mat_leg)

	return root


static func _mk_sphere(radius: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	mi.mesh = s
	mi.material_override = mat
	return mi


static func _leg_pair(root: Node3D, side: float, z: float, yaw_off: float, mat: Material) -> void:
	var attach := Vector3(side * 0.102, 0.112, z)
	# Femur
	var fem := MeshInstance3D.new()
	var cf := CylinderMesh.new()
	cf.top_radius = 0.017
	cf.bottom_radius = 0.021
	cf.height = 0.13
	fem.mesh = cf
	fem.material_override = mat
	fem.position = attach + Vector3(side * 0.035, -0.015, 0.0)
	fem.rotation_degrees = Vector3(48.0 + yaw_off * 0.12, side * -24.0, side * 40.0)
	root.add_child(fem)
	var fknee := fem.position + Vector3(side * 0.085, -0.095, 0.035)
	# Tibia
	var tib := MeshInstance3D.new()
	var ct := CylinderMesh.new()
	ct.top_radius = 0.014
	ct.bottom_radius = 0.012
	ct.height = 0.16
	tib.mesh = ct
	tib.material_override = mat
	tib.position = fknee
	tib.rotation_degrees = Vector3(62.0 + yaw_off * 0.18, side * -14.0, side * 28.0)
	root.add_child(tib)
	var ttip := tib.position + Vector3(side * 0.06, -0.12, 0.03)
	# Tarsus (foot)
	var tar := MeshInstance3D.new()
	var cta := CylinderMesh.new()
	cta.top_radius = 0.01
	cta.bottom_radius = 0.008
	cta.height = 0.09
	tar.mesh = cta
	tar.material_override = mat
	tar.position = ttip
	tar.rotation_degrees = Vector3(78.0, side * -8.0, side * 15.0)
	root.add_child(tar)


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
	c.bottom_radius = radius * 1.04
	c.height = height
	mi.mesh = c
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)


## Dark cuticle: slight **metallic** + **emission** so ants stay readable on **sand** with scene lighting.
static func _mat_exo(shade: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	var a: float = 0.07 * shade
	m.albedo_color = Color(a, a * 0.92, a * 0.88)
	m.metallic = 0.22
	m.roughness = 0.48
	m.emission_enabled = true
	var e: float = 0.06 * shade
	m.emission = Color(e * 0.9, e * 0.88, e * 0.85)
	return m
