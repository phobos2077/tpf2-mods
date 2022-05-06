local table_util = require "costly_infrastructure_v2/lib/table_util"
local entity_util = require "costly_infrastructure_v2/lib/entity_util"
local entity_info = require "costly_infrastructure_v2/entity_info"
local Category = (require "costly_infrastructure_v2/enum").Category

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

local function getPersonEdgeFreePlaces(edgeId)
	personAtTerminalSystem = personAtTerminalSystem or api.engine.system.simPersonAtTerminalSystem
	return personAtTerminalSystem.getNumFreePlaces(edgeId)
end

local function getStationTerminalsCapacity(station, tnEntity)
	local stationEdgeIds = {}
	local nodeIdsToCheck = {}
	for _, terminal in pairs(station.terminals) do
		if #terminal.personEdges > 0 then
			table_util.iinsert(stationEdgeIds, terminal.personEdges)
		elseif #terminal.personNodes > 0 then
			table_util.iinsert(nodeIdsToCheck, terminal.personNodes)
		end
	end

	if tnEntity and #nodeIdsToCheck > 0 then
		-- Assume a terminal can have nodes&edges only within one entity.
		-- Have to manually find edgeIds.
		local tn = api.engine.getComponent(tnEntity, api.type.ComponentType.TRANSPORT_NETWORK)
		-- Edges connected to station node are taken.
		for i, edge in ipairs(tn.edges) do
			for _, nodeId in pairs(nodeIdsToCheck) do
				if edge.conns[1] == nodeId or edge.conns[2] == nodeId then
					table.insert(stationEdgeIds, api.type.EdgeId.new(nodeId.entity, i - 1))
					break
				end
			end
		end
	end

	if station.cargo then
		return table_util.sum(stationEdgeIds, getCargoEdgeCapacity)
	else
		return table_util.sum(stationEdgeIds, getPersonEdgeFreePlaces)
	end
end

local function getTotalStationCapacityOnEntity(stations, tnEntity)
	local total = 0
	local hasPassengerStation = false
	for _, station in pairs(stations) do
		if station and station.terminals and #station.terminals > 0 then
			local terminalsCapacity = getStationTerminalsCapacity(station, tnEntity)
			local moreCapacity = (station.pool and station.pool.moreCapacity or 0)
			total = total + terminalsCapacity + moreCapacity
			if not station.cargo then
				hasPassengerStation = true
			end
		end
	end

	if hasPassengerStation then
		personSystem = personSystem or api.engine.system.simPersonSystem
		local numPersons = #personSystem.getSimPersonsAtTerminalForTransportNetwork(tnEntity)
		total = total + numPersons
	end
	return total
end

local function getStationTnEntity(station)
	local term = station.terminals[1]
	return term.personEdges[1] and term.personEdges[1].entity or term.personNodes[1].entity
end

function station_stats.getTotalCapacityOfAllStationsByCategory()
    local player = game.interface.getPlayer()
    local result = table_util.mapDict(Category, function(cat) return cat, 0 end)

	local allStations = entity_util.findAllEntitiesOfType("STATION")

	local stationsByTnEntity = {}
	for _, stationId in pairs(allStations) do
		if entity_util.isPlayerOwned(stationId, player) then
			local station = api.engine.getComponent(stationId, api.type.ComponentType.STATION)
			local tnEntity = getStationTnEntity(station)
			if stationsByTnEntity[tnEntity] == nil then
				stationsByTnEntity[tnEntity] = {{}, stationId}
			end
			table.insert(stationsByTnEntity[tnEntity][1], station)
		end
	end
	for tnEntity, data in pairs(stationsByTnEntity) do
		local stations, firstStationId = table.unpack(data)
		local stationInfo = game.interface.getEntity(firstStationId)
		local category = stationInfo.carriers and entity_info.getCategoryByCarriers(stationInfo.carriers)
		if category then
			result[category] = result[category] + getTotalStationCapacityOnEntity(stations, tnEntity)
		end
	end
    return result
end

function station_stats.getTotalStationCapacity(stationId)
	local station = api.engine.getComponent(stationId, api.type.ComponentType.STATION)
	local tnEntity = getStationTnEntity(station)
	local construction = api.engine.getComponent(tnEntity, api.type.ComponentType.CONSTRUCTION)
	local stationsOnEntity
	if construction ~= nil then
		stationsOnEntity = table_util.map(construction.stations, function(id)
			return api.engine.getComponent(id, api.type.ComponentType.STATION)
		end)
	else
		local edge = api.engine.getComponent(tnEntity, api.type.ComponentType.BASE_EDGE)
		if edge ~= nil then
			stationsOnEntity = table_util.map(edge.objects, function(obj)
				return api.engine.getComponent(obj[1], api.type.ComponentType.STATION)
			end)
		else
			print("! ERROR ! Unknown type of station parent entity: " .. tnEntity)
		end
	end
	if stationsOnEntity ~= nil then
		return getTotalStationCapacityOnEntity(stationsOnEntity, tnEntity)
	else
		return 0
	end
end

return station_stats