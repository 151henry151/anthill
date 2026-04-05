extends RefCounted
class_name VoxelMeshBuilder

const _Const := preload("res://scripts/constants.gd")
const _Chunk := preload("res://scripts/world/chunk_data.gd")
const _TerrainGen := preload("res://scripts/world/terrain_gen.gd")

const COL_SAND := Color(0.88, 0.78, 0.58)
const COL_STONE := Color(0.42, 0.39, 0.35)
const COL_PACKED_SAND := Color(0.72, 0.60, 0.38)

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
	var lox: float = float(ox)
	var loz: float = float(oz)
	var y_lo: int = maxi(_MESH_Y_LO, 0)
	var y_hi: int = mini(_MESH_Y_HI, sy - 1)
	var data: PackedByteArray = chunk.data
	var stride_y: int = sx
	var stride_z: int = sx * sy
	var inv_depth: float = 1.0 / _Const.XRAY_DEPTH_FADE_RANGE
	var surface_base: int = _TerrainGen.SURFACE_BASE
	for lz in range(sz):
		var z_off: int = lz * stride_z
		for ly in range(y_lo, y_hi + 1):
			var yz_off: int = z_off + ly * stride_y
			for lx in range(sx):
				var id: int = data[yz_off + lx]
				if id == _Const.BLOCK_AIR:
					continue
				var wx: int = ox + lx
				var wy: int = ly
				var wz: int = oz + lz
				var col: Color
				if id == _Const.BLOCK_SAND:
					col = COL_SAND
				elif id == _Const.BLOCK_PACKED_SAND:
					col = COL_PACKED_SAND
				else:
					col = COL_STONE
				var df: float = clampf(float(surface_base - wy) * inv_depth, 0.0, 1.0)
				col = Color(col.r * (1.0 - df * 0.3), col.g * (1.0 - df * 0.15), col.b, col.a)
				var base := Vector3(float(lx), float(wy), float(lz))
				# Neighbor checks: use local array when neighbor is in-chunk; fall back to world.get_block at chunk borders.
				var n_px: int
				if lx < sx - 1:
					n_px = data[yz_off + lx + 1]
				else:
					n_px = world.get_block(wx + 1, wy, wz)
				if n_px == _Const.BLOCK_AIR:
					_add_quad(st, base + Vector3(1,0,1), base + Vector3(1,1,1), base + Vector3(1,1,0), base + Vector3(1,0,0), Vector3.RIGHT, col)
				var n_nx: int
				if lx > 0:
					n_nx = data[yz_off + lx - 1]
				else:
					n_nx = world.get_block(wx - 1, wy, wz)
				if n_nx == _Const.BLOCK_AIR:
					_add_quad(st, base + Vector3(0,0,0), base + Vector3(0,1,0), base + Vector3(0,1,1), base + Vector3(0,0,1), Vector3.LEFT, col)
				var n_py: int
				if ly < sy - 1:
					n_py = data[z_off + (ly + 1) * stride_y + lx]
				else:
					n_py = _Const.BLOCK_AIR
				if n_py == _Const.BLOCK_AIR:
					_add_quad(st, base + Vector3(0,1,0), base + Vector3(1,1,0), base + Vector3(1,1,1), base + Vector3(0,1,1), Vector3.UP, col)
				var n_ny: int
				if ly > 0:
					n_ny = data[z_off + (ly - 1) * stride_y + lx]
				else:
					n_ny = world.get_block(wx, wy - 1, wz)
				if n_ny == _Const.BLOCK_AIR:
					_add_quad(st, base + Vector3(0,0,1), base + Vector3(1,0,1), base + Vector3(1,0,0), base + Vector3(0,0,0), Vector3.DOWN, col)
				var n_pz: int
				if lz < sz - 1:
					n_pz = data[(lz + 1) * stride_z + ly * stride_y + lx]
				else:
					n_pz = world.get_block(wx, wy, wz + 1)
				if n_pz == _Const.BLOCK_AIR:
					_add_quad(st, base + Vector3(0,0,1), base + Vector3(0,1,1), base + Vector3(1,1,1), base + Vector3(1,0,1), Vector3.BACK, col)
				var n_nz: int
				if lz > 0:
					n_nz = data[(lz - 1) * stride_z + ly * stride_y + lx]
				else:
					n_nz = world.get_block(wx, wy, wz - 1)
				if n_nz == _Const.BLOCK_AIR:
					_add_quad(st, base + Vector3(1,0,0), base + Vector3(1,1,0), base + Vector3(0,1,0), base + Vector3(0,0,0), Vector3.FORWARD, col)
	var mesh: ArrayMesh = st.commit()
	return mesh
