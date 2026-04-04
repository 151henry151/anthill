anthill = anthill or {}

minetest.register_chatcommand("spawn_ants", {
	params = "[count]",
	description = "Spawn large ants near the nest (default 8)",
	privs = { server = true },
	func = function(name, param)
		local n = tonumber(param) or 8
		n = math.floor(math.max(1, math.min(n, 48)))
		local ok = 0
		for _ = 1, n do
			if anthill.spawn_ant_near({ x = 0, y = 0, z = 0 }, 85) then
				ok = ok + 1
			end
		end
		return true, ("Spawned %d ants."):format(ok)
	end,
})

minetest.register_chatcommand("ant_count", {
	description = "Print active ant entity count",
	privs = { server = true },
	func = function()
		return true, ("Active ants: %d"):format(#anthill.ant_list)
	end,
})
