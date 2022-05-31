--[[
Entity info gathering utilities.
Version: 1.2

Copyright (c)  2022  phobos2077  (https://steamcommunity.com/id/phobos2077)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including the right to distribute and without limitation the rights to use, copy and/or modify
the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.
--]]

local table_util = require "costly_infrastructure_v2/lib/table_util"
local entity_util = require "costly_infrastructure_v2/lib/entity_util"
local log_util = require "costly_infrastructure_v2/lib/log_util"
local entity_info = require "costly_infrastructure_v2/entity_info"
local enum = require "costly_infrastructure_v2/enum"

local entity_costs = {}

--- Gets all entities on the map with a given type.
---@param type string Entitiy type.
---@return table A list of entities.
function entity_costs.getAllEntitiesByType(type)
    return game.interface.getEntities({radius = 1e10}, {type = type})
end

local Category = enum.Category

local function getStreetEdgeMult(tramTrackType, hasBus)
	local result = 1
    if tramTrackType == 1 then
        result = result + game.config.costs.roadTramLane
	elseif tramTrackType == 2 then
        result = result + game.config.costs.roadElectricTramLane
    end
	if hasBus then
		result = result + game.config.costs.roadBusLane
	end
    return result
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
---@return number
local function getCostByType(typeId, cached, repName)
    if cached[typeId] == nil then
        local data = api.res[repName].get(typeId)
		local constructionCost = data and (data.metadata and data.metadata.cost and data.metadata.cost.price or data.cost) or 0
        cached[typeId] = constructionCost
    end
    return cached[typeId]
end

--- Cost of model instance.
---@param modelId number Model ID.
---@return number Money cost.
local function getModelCost(modelId)
    return getCostByType(modelId, cachedCosts.model, "modelRep")
end

--- Cost of street edge.
---@param street userdata
---@param len number Length in meters.
---@return number Money cost.
local function getStreetEdgeCost(street, len)
    local costPerMeter = getCostByType(street.streetType, cachedCosts.street, "streetTypeRep")
    local tramMult = getStreetEdgeMult(street.tramTrackType, street.hasBus)
    return costPerMeter * len * tramMult
end

--- Cost of track edge.
---@param track userdata
---@param len number Length in meters.
---@return number Money cost.
local function getTrackEdgeCost(track, len)
    local costPerMeter = getCostByType(track.trackType, cachedCosts.track, "trackTypeRep")
    local mult = getMultByCatenary(track.catenary and 1 or 0)
    return costPerMeter * len * mult
end

local function getTerrainHeightAt(pos2d)
	return api.engine.terrain.getHeightAt(pos2d)
end

local cachedCostFactors = {}
local function getBridgeCostFactors(bridgeId)
	if cachedCostFactors[bridgeId] == nil then
		local data = api.res.bridgeTypeRep.get(bridgeId)
		cachedCostFactors[bridgeId] = data and data.costFactors and data.costFactors[1] > 0 and data.costFactors[2] > 0 and {data.costFactors[1], data.costFactors[2]} or false
		if cachedCostFactors[bridgeId] == false then
			print("Bad cost factors for bridge ID = " .. bridgeId)
		end
	end
	return cachedCostFactors[bridgeId]
end

local function getBridgeEdgeCost(edge, geometry)
    local costPerMeter = getCostByType(edge.typeIndex, cachedCosts.bridge, "bridgeTypeRep")
	local bridgeCostFactors = getBridgeCostFactors(edge.typeIndex)
	if costPerMeter > 0 then
		local mult = 1
		if bridgeCostFactors then
			local startPos = geometry.params.pos[1]
			local endPos = geometry.params.pos[2]
			local height1 = geometry.height.x - getTerrainHeightAt(startPos)
			local height2 = geometry.height.y - getTerrainHeightAt(endPos)
			local averageHeight = (height1 + height2) / 2
			if averageHeight > 0 then
				-- This formula was deduced to approximate real costs. Actual formula may be different.
				mult = math.max((averageHeight / bridgeCostFactors[1]) ^ bridgeCostFactors[2], 1)
			end

			--[[debugPrint("Calculating bridge section. cost=" .. costPerMeter ..
			", mult=(".. averageHeight .. "/" .. bridgeCostFactors[1] .. ") ^ " .. bridgeCostFactors[2] ..
			", length=" .. geometry.length ..
			", result=" .. (costPerMeter * geometry.length * mult))]]
		end
		return costPerMeter * geometry.length * mult
	else
		return 0
	end
end

local function getTunnelEdgeCost(edge, len)
    local costPerMeter = getCostByType(edge.typeIndex, cachedCosts.tunnel, "tunnelTypeRep")
    return costPerMeter * len
end

local function getModelsOnEdgeCost(edge)
	local function sumInstances(instances)
		return table_util.sum(instances, function(inst)
			 return getModelCost(inst.modelId)
		end)
	end
    if edge.objects ~= nil then
		local totalCost = table_util.sum(edge.objects, function(obj)
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


-- We need to find one path of TN edges that connects the actual nodes.
-- More than one path occurs e.g. for roads (one per lane + one per sidewalk).
-- Signals and waypoints split the segment into more TN edges.
local function findUniqueTNPath(tnEdges, edge)
	local tnPath = {}
	local lastEdgeId
	for _, tnEdge in pairs(tnEdges) do
		-- Modes 1 and 2 are people and cargo - it's used for sidewalks, we should skip it.
		if tnEdge.transportModes[1] == 0 and tnEdge.transportModes[2] == 0 and (lastEdgeId == nil or tnEdge.conns[1] == lastEdgeId) then
			table.insert(tnPath, tnEdge)
			lastEdgeId = tnEdge.conns[2]
		end
	end
	-- Validate path
	local pathStart = tnPath[1].conns[1].entity
	local pathEnd = tnPath[#tnPath].conns[2].entity
	if not (pathStart == edge.node0 and pathEnd == edge.node1) and not (pathStart == edge.node1 and pathEnd == edge.node0) then
		log_util.logError("Incorrect path! Start/end is "..pathStart.."/"..pathEnd..", but should be "..edge.node0.."/"..edge.node1)
	end
	return tnPath
end

local Timer = {}
function Timer.new()
	local o = {t = 0, e = 0}
	setmetatable(o, {__index = Timer})
	return o
end

function Timer:start()
	self.t = os.clock()
end

function Timer:stop()
	self.e = self.e + os.clock() - self.t
end

function Timer:elapsedMs()
	return self.e * 1000
end

---@return table<string, EdgeCostData>
function entity_costs.getTotalEdgeCostsByCategory()
    local playerId = game.interface.getPlayer()

	local function newEdgeCosts()
		---@class EdgeCostData
		local d = {
			edge = 0,
			bridge = 0,
			tunnel = 0,
			objects = 0, -- object costs are included in edge costs
			len = {
				edge = 0,
				bridge = 0,  -- edge length include bridge and tunnel lengths
				tunnel = 0,
			},
			numObjs = 0
		}
		return d
	end
	
    local result = {
		[Category.STREET] = newEdgeCosts(),
		[Category.RAIL] = newEdgeCosts()
	}
	local timers = {"gcStreet", "gcTrack", "gcNetwork", "uniqPath", "costStreet", "costTrack", "costModels", "costBridge", "costTunnel"}
	timers = table_util.mapDict(timers, function(name) return name, Timer.new() end)
	api.engine.forEachEntityWithComponent(function(edgeId, edge)
        if entity_util.isPlayerOwned(edgeId, playerId) then
			timers.gcStreet:start()
			local street = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_STREET)
			timers.gcStreet:stop()
			timers.gcTrack:start()
			local track = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
			timers.gcTrack:stop()
			timers.gcNetwork:start()
			local network = api.engine.getComponent(edgeId, api.type.ComponentType.TRANSPORT_NETWORK)
			timers.gcNetwork:stop()
			timers.uniqPath:start()
			local uniqTNPath = findUniqueTNPath(network.edges, edge)
			timers.uniqPath:stop()
			local lengthByTN = table_util.sum(uniqTNPath, function(e) return e.geometry.length end)
			local category = nil
			local edgeCost = 0
			if street ~= nil then
				category = Category.STREET
				timers.costStreet:start()
				edgeCost = getStreetEdgeCost(street, lengthByTN)
				timers.costStreet:stop()
			elseif track ~= nil then
				category = Category.RAIL
				timers.costTrack:start()
				edgeCost = getTrackEdgeCost(track, lengthByTN)
				timers.costTrack:stop()
			end
			if category ~= nil then
				local subResult = result[category]
				timers.costModels:start()
				local modelsCost, modelsNum = getModelsOnEdgeCost(edge)
				timers.costModels:stop()
				table_util.incInTable(subResult, "edge", edgeCost + modelsCost)
				table_util.incInTable(subResult.len, "edge", lengthByTN)

				table_util.incInTable(subResult, "objects", modelsCost)
				table_util.incInTable(subResult, "numObjs", modelsNum)
				if edge.type == 1 then
					timers.costBridge:start()
					local bridgeCost = table_util.sum(uniqTNPath, function(e) return getBridgeEdgeCost(edge, e.geometry) end)
					timers.costBridge:stop()
					table_util.incInTable(subResult, "bridge", bridgeCost)
					table_util.incInTable(subResult.len, "bridge", lengthByTN)
				elseif edge.type == 2 then
					timers.costTunnel:start()
					local tunnelCost = getTunnelEdgeCost(edge, lengthByTN)
					timers.costTunnel:stop()
					table_util.incInTable(subResult, "tunnel", tunnelCost)
					table_util.incInTable(subResult.len, "tunnel", lengthByTN)
				end
			end
        end
    end, api.type.ComponentType.BASE_EDGE)

	result._times = table_util.map(timers, Timer.elapsedMs)
    return result
end

---@return ConstructionMaintenanceByCategory
function entity_costs.getTotalConstructionMaintenanceByCategory()
	local playerId = game.interface.getPlayer()
	---@class ConstructionMaintenanceByCategory
	local result = {
		[Category.STREET] = 0,
		[Category.RAIL] = 0,
		[Category.WATER] = 0,
		[Category.AIR] = 0,
		num = {}
	}
	api.engine.system.streetConnectorSystem.forEach(function(id, construction)
		if #construction.townBuildings == 0 and entity_util.isPlayerOwned(id, playerId) then
			local maintenanceCost = api.engine.getComponent(id, api.type.ComponentType.MAINTENANCE_COST)
			if maintenanceCost ~= nil then
				local category = entity_info.getCategoryByConstructionFileName(construction.fileName)
				if category ~= nil then
					table_util.incInTable(result, category, maintenanceCost.maintenanceCost)
					table_util.incInTable(result.num, category, 1)
				end
			end
		end
	end)
    --[[
	local allConstructions = entity_util.findAllEntitiesOfType("CONSTRUCTION")
	for _, id in pairs(allConstructions) do
		if entity_util.isPlayerOwned(id, playerId) then
			local construction = api.engine.getComponent(id, api.type.ComponentType.CONSTRUCTION)
			
		end
	end]]
	return result
end

return entity_costs