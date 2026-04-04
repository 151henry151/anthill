--[[
  Scale target: one node reads like one grain of sand; ant body length ~100 nodes.
  This registers a debug cube entity at that visual scale (Minetest "cube" visual).
]]

local HALF = 50 -- ~100 nodes wide collision extent from center
-- Spawn /spawn_ant high enough that the collision box clears flat desert surface.
local SURFACE_PAD = 55

minetest.register_entity("anthill_ant:giant", {
	initial_properties = {
		visual = "cube",
		textures = { "default_desert_sand.png" },
		visual_size = { x = 100, y = 100, z = 100 },
		collisionbox = { -HALF, -HALF, -HALF, HALF, HALF, HALF },
		physical = true,
		collide_with_objects = true,
		stepheight = 0,
	},
	on_activate = function(self, staticdata, dtime_s)
		self.object:set_acceleration({ x = 0, y = -10, z = 0 })
	end,
})

minetest.register_chatcommand("spawn_ant", {
	params = "",
	description = "Spawn a giant ant placeholder near your position (needs server priv)",
	privs = { server = true },
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "No player."
		end
		local pos = player:get_pos()
		-- Spawn above ground so the huge collision box clears the surface.
		pos.y = pos.y + HALF + SURFACE_PAD
		local ent = minetest.add_entity(pos, "anthill_ant:giant")
		if ent then
			return true, "Spawned anthill_ant:giant."
		end
		return false, "Could not spawn entity."
	end,
})
