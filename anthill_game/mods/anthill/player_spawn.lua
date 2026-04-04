-- Observer player: spawn high above the nest so the dune field is visible.

anthill = anthill or {}

minetest.register_on_newplayer(function(player)
	local y = anthill.get_surface_y(0, 0) + 96
	player:set_pos({ x = 0, y = y, z = 0 })
end)

minetest.register_on_joinplayer(function(player)
	player:set_properties({
		visual = "cube",
		textures = { "blank.png^[colorize:#6a5a4a" },
		visual_size = { x = 1, y = 2, z = 1 },
		collisionbox = { -0.35, 0, -0.35, 0.35, 1.8, 0.35 },
		eye_height = 1.55,
	})
	player:set_physics_override({ speed = 1.2, jump = 1.1, gravity = 1 })
end)
