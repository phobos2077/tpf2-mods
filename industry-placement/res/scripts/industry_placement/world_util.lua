local vector2 = require "industry_placement/lib/vector2"

local world_util = {}

---@param position table
---@return table
function world_util.getClosestTown(position)
	local towns = game.interface.getEntities({pos = {position[1], position[2]}, radius = 1e10}, {type = "TOWN", includeData = true})
	local minDistance = math.huge
	local closestTown
	for id, townData in pairs(towns) do
		local distance = vector2.distance(position, townData.position)
		if distance < minDistance then
			minDistance = distance
			closestTown = townData
		end
	end
	return closestTown
end

function world_util.getWorldSize()
	local ter = api.engine.getComponent(game.interface.getWorld(), api.type.ComponentType.TERRAIN)
	return {
		ter.size.x / ter.baseResolution.x,
		ter.size.y / ter.baseResolution.y
	}
end

local cachedWorldSize
function world_util.getWorldSizeCached()
	cachedWorldSize = cachedWorldSize or world_util.getWorldSize()
	return cachedWorldSize
end

return world_util