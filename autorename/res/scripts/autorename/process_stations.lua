local process_stations = {}


local function renameStationGroup(groupId, stationIds)
	local curName = api.engine.getComponent(groupId, api.type.ComponentType.NAME).name
	local newName = "WTF"
	api.cmd.sendCommand(api.cmd.make.setName(groupId, newName), commandCallback)
	log_util.log(string.format("Renamed Station %s to %s.", curName, newName))	
	return true
end

local function groupStationIds(stationIds)
	return table_util.igroupBy(stationIds, function(stationId)
		return api.engine.system.stationGroupSystem.getStationGroup(stationId)
	end)
end



function rename.renameStationConstruction(constrId)
	local constr = api.engine.getComponent(constrId, api.type.ComponentType.CONSTRUCTION)
	local stationGroups = groupStationIds(constr.stations)
	local numRenamed = 0
	for groupId, _ in pairs(stationGroups) do
		if renameStationGroup(groupId) then
			numRenamed = numRenamed + 1
		end
	end
	return numRenamed
end

local function getStationsConnectedToIndustry(industryConstrId)
	-- TODO: need to test if this always the case that 0 index is correct one. Couldn't find any proper way.
	local industryEdgeId = api.type.EdgeId.new(industryConstrId, 0)
 	return api.engine.system.catchmentAreaSystem.getEdge2stationsMap()[industryEdgeId]
end


-- TODO:
function rename.renameStations()
	local timer = os.clock()
	local playerId = game.interface.getPlayer()
	local numRenamed = 0

	-- local playerStationIds = table_util.filter(game.interface.getStations(), function(id)
	-- 	return entity_util.isPlayerOwned(id, playerId)
	-- end)
	-- local groupToStations = groupStationIds(playerStationIds)
	-- local numRenamed = 0
	-- for groupId, stationIds in pairs(groupToStations) do
	-- 	if renameStationGroup(groupId, stationIds) then
	-- 		numRenamed = numRenamed + 1
	-- 	end
	-- end

	local simBuildingIds = entity_util.findAllEntitiesOfType("SIM_BUILDING")
	local industryToSimBuildings = table_util.igroupBy(simBuildingIds, function(simBuildingId)
		---@type number
		local res = api.engine.system.streetConnectorSystem.getConstructionEntityForSimBuilding(simBuildingId)
		return res
	end)
	for industryConstrId, simBuildingIds in pairs(industryToSimBuildings) do
		local industryName = api.engine.getComponent(industryConstrId, api.type.ComponentType.NAME).name
		local stationIds = getStationsConnectedToIndustry(industryConstrId)
		if stationIds ~= nil then
			stationIds = table_util.filter(stationIds, function(id)
				return entity_util.isPlayerOwned(id, playerId)
			end)
			local groupToStations = groupStationIds(stationIds)
			debugPrint(groupToStations)
			for groupId, stationIds in pairs(groupToStations) do
				local curName = api.engine.getComponent(groupId, api.type.ComponentType.NAME).name
				local newName = industryName
				api.cmd.sendCommand(api.cmd.make.setName(groupId, newName), commandCallback)
				log_util.log(string.format("Renamed Station %s to %s.", curName, newName))
				numRenamed = numRenamed + 1
			end
		end
	end

	local elapsed = os.clock() - timer
	log_util.log(string.format("Renamed %d stations in %.0f ms.", numRenamed, elapsed * 1000), LOG_TAG)
end


return process_stations