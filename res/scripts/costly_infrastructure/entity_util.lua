local util = require 'costly_infrastructure/util'

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

-- Since API doesn't expose actual costFactors let's use a reasonable default.
local bridgeCostFactors = {10, 2, 1}

local cachedCosts = {street = {}, track = {}, bridge = {}, tunnel = {}}

local function getCostByType(typeId, cached, repName)
    if cached[typeId] == nil then
        local config = api.res[repName].get(typeId)
        cached[typeId] = config and config.cost or 0
    end
    return cached[typeId]
end

--- Cost of street edge.
---@param street userdata
---@param len number Length in meters.
---@return number Money cost.
local function getStreetEdgeCost(street, len)
    local costPerMeter = getCostByType(street.streetType, cachedCosts.street, "streetTypeRep")
    local tramMult = getMultByTramType(street.tramTrackType)
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

local function getBridgeEdgeCost(edge, geometry)
    local costPerMeter = getCostByType(edge.typeIndex, cachedCosts.bridge, "bridgeTypeRep")
	local averageHeight = (geometry.height.x + geometry.height.y) / 2

	-- This formula was deduced to approximate real costs. Actual formula may be different.
    local mult = (averageHeight / bridgeCostFactors[1]) ^ bridgeCostFactors[2]
--[[ 	debugPrint("Calculating bridge section. cost=" .. costPerMeter ..
		", height=" .. averageHeight ..
		", length=" .. geometry.length ..
		", result=" .. (costPerMeter * geometry.length * mult)) ]]
    return costPerMeter * geometry.length * mult
end

local function getTunnelEdgeCost(edge, len)
    local costPerMeter = getCostByType(edge.typeIndex, cachedCosts.tunnel, "tunnelTypeRep")
    return costPerMeter * len
end

local function getBridgeOrTunnelEdgeCost(edge, geometry)
    if edge.type == 1 then
		return getBridgeEdgeCost(edge, geometry)
	elseif edge.type == 2 then
		return getTunnelEdgeCost(edge, geometry.length)
    end
    return 0
end

local function isPlayerOwned(entityId)
	local playerOwned = api.engine.getComponent(entityId, api.type.ComponentType.PLAYER_OWNED)
	return playerOwned ~= nil and playerOwned.player == game.interface.getPlayer()
end

function entity_util.getTotalEdgeCostsByType()
    local playerId = game.interface.getPlayer()
    local allEdges = entity_util.getAllEntitiesByType("BASE_EDGE")
    local result = {street = 0, track = 0}
    for _, edgeId in pairs(allEdges) do
        if isPlayerOwned(edgeId) then
            local network = api.engine.getComponent(edgeId, api.type.ComponentType.TRANSPORT_NETWORK)
            if network ~= nil and network.edges ~= nil and network.edges[1] ~= nil then
				local geometry = network.edges[1].geometry
                local len = geometry.length
                local street = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_STREET)
                local edge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                if street ~= nil then
                    util.incInTable(result, "street", getStreetEdgeCost(street, len) + getBridgeOrTunnelEdgeCost(edge, geometry))
                else
                    local track = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
                    if track ~= nil then
                        util.incInTable(result, "track", getTrackEdgeCost(track, len) + getBridgeOrTunnelEdgeCost(edge, geometry))
                    end
                end
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
			cachedConstructionTypes[fileName] = config and config.type or ConTypeEnum.NONE
		else
			cachedConstructionTypes[fileName] = ConTypeEnum.NONE
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

function entity_util.getTotalConstructionMaintenanceByType()
	
	local allConstructions = entity_util.getAllEntitiesByType("CONSTRUCTION")
	local result = {street = 0, rail = 0, water = 0, air = 0}
    for _, id in pairs(allConstructions) do
		if isPlayerOwned(id) then
			local construction = api.engine.getComponent(id, api.type.ComponentType.CONSTRUCTION)
			local maintenanceCost = api.engine.getComponent(id, api.type.ComponentType.MAINTENANCE_COST)
			if construction ~= nil and maintenanceCost ~= nil then
				local typeName = getTypeByConstruction(construction)
				if typeName ~= nil then
					util.incInTable(result, typeName, maintenanceCost.maintenanceCost)
				end
			end
		end
	end
	return result
end

return entity_util