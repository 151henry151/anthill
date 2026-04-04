--[[
  Anthill desert base map: flat generator + full-chunk fill so nothing else
  (trees, plants, decorations) can remain. Uses default desert sand / stone.
  Create a new world after enabling this mod so mapgen settings apply.
]]

local SURFACE_Y = 8
local SAND_DEPTH = 4

minetest.register_on_mods_loaded(function()
	minetest.set_mapgen_setting("mg_name", "flat", true)
	minetest.set_mapgen_setting("mgflat_height", tostring(SURFACE_Y), true)
end)

minetest.register_on_generated(function(minp, maxp, blockseed)
	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new({ MinEdge = emin, MaxEdge = emax })
	local data = vm:get_data()

	local c_air = minetest.get_content_id("air")
	local c_sand = minetest.get_content_id("default:desert_sand")
	local c_stone = minetest.get_content_id("default:desert_stone")

	for z = emin.z, emax.z do
		for y = emin.y, emax.y do
			for x = emin.x, emax.x do
				local vi = area:index(x, y, z)
				if y > SURFACE_Y then
					data[vi] = c_air
				elseif y > SURFACE_Y - SAND_DEPTH then
					data[vi] = c_sand
				else
					data[vi] = c_stone
				end
			end
		end
	end

	vm:set_data(data)
	vm:write_to_map(true)
end)
