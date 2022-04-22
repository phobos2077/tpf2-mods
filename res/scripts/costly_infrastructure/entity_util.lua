local util = require 'costly_infrastructure/util'
local vector = require 'costly_infrastructure/vector'
local config = require 'costly_infrastructure/config'

local entity_util = {}

--- Gets all entities on the map with a given type.
---@param type string Entitiy type.
---@return table A list of entities.
function entity_util.getAllEntitiesByType(type)
    return game.interface.getEntities({radius = 1e10}, {type = type})
end

local function getMultByTramType(tramTrackType)
    if tramTrackType == 1 then
        return 1 + game.config.costs.roadTramLane
    end
    if tramTrackType == 2 then
        return 1 + game.config.costs.roadElectricTramLane
    end
    return 1
end

local function getMultByCatenary(hasCatenary)
    if hasCatenary == 1 then
        return 1 + game.config.costs.railroadCatenary
    end
    return 1
end

local cachedCosts = {street = {}, track = {}, bridge = {}, tunnel = {}, model = {}}

--- Un-modded cost by object type.
---@param typeId number
---@param cached table
---@param repName string
---@param costMultType string
---@return number
local function getOriginalCostByType(typeId, cached, repName, costMultType)
    if cached[typeId] == nil then
        local data = api.res[repName].get(typeId)
		local constructionCost = data and (data.metadata and data.metadata.cost and data.metadata.cost.price or data.cost) or 0
		if constructionCost ~= 0 then
			constructionCost = constructionCost / config.get().costMultipliers[costMultType]
		end
        cached[typeId] = constructionCost
    end
    return cached[typeId]
end

--- Cost of model instance.
---@param modelId number Model ID.
---@param costMultType string Type of cost mult.
---@return number Money cost.
local function getModelCost(modelId, costMultType)
    return getOriginalCostByType(modelId, cachedCosts.model, "modelRep", costMultType)
end

--- Cost of street edge.
---@param street userdata
---@param len number Length in meters.
---@return number Money cost.
local function getStreetEdgeCost(street, len)
    local costPerMeter = getOriginalCostByType(street.streetType, cachedCosts.street, "streetTypeRep", "street")
    local tramMult = getMultByTramType(street.tramTrackType)
    return costPerMeter * len * tramMult
end

--- Cost of track edge.
---@param track userdata
---@param len number Length in meters.
---@return number Money cost.
local function getTrackEdgeCost(track, len)
    local costPerMeter = getOriginalCostByType(track.trackType, cachedCosts.track, "trackTypeRep", "track")
    local mult = getMultByCatenary(track.catenary and 1 or 0)
    return costPerMeter * len * mult
end

local function getHeightAt(pos2d)
	if pos2d.z ~= nil then
		pos2d = api.type.Vec2f.new(pos2d.x, pos2d.y)
	end
	return api.engine.terrain.getHeightAt(pos2d)
end

local loadedBridges = {}
local function getBridgeCostFactors(bridgeId)
	if loadedBridges[bridgeId] == nil then
		local bridgeName = api.res.bridgeTypeRep.getName(bridgeId)
		local fileName = "./res/config/bridge/" .. bridgeName
		local env = {}
		setmetatable(env, {__index=_G})
		local bridgeFunc = loadfile(fileName, "bt", env)
		if type(bridgeFunc) == "function" then
			bridgeFunc()
			if type(env.data) == "function" then
				loadedBridges[bridgeId] = env.data()
			else
				print("Incorrect bridge script: " .. fileName)
			end
		else
			print("Error loading bridge: " .. fileName)
		end
	end

	return loadedBridges[bridgeId] and loadedBridges[bridgeId].costFactors
end

