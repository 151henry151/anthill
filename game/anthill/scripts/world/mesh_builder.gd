extends RefCounted
class_name VoxelMeshBuilder

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")
const _TerrainGen := preload("res://scripts/world/terrain_gen.gd")

const COL_SAND := Color(0.88, 0.78, 0.58)
const COL_STONE := Color(0.42, 0.39, 0.35)

## Only scan the Y band that can have exposed faces (surface region +/- margin).
## Deep stone is fully enclosed so it produces no mesh faces.
const _MESH_Y_LO := _TerrainGen.SURFACE_BASE - 50
const _MESH_Y_HI := _TerrainGen.SURFACE_BASE + 20


static func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color) -> void:
	st.set_normal(n)
	st.set_color(col)
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(d)


static func build_chunk_mesh(world: Node, chunk: RefCounted) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sx: int = _Chunk.SIZE_X
	var sy: int = _Chunk.SIZE_Y
	var sz: int = _Chunk.SIZE_Z
	var ox: int = chunk.cx * sx
	var oz: int = chunk.cz * sz
	var y_lo: int = maxi(_MESH_Y_LO, 0)
	var y_hi: int = mini(_MESH_Y_HI, sy - 1)
	for lz in range(sz):
		for ly in range(y_lo, y_hi + 1):
			for lx in range(sx):
				var id: int = chunk.get_b(lx, ly, lz)
				if id == _Const.BLOCK_AIR:
					continue
				var col: Color = COL_SAND if id == _Const.BLOCK_SAND else COL_STONE
				var wx: int = ox + lx
				var wy: int = ly
				var wz: int = oz + lz
				var base := Vector3(wx, wy, wz)
				if world.get_block(wx + 1, wy, wz) == _Const.BLOCK_AIR:
					_add_quad(
						st,
						base + Vector3(1, 0, 1),
						base + Vector3(1, 1, 1),
						base + Vector3(1, 1, 0),
						base + Vector3(1, 0, 0),
						Vector3.RIGHT,
						col
					)
				if world.get_block(wx - 1, wy, wz) == _Const.BLOCK_AIR:
					_add_quad(
						st,
						base + Vector3(0, 0, 0),
						base + Vector3(0, 1, 0),
						base + Vector3(0, 1, 1),
						base + Vector3(0, 0, 1),
						Vector3.LEFT,
						col
					)
				if world.get_block(wx, wy + 1, wz) == _Const.BLOCK_AIR:
					_add_quad(
						st,
						base + Vector3(0, 1, 0),
						base + Vector3(1, 1, 0),
						base + Vector3(1, 1, 1),
						base + Vector3(0, 1, 1),
						Vector3.UP,
						col
					)
				if world.get_block(wx, wy - 1, wz) == _Const.BLOCK_AIR:
					_add_quad(
						st,
						base + Vector3(0, 0, 1),
						base + Vector3(1, 0, 1),
						base + Vector3(1, 0, 0),
						base + Vector3(0, 0, 0),
						Vector3.DOWN,
						col
					)
				if world.get_block(wx, wy, wz + 1) == _Const.BLOCK_AIR:
					_add_quad(
						st,
						base + Vector3(0, 0, 1),
						base + Vector3(0, 1, 1),
						base + Vector3(1, 1, 1),
						base + Vector3(1, 0, 1),
						Vector3.BACK,
						col
					)
				if world.get_block(wx, wy, wz - 1) == _Const.BLOCK_AIR:
					_add_quad(
						st,
						base + Vector3(1, 0, 0),
						base + Vector3(1, 1, 0),
						base + Vector3(0, 1, 0),
						base + Vector3(0, 0, 0),
						Vector3.FORWARD,
						col
					)
	var mesh: ArrayMesh = st.commit()
	return mesh
