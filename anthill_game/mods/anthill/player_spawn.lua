-- Spectator-only “camera”: stay far above the dunes so many large ants fit in frame; no zoom telescope.

anthill = anthill or {}

-- Nodes above *local* terrain height. Ants are ~80 nodes across; ~500+ keeps several to many ants
-- in a typical downward FOV without filling the screen with one ant.
local OBSERVER_CLEARANCE = 520

anthill.observer_clearance = OBSERVER_CLEARANCE

local function min_observer_y_at(x, z)
	return anthill.get_surface_y(x, z) + OBSERVER_CLEARANCE
end

local function place_observer(player)
	local sy = anthill.get_surface_y(0, 0)
	player:set_pos({ x = 0, y = min_observer_y_at(0, 0), z = 0 })
	player:set_look_horizontal(0)
	-- API: positive look_vertical = look downward; ~1.1 rad looks steeply at the ground.
	if player.set_look_vertical then
		player:set_look_vertical(1.1)
	end
	-- Moderate FOV; engine zoom is disabled via zoom_fov = 0 in set_properties.
	if player.set_fov then
		player:set_fov(72, false)
	end
end

anthill.place_observer = place_observer

local function enforce_observer_altitude(player)
	local pos = player:get_pos()
	local floor_y = min_observer_y_at(pos.x, pos.z)
	if pos.y < floor_y - 0.25 then
		pos.y = floor_y
		player:set_pos(pos)
	end
end

minetest.register_globalstep(function()
	for _, player in ipairs(minetest.get_connected_players()) do
		enforce_observer_altitude(player)
	end
end)

minetest.register_chatcommand("observer_reset", {
	description = "Move to the default high spectator view above the nest",
	privs = { server = true },
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "No player."
		end
		player:get_meta():set_string("anthill_observer_setup", "1")
		place_observer(player)
		return true, "Observer position updated."
	end,
})

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local privs = minetest.get_player_privs(name)
	privs.fly = true
	privs.noclip = true
	minetest.set_player_privs(name, privs)

	player:set_properties({
		visual = "cube",
		textures = { "blank.png^[colorize:#6a5a4a" },
		visual_size = { x = 1, y = 2, z = 1 },
		collisionbox = { -0.35, 0, -0.35, 0.35, 1.8, 0.35 },
		eye_height = 1.55,
		zoom_fov = 0,
	})
	-- Spectator: slow pan, no survival movement fantasy.
	player:set_physics_override({ speed = 0.35, jump = 0, gravity = 1 })

	local meta = player:get_meta()
	if meta:get_string("anthill_observer_setup") == "" then
		minetest.after(0.15, function()
			local p = minetest.get_player_by_name(name)
			if not p then
				return
			end
			meta:set_string("anthill_observer_setup", "1")
			place_observer(p)
		end)
	end
end)
