extends RefCounted
class_name VoxelMeshBuilder

const COL_SAND := Color(0.88, 0.78, 0.58)
const COL_STONE := Color(0.42, 0.39, 0.35)


static func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color) -> void:
	st.set_normal(n)
	st.set_color(col)
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(d)


static func build_chunk_mesh(world: WorldManager, chunk: VoxelChunk) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sx := VoxelChunk.SIZE_X
	var sy := VoxelChunk.SIZE_Y
	var sz := VoxelChunk.SIZE_Z
	var ox := chunk.cx * sx
	var oz := chunk.cz * sz
	for lz in sz:
		for ly in sy:
			for lx in sx:
				var id := chunk.get_b(lx, ly, lz)
				if id == GameConstants.BLOCK_AIR:
					continue
				var col := COL_SAND if id == GameConstants.BLOCK_SAND else COL_STONE
				var wx := ox + lx
				var wy := ly
				var wz := oz + lz
				var base := Vector3(wx, wy, wz)
				# Neighbor air check -> expose face
				if world.get_block(wx + 1, wy, wz) == GameConstants.BLOCK_AIR:
					_add_quad(
						st,
						base + Vector3(1, 0, 1),
						base + Vector3(1, 1, 1),
						base + Vector3(1, 1, 0),
						base + Vector3(1, 0, 0),
						Vector3.RIGHT,
						col
					)
				if world.get_block(wx - 1, wy, wz) == GameConstants.BLOCK_AIR:
					_add_quad(
						st,
						base + Vector3(0, 0, 0),
						base + Vector3(0, 1, 0),
						base + Vector3(0, 1, 1),
						base + Vector3(0, 0, 1),
						Vector3.LEFT,
						col
					)
				if world.get_block(wx, wy + 1, wz) == GameConstants.BLOCK_AIR:
					_add_quad(
						st,
						base + Vector3(0, 1, 0),
						base + Vector3(1, 1, 0),
						base + Vector3(1, 1, 1),
						base + Vector3(0, 1, 1),
						Vector3.UP,
						col
					)
				if world.get_block(wx, wy - 1, wz) == GameConstants.BLOCK_AIR:
					_add_quad(
						st,
						base + Vector3(0, 0, 1),
						base + Vector3(1, 0, 1),
						base + Vector3(1, 0, 0),
						base + Vector3(0, 0, 0),
						Vector3.DOWN,
						col
					)
				if world.get_block(wx, wy, wz + 1) == GameConstants.BLOCK_AIR:
					_add_quad(
						st,
						base + Vector3(0, 0, 1),
						base + Vector3(0, 1, 1),
						base + Vector3(1, 1, 1),
						base + Vector3(1, 0, 1),
						Vector3.BACK,
						col
					)
				if world.get_block(wx, wy, wz - 1) == GameConstants.BLOCK_AIR:
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
