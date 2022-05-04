local table_util = require "lib/table_util"
local entity_util = require "lib/entity_util"
local entity_info = require "costly_infrastructure/entity_info"
local Category = (require "costly_infrastructure/enum").Category

local station_stats = {}


local cargoAtTerminalSystem
local personAtTerminalSystem
local personSystem
local numCargoTypes

local function getCargoEdgeCapacity(edgeId)
	numCargoTypes = numCargoTypes or #api.res.cargoTypeRep.getAll()
	for i = 0, numCargoTypes - 1 do
		cargoAtTerminalSystem = cargoAtTerminalSystem or api.engine.system.simCargoAtTerminalSystem
		local maxCount = cargoAtTerminalSystem.getMaxCount(edgeId, i)
		if maxCount > 0 then
			return maxCount
		end
	end
	return 0
end

local function getPersonEdgeCapacity(edgeId)
	personAtTerminalSystem = personAtTerminalSystem or api.engine.system.simPersonAtTerminalSystem
	personSystem = personSystem or api.engine.system.simPersonSystem
	local numPersons = #personSystem.getSimPersonsAtTerminalForTransportNetwork(edgeId.entity)
	return personAtTerminalSystem.getNumFreePlaces(edgeId) + numPersons
end

local function getTotalStationCapacity(stationId)
    local station = api.engine.getComponent(stationId, api.type.ComponentType.STATION)
	if not station.terminals or #station.terminals == 0 then
		return 0
	end
	-- Assume station can have nodes&edges only within one entity.
	-- First gather all edges related to this tation.
	
	local tns = {}
	local function getTn(entityId)
		local tn = tns[entityId]
		if tn == nil then
			tn = api.engine.getComponent(entityId, api.type.ComponentType.TRANSPORT_NETWORK)
			tns[entityId] = tn
		end
		return tn
	end
	local stationEdgeIds = {}
	for _, terminal in pairs(station.terminals) do
		if #terminal.personEdges > 0 then
			table_util.iinsert(stationEdgeIds, terminal.personEdges)
		elseif #terminal.personNodes > 0 then
			-- Have to manually find edgeIds.
			local nodeIdsByEntity = table_util.groupBy(terminal.personNodes, function(nodeId) return nodeId.entity end)
			for entity, nodeIds in pairs(nodeIdsByEntity) do
				local tn = getTn(entity)
				-- Edges connected to station node are taken.
				for i, edge in ipairs(tn.edges) do
					for _, nodeId in pairs(nodeIds) do
						if edge.conns[1] == nodeId or edge.conns[2] == nodeId then
							table.insert(stationEdgeIds, api.type.EdgeId.new(nodeId.entity, i - 1))
							break
						end
					end
				end
			end
		end
	end
	if #stationEdgeIds == 0 then return 0 end

	local stationInfo = game.interface.getEntity(stationId)
	local category = stationInfo.carriers and entity_info.getCategoryByCarriers(stationInfo.carriers)
	return table_util.sum(stationEdgeIds, function(edgeId)
		return station.cargo
			and getCargoEdgeCapacity(edgeId)
			or getPersonEdgeCapacity(edgeId)
	end), category
end

function station_stats.getPlayerOwnedConstructions()
    local player = game.interface.getPlayer()
    local allConstructions = entity_util.findAllEntitiesOfType("CONSTRUCTION")
    local result = table_util.mapDict(Category, function(cat) return cat, {} end)
    for _, constructionId in pairs(allConstructions) do
        local construction = api.engine.getComponent(constructionId, api.type.ComponentType.CONSTRUCTION)
        if construction ~= nil and entity_util.isPlayerOwned(constructionId, player) then
            local category = entity_info.getCategoryByConstructionFileName(construction.fileName)
            if category then
                table.insert(result[category], constructionId)
            end
        end
    end
    return result
end

function station_stats.getTotalCapacityOfAllStationsByCategory()
    local player = game.interface.getPlayer()
    local allStations = entity_util.findAllEntitiesOfType("STATION")
    local result = table_util.mapDict(Category, function(cat) return cat, 0 end)

    for _, stationId in pairs(allStations) do
		if entity_util.isPlayerOwned(stationId, player) then
			local capacity, category = getTotalStationCapacity(stationId)
			if category and capacity then
				result[category] = result[category] + capacity
			end
		end
    end
    return result
end

station_stats.getTotalStationCapacity = getTotalStationCapacity

return station_stats