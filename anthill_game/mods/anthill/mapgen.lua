-- Procedural desert dunes: one node = one "grain"; surface height from 2D Perlin noise.

anthill = anthill or {}

local SURFACE_BASE = 32
local DUNE_AMP = 14
local SAND_DEPTH = 7
local np = {
	offset = 0,
	scale = DUNE_AMP,
	spread = { x = 420, y = 420, z = 420 },
	seed = 0,
	octaves = 5,
	persistence = 0.47,
	lacunarity = 2.0,
}

local nest_placed = false
local terrain_noise

local function world_seed()
	local s = minetest.get_mapgen_setting("seed")
	return tonumber(s) or 90210
end

local function terrain_noise_at(x, z)
	if not terrain_noise then
		np.seed = world_seed()
		terrain_noise = minetest.get_perlin(np)
	end
	return terrain_noise:get_2d({ x = x, y = z })
end

function anthill.get_surface_y(x, z)
	return math.floor(SURFACE_BASE + terrain_noise_at(x, z))
end

minetest.register_on_mods_loaded(function()
	minetest.set_mapgen_setting("mg_name", "flat", true)
	minetest.set_mapgen_setting("mgflat_height", tostring(SURFACE_BASE - 8), true)
end)

minetest.register_on_generated(function(minp, maxp, blockseed)
	if not terrain_noise then
		np.seed = world_seed()
		terrain_noise = minetest.get_perlin(np)
	end

	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new({ MinEdge = emin, MaxEdge = emax })
	local data = vm:get_data()

	local c_air = minetest.get_content_id("air")
	local c_sand = minetest.get_content_id("anthill:sand")
	local c_stone = minetest.get_content_id("anthill:stone")
	local c_nest = minetest.get_content_id("anthill:nest")

	for z = emin.z, emax.z do
		for x = emin.x, emax.x do
			local n = terrain_noise:get_2d({ x = x, y = z })
			local surface = math.floor(SURFACE_BASE + n)
			for y = emin.y, emax.y do
				local vi = area:index(x, y, z)
				if y > surface then
					data[vi] = c_air
				elseif y > surface - SAND_DEPTH then
					data[vi] = c_sand
				else
					data[vi] = c_stone
				end
			end
		end
	end

	-- Nest at world origin on first chunk that contains (0,*,0)
	if not nest_placed and minp.x <= 0 and maxp.x >= 0 and minp.z <= 0 and maxp.z >= 0 then
		local sy = anthill.get_surface_y(0, 0)
		if sy >= emin.y and sy <= emax.y then
			local vi = area:index(0, sy, 0)
			data[vi] = c_nest
			nest_placed = true
			anthill.nest_surface_y = sy
			if anthill.seed_nest_scent then
				anthill.seed_nest_scent(sy)
			end
		end
	end

	vm:set_data(data)
	vm:write_to_map(true)
end)
