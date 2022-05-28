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

function world_util.findAllIndustries(filterFunc, mapFunc)
	local result = {}
	api.engine.forEachEntityWithComponent(function(id, simBuilding)
		local conId = simBuilding.stockList
		local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
		if not filterFunc or filterFunc(conId, con) then
			result[#result+1] = mapFunc and mapFunc(conId, con, simBuilding) or {conId, con, simBuilding}
		end
	end, api.type.ComponentType.SIM_BUILDING)
	return result
end

function world_util.findIndustriesInBox(pos, size)
	local pos2f = api.type.Vec2f.new(pos[1], pos[2])
	local pos3f = api.type.Vec3f.new(pos[1], pos[2], api.engine.terrain.getBaseHeightAt(pos2f))
	local halfSize3f = api.type.Vec3f.new(size[1], size[2], 100)
	local box3f = api.type.Box3.new(pos3f - halfSize3f, pos3f + halfSize3f)
	local result = {}
	api.engine.system.octreeSystem.findIntersectingEntities(box3f, function(id)
		local con = api.engine.getComponent(id, api.type.ComponentType.CONSTRUCTION)
		if con and #con.simBuildings > 0 then
			result[#result+1] = {id, con}
		end
	end)
	return result
end

function world_util.anyConstructionInRadius(pos, radius)
	local ents = game.interface.getEntities({pos = {pos[1], pos[2]}, radius = radius}, {type = "CONSTRUCTION"})
	return #ents > 0
end

return world_util