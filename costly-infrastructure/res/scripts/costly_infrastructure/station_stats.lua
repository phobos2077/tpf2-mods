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

local function getTotalStationCapacityAtConstruction(construction)
    return table_util.sum(construction.stations, function(stationId)
        local station = api.engine.getComponent(stationId, api.type.ComponentType.STATION)
        local terminalCapacity = table_util.sum(station.terminals, function(terminal)
            return table_util.sum(terminal.personEdges, function(edgeId)
				return station.cargo
					and getCargoEdgeCapacity(edgeId)
					or getPersonEdgeCapacity(edgeId)
            end)
        end)
        return terminalCapacity + station.pool.moreCapacity
    end)
end

function station_stats.getTotalStationCapacityTest(id)
    local construction = api.engine.getComponent(id, api.type.ComponentType.CONSTRUCTION)
    return getTotalStationCapacityAtConstruction(construction)
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
    local allConstructions = entity_util.findAllEntitiesOfType("CONSTRUCTION")
    local result = table_util.mapDict(Category, function(cat) return cat, 0 end)
    for _, constructionId in pairs(allConstructions) do
        local construction = api.engine.getComponent(constructionId, api.type.ComponentType.CONSTRUCTION)
        if construction ~= nil and #construction.stations > 0 and entity_util.isPlayerOwned(constructionId, player) then
            local category = entity_info.getCategoryByConstructionFileName(construction.fileName)
            if category then
                result[category] = result[category] + getTotalStationCapacityAtConstruction(construction, constructionId)
            end
        end
    end
    return result
end


return station_stats