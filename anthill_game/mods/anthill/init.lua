--[[
  Anthill: Luanti-engine-only desert grain world + giant ant simulation.
]]

anthill = {
	ant_list = {},
}

-- Mapblocks (16³ nodes): default engine limits are too small for a ~520-node-high spectator.
minetest.register_on_mods_loaded(function()
	minetest.settings:set("max_block_send_distance", "72")
	minetest.settings:set("active_object_send_range_blocks", "64")
end)

local mp = minetest.get_modpath("anthill")
dofile(mp .. "/nodes.lua")
dofile(mp .. "/pheromone.lua")
dofile(mp .. "/mapgen.lua")
dofile(mp .. "/player_spawn.lua")
dofile(mp .. "/ant_entity.lua")
dofile(mp .. "/commands.lua")

-- Initial colony (once per world): spawn near the dune field beside the nest quarter.
local storage = minetest.get_mod_storage()
minetest.register_on_mods_loaded(function()
	minetest.after(0, function()
		if storage:get_string("initial_colony") == "1" then
			return
		end
		storage:set_string("initial_colony", "1")
		local y0 = anthill.get_surface_y(12, -8)
		for _ = 1, 10 do
			anthill.spawn_ant_near({ x = 12, y = y0, z = -8 }, 55)
		end
	end)
end)
