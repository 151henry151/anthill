-- Coarse grid pheromone fields (engine has no tiny voxels; we simulate scent on a sparse grid).

anthill = anthill or {}

local CELL = 10
local fields = {
	trail = {}, -- exploration / generic trail
	home = {}, -- bias toward nest
}

local function cell_key(pos)
	local x = math.floor(pos.x / CELL)
	local z = math.floor(pos.z / CELL)
	return ("%d,%d"):format(x, z)
end

function anthill.pheromone_deposit(kind, pos, amount)
	local t = fields[kind]
	if not t then
		return
	end
	local k = cell_key(pos)
	t[k] = (t[k] or 0) + amount
end

function anthill.pheromone_sample(kind, pos)
	local t = fields[kind]
	if not t then
		return 0
	end
	return t[cell_key(pos)] or 0
end

-- Returns a horizontal unit vector toward the strongest neighbor cell, or nil.
function anthill.pheromone_gradient(kind, pos)
	local t = fields[kind]
	if not t then
		return nil
	end
	local best_v = 0
	local best_off = { x = 0, z = 0 }
	for dx = -1, 1 do
		for dz = -1, 1 do
			if dx ~= 0 or dz ~= 0 then
				local p = { x = pos.x + dx * CELL, y = pos.y, z = pos.z + dz * CELL }
				local v = t[cell_key(p)] or 0
				if v > best_v then
					best_v = v
					best_off.x = dx
					best_off.z = dz
				end
			end
		end
	end
	if best_v < 0.05 then
		return nil
	end
	local len = math.sqrt(best_off.x * best_off.x + best_off.z * best_off.z)
	if len < 0.001 then
		return nil
	end
	return vector.normalize({ x = best_off.x / len, y = 0, z = best_off.z / len })
end

local function decay_field(t, dt, rate)
	local mul = math.exp(-dt * rate)
	for k, v in pairs(t) do
		local nv = v * mul
		if nv < 0.02 then
			t[k] = nil
		else
			t[k] = nv
		end
	end
end

minetest.register_globalstep(function(dt)
	decay_field(fields.trail, dt, 0.12)
	decay_field(fields.home, dt, 0.08)
end)

function anthill.seed_nest_scent(surface_y)
	local pos = { x = 0, y = surface_y, z = 0 }
	for _ = 1, 32 do
		anthill.pheromone_deposit("home", pos, 2.0)
	end
end
