-- Giant ants: ~80-node visual cube, smaller collision; wander + trail + nest bias + separation.
-- Scale matches “one node = one grain”; observer camera stays far above (see player_spawn.lua).

anthill = anthill or {}
anthill.ant_list = anthill.ant_list or {}

local COLL_HALF = 34
local VIS = 80
local SPEED = 11
local PHERO_W = 0.42
local HOME_W = 0.22
local SEP_R = 52
local SEP_W = 0.55
local TRAIL_DT = 0.18

local function clamp(v, a, b)
	if v < a then
		return a
	end
	if v > b then
		return b
	end
	return v
end

local function forward_from_yaw(yaw)
	return vector.new(-math.sin(yaw), 0, math.cos(yaw))
end

local function ground_y_for_ant(pos)
	local top = vector.add(pos, vector.new(0, COLL_HALF + 2, 0))
	local bot = vector.add(pos, vector.new(0, -COLL_HALF - 260, 0))
	local ray = minetest.raycast(top, bot, false, false)
	for hit in ray do
		if hit.type == "node" then
			return hit.intersection_point.y + COLL_HALF + 0.5
		end
	end
	return pos.y
end

local function separation(self, pos)
	local out = vector.new(0, 0, 0)
	for _, other in ipairs(anthill.ant_list) do
		if other ~= self and other.object then
			local op = other.object:get_pos()
			local d = vector.distance(pos, op)
			if d > 0.1 and d < SEP_R then
				local away = vector.subtract(pos, op)
				away.y = 0
				out = vector.add(out, vector.multiply(vector.normalize(away), (SEP_R - d) / SEP_R))
			end
		end
	end
	if vector.length(out) < 0.01 then
		return nil
	end
	return vector.normalize(out)
end

minetest.register_entity("anthill:ant", {
	initial_properties = {
		visual = "cube",
		textures = { "blank.png^[colorize:#3d2817" },
		visual_size = { x = VIS, y = VIS, z = VIS },
		collisionbox = { -COLL_HALF, -COLL_HALF, -COLL_HALF, COLL_HALF, COLL_HALF, COLL_HALF },
		physical = true,
		collide_with_objects = false,
		stepheight = 0,
	},
	on_activate = function(self, staticdata, dtime_s)
		self.state = {
			wander_acc = 0,
			trail_acc = 0,
			stuck_acc = 0,
			last_pos = self.object:get_pos(),
		}
		table.insert(anthill.ant_list, self)
		self.object:set_acceleration({ x = 0, y = -10, z = 0 })
	end,
	on_deactivate = function(self, removal)
		for i, o in ipairs(anthill.ant_list) do
			if o == self then
				table.remove(anthill.ant_list, i)
				break
			end
		end
	end,
	get_staticdata = function(self)
		return ""
	end,
	on_step = function(self, dtime)
		local obj = self.object
		local pos = obj:get_pos()
		local yaw = obj:get_yaw()

		-- Wander: slowly adjust heading
		self.state.wander_acc = self.state.wander_acc + dtime
		if self.state.wander_acc > 0.35 + math.random() * 0.45 then
			self.state.wander_acc = 0
			obj:set_yaw(yaw + (math.random() - 0.5) * 1.1)
			yaw = obj:get_yaw()
		end

		local f = forward_from_yaw(yaw)
		local v = vector.new(f.x, 0, f.z)

		local grad = anthill.pheromone_gradient("trail", pos)
		if grad then
			v = vector.add(v, vector.multiply(grad, PHERO_W))
		end

		local nest = {
			x = 0,
			y = anthill.nest_surface_y or anthill.get_surface_y(0, 0),
			z = 0,
		}
		local to_nest = vector.new(nest.x - pos.x, 0, nest.z - pos.z)
		local dh = vector.length(to_nest)
		if dh > 18 then
			local hn = vector.normalize(to_nest)
			v = vector.add(v, vector.multiply(hn, HOME_W))
		end

		local sep = separation(self, pos)
		if sep then
			v = vector.add(v, vector.multiply(sep, SEP_W))
		end

		if vector.length(v) > 0.02 then
			v = vector.normalize(v)
		else
			v = f
		end

		local gy = ground_y_for_ant(pos)
		local vy = obj:get_velocity().y
		if pos.y > gy + 4 then
			vy = math.min(vy - 18 * dtime, -6)
		elseif pos.y < gy - 3 then
			vy = 9
		else
			vy = clamp(vy * 0.92, -4, 4)
		end

		obj:set_velocity({ x = v.x * SPEED, y = vy, z = v.z * SPEED })

		-- Deposit exploration trail while moving horizontally
		self.state.trail_acc = self.state.trail_acc + dtime
		if self.state.trail_acc > TRAIL_DT then
			self.state.trail_acc = 0
			anthill.pheromone_deposit("trail", pos, 0.35)
		end

		-- Anti-stuck: nudge yaw if barely moving
		local moved = vector.distance(pos, self.state.last_pos)
		self.state.last_pos = pos
		if moved < 0.08 * dtime * 30 then
			self.state.stuck_acc = self.state.stuck_acc + dtime
		else
			self.state.stuck_acc = 0
		end
		if self.state.stuck_acc > 2.2 then
			self.state.stuck_acc = 0
			obj:set_yaw(yaw + math.pi * 0.5 + (math.random() - 0.5))
		end
	end,
})

function anthill.spawn_ant_near(origin, spread)
	origin = origin or { x = 0, y = 0, z = 0 }
	spread = spread or 70
	local ox = (math.random() - 0.5) * 2 * spread
	local oz = (math.random() - 0.5) * 2 * spread
	local gx = origin.x + ox
	local gz = origin.z + oz
	local sy = anthill.get_surface_y(gx, gz)
	local pos = { x = gx, y = sy + COLL_HALF + 48, z = gz }
	local ent = minetest.add_entity(pos, "anthill:ant")
	return ent
end
