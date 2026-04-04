-- Spectator-only “camera”: stay far above the dunes so many large ants fit in frame; no zoom telescope.

anthill = anthill or {}

-- Vertical offset above local terrain (nodes). Default 176 keeps the camera within ~11 mapblocks
-- vertically so the stock client viewing_range (~190 → ~12 mapblocks of server send radius) still
-- loads ground mapblocks. User ~/.minetest/minetest.conf overrides game minetest.conf for
-- viewing_range; raising viewing_range to ~1200 lets you set anthill_observer_clearance toward 520.
local OBSERVER_CLEARANCE = 176

local function refresh_observer_clearance()
	local s = minetest.settings:get("anthill_observer_clearance")
	local v = tonumber(s)
	if v and v >= 80 and v <= 600 then
		OBSERVER_CLEARANCE = math.floor(v)
	else
		OBSERVER_CLEARANCE = 176
	end
	anthill.observer_clearance = OBSERVER_CLEARANCE
end

minetest.register_on_mods_loaded(function()
	refresh_observer_clearance()
end)

anthill.observer_clearance = OBSERVER_CLEARANCE

-- Default engine clouds sit near y≈120; spectator is usually well above that. Put the cloud deck
-- high so we can look up at clouds from the lowered default clearance.
local CLOUD_BASE_Y = 1180

local function min_observer_y_at(x, z)
	return anthill.get_surface_y(x, z) + OBSERVER_CLEARANCE
end

local function place_observer(player)
	local sy = anthill.get_surface_y(0, 0)
	player:set_pos({ x = 0, y = min_observer_y_at(0, 0), z = 0 })
	player:set_look_horizontal(0)
	-- Horizontal default; look freely (up at clouds, down at ground). Mapblock reach uses viewing_range.
	if player.set_look_vertical then
		player:set_look_vertical(0)
	end
	-- Moderate FOV; engine zoom is disabled via zoom_fov = 0 in set_properties.
	if player.set_fov then
		player:set_fov(72, false)
	end
end

anthill.place_observer = place_observer

function anthill.apply_observer_visibility(player)
	if not player then
		return
	end
	if player.set_clouds then
		player:set_clouds({
			height = CLOUD_BASE_Y,
			thickness = 24,
			density = 0.4,
		})
	end
	-- Push fog out. Client caps wanted_range to min(viewing_range, fog_distance) per frame when
	-- fog_distance >= 0 — keep this well above viewing_range (see anthill_game/minetest.conf).
	if player.set_sky then
		player:set_sky({
			fog = {
				fog_distance = 6000,
				fog_start = 0.88,
			},
		})
	end
end

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
		anthill.apply_observer_visibility(player)
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
	minetest.after(0.35, function()
		local p = minetest.get_player_by_name(name)
		if p then
			anthill.apply_observer_visibility(p)
		end
	end)
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