local function getBridgeEdgeCostOld(edge, geometry)
    local costPerMeter = getOriginalCostByType(edge.typeIndex, cachedCosts.bridge, "bridgeTypeRep", "bridge")
	local bridgeCostFactors = getBridgeCostFactors(edge.typeIndex)
	local startPos = geometry.params.pos[1]
	local endPos = geometry.params.pos[2]
	local height1 = geometry.height.x - getHeightAt(startPos)
	local height2 = geometry.height.y - getHeightAt(endPos)
	local averageHeight = (height1 + height2) / 2

	-- This formula was deduced to approximate real costs. Actual formula may be different.
    local mult = (averageHeight / bridgeCostFactors[1]) ^ bridgeCostFactors[2]
--[[  	debugPrint("Calculating bridge section. cost=" .. costPerMeter ..
	 	", mult=(".. averageHeight .. "/" .. bridgeCostFactors[1] .. ") ^ " .. bridgeCostFactors[2] ..
		", length=" .. geometry.length ..
		", result=" .. (costPerMeter * geometry.length * mult)) ]]
    return costPerMeter * geometry.length * mult
end

local function getBridgeEdgeCost(edge, len, startPos, endPos)
    local costPerMeter = getOriginalCostByType(edge.typeIndex, cachedCosts.bridge, "bridgeTypeRep", "bridge")
	local bridgeCostFactors = getBridgeCostFactors(edge.typeIndex)
	local height1 = startPos.z - getHeightAt(startPos)
	local height2 = endPos.y - getHeightAt(endPos)
	local averageHeight = (height1 + height2) / 2

	-- This formula was deduced to approximate real costs. Actual formula may be different.
    local mult = (averageHeight / bridgeCostFactors[1]) ^ bridgeCostFactors[2]
  	debugPrint("Calculating bridge section. cost=" .. costPerMeter ..
	 	", mult=(".. averageHeight .. "/" .. bridgeCostFactors[1] .. ") ^ " .. bridgeCostFactors[2] ..
		", length=" .. len ..
		", result=" .. (costPerMeter * len * mult))
    return costPerMeter * len * mult
end

local function getTunnelEdgeCost(edge, len)
    local costPerMeter = getOriginalCostByType(edge.typeIndex, cachedCosts.tunnel, "tunnelTypeRep", "tunnel")
    return costPerMeter * len
end

local function getModelsOnEdgeCost(edge, costMultType)
	local function sumInstances(instances)
		return util.sum(instances, function(inst)
			 return getModelCost(inst.modelId, costMultType)
		end)
	end
    if edge.objects ~= nil then
		local totalCost = util.sum(edge.objects, function(obj)
			local modelEntity = obj[1]
			local instList = api.engine.getComponent(modelEntity, api.type.ComponentType.MODEL_INSTANCE_LIST)
			if instList ~= nil then
				return sumInstances(instList.thinInstances) + sumInstances(instList.fatInstances)
			else
				return 0
			end
		end)
		return totalCost, #edge.objects
	else
		return 0, 0
	end
end

local function isPlayerOwned(entityId, playerId)
	local playerOwned = api.engine.getComponent(entityId, api.type.ComponentType.PLAYER_OWNED)
	return playerOwned ~= nil and playerOwned.player == playerId
end

---@return EdgeCostsByType
function entity_util.getTotalEdgeCostsByType()
    local playerId = game.interface.getPlayer()
    local allEdges = entity_util.getAllEntitiesByType("BASE_EDGE")
	---@class EdgeCostsByType
    local result = {
		street = 0, track = 0, len = {street = 0, track = 0}, objs = {street = 0, track = 0},
		addEdge = function (self, key, cost, len, numObjs)
			debugPrint({"addEdge", key, cost, len, numObjs})
			util.incInTable(self, key, cost)
			util.incInTable(self.len, key, len)
			util.incInTable(self.objs, key, numObjs)
		end
	}
    for _, edgeId in pairs(allEdges) do
        if isPlayerOwned(edgeId, playerId) then
			local edge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
			local street = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_STREET)
			local track = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
			local node1 = api.engine.getComponent(edge.node0, api.type.ComponentType.BASE_NODE)
			local node2 = api.engine.getComponent(edge.node1, api.type.ComponentType.BASE_NODE)

			-- Assume straight lines.. might be very inaccurate for curved roads and tracks...
			local edgeLength = vector.len3d(node2.position - node1.position)
			local typeKey = nil
			local totalCost = 0
			if street ~= nil then
				typeKey = "street"
				totalCost = getStreetEdgeCost(street, edgeLength)
			elseif track ~= nil then
				typeKey = "track"
				totalCost = getTrackEdgeCost(track, edgeLength)
			end
			if typeKey ~= nil then
				local modelsCost, modelsNum = getModelsOnEdgeCost(edge, typeKey)
				totalCost = totalCost + modelsCost
				if edge.type == 1 then
					totalCost = totalCost + getBridgeEdgeCost(edge, edgeLength, node1.position, node2.position)
				elseif edge.type == 2 then
					totalCost = totalCost + getTunnelEdgeCost(edge, edgeLength)
				end
				result:addEdge(typeKey, totalCost, edgeLength, modelsNum)
			end
        end
    end
    return result
