---@class Box2
local box2 = {}

---@return Box2
function box2.fromPosAndSize(pos, size)
	local o = {
		min = {pos[1] - size[1], pos[2] - size[2]},
		max = {pos[1] + size[1], pos[2] + size[2]}
	}
	setmetatable(o, {__index = box2})
	return o
end

---@param b1 Box2
---@param b2 Box2
---@return boolean
function box2.intersects(b1, b2)
	return
		b1.max[1] > b2.min[1] and b1.max[2] > b2.min[2] and
		b1.min[1] < b2.max[1] and b1.min[2] < b2.max[2]
end

---@param b1 Box2
---@param b2 Box2
---@return boolean
function box2.contains(b1, b2)
	return
		b2.min[1] > b1.min[1] and b2.min[2] > b1.min[2] and
		b2.max[1] < b1.max[1] and b2.max[2] < b1.max[2]
end

return box2