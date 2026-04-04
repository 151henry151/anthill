-- Sand "grains" (nodes) and underground stone; nest marker at colony origin.

local function tile(hex)
	return ("blank.png^[colorize:#%s"):format(hex)
end

minetest.register_node("anthill:sand", {
	description = "Sand grain",
	tiles = { tile("c9b28c"), tile("b8a078"), tile("c9b28c") },
	groups = { crumbly = 3, oddly_breakable_by_hand = 1, sand = 1 },
})

minetest.register_node("anthill:stone", {
	description = "Desert bedrock",
	tiles = { tile("6b5b4f") },
	groups = { cracky = 2 },
})

minetest.register_node("anthill:nest", {
	description = "Colony nest",
	drawtype = "nodebox",
	tiles = { tile("4a3528"), tile("3d2a1f") },
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.45, -0.5, -0.45, 0.45, -0.15, 0.45 },
		},
	},
	groups = { crumbly = 2, oddly_breakable_by_hand = 1 },
})

-- Flat / engine mapgen expects these aliases before our on_generated pass runs.
minetest.register_alias("mapgen_stone", "anthill:stone")
minetest.register_alias("mapgen_water_source", "air")
minetest.register_alias("mapgen_river_water_source", "air")