end


local cachedConstructionTypes = {}
local function getConstructionTypeByFileName(fileName)
    if cachedConstructionTypes[fileName] == nil then
		local index = api.res.constructionRep.find(fileName)
		if index ~= -1 then
			local config = api.res.constructionRep.get(index)
			cachedConstructionTypes[fileName] = config and config.type or false
		else
			cachedConstructionTypes[fileName] = false
		end
    end
    return cachedConstructionTypes[fileName]
end

--[[ {
    AIRPORT = 2,
    AIRPORT_CARGO = 16,
    ASSET_DEFAULT = 11,
    ASSET_TRACK = 12,
    HARBOR = 3,
    HARBOR_CARGO = 6,
    INDUSTRY = 10,
    NONE = 15,
    RAIL_DEPOT = 8,
    RAIL_STATION = 1,
    RAIL_STATION_CARGO = 5,
    STREET_CONSTRUCTION = 14,
    STREET_DEPOT = 7,
    STREET_STATION = 0,
    STREET_STATION_CARGO = 4,
    TOWN_BUILDING = 13,
    WATER_DEPOT = 9,
  } ]]

local typeByConstructionType = nil
---
---@param construction userdata
---@return string
local function getTypeByConstruction(construction)
	if typeByConstructionType == nil then
		local ConTypeEnum = api.type.enum.ConstructionType
		typeByConstructionType = {
			[ConTypeEnum.AIRPORT] = "air",
			[ConTypeEnum.AIRPORT_CARGO] = "air",

			[ConTypeEnum.HARBOR] = "water",
			[ConTypeEnum.HARBOR_CARGO] = "water",

			[ConTypeEnum.RAIL_DEPOT] = "rail",
			[ConTypeEnum.RAIL_STATION] = "rail",
			[ConTypeEnum.RAIL_STATION_CARGO] = "rail",

			[ConTypeEnum.STREET_CONSTRUCTION] = "street",
			[ConTypeEnum.STREET_DEPOT] = "street",
			[ConTypeEnum.STREET_STATION] = "street",
			[ConTypeEnum.STREET_STATION_CARGO] = "street",
		}
	end
	return typeByConstructionType[getConstructionTypeByFileName(construction.fileName)]
end

---@return ConstructionMaintenanceByType
function entity_util.getTotalConstructionMaintenanceByType()
	local allConstructions = entity_util.getAllEntitiesByType("CONSTRUCTION")
	---@class ConstructionMaintenanceByType
	local result = {street = 0, rail = 0, water = 0, air = 0, num = {}}
    for _, id in pairs(allConstructions) do
		if isPlayerOwned(id) then
			local construction = api.engine.getComponent(id, api.type.ComponentType.CONSTRUCTION)
			local maintenanceCost = api.engine.getComponent(id, api.type.ComponentType.MAINTENANCE_COST)
			if construction ~= nil and maintenanceCost ~= nil then
				local typeName = getTypeByConstruction(construction)
				if typeName ~= nil then
					util.incInTable(result, typeName, maintenanceCost.maintenanceCost)
					util.incInTable(result.num, typeName, 1)
				end
			end
		end
	end
	return result
end

return entity_util