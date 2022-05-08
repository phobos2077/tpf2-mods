local game_enum = require "autorename/lib/game_enum"
local table_util = require "autorename/lib/table_util"
local log_util = require "autorename/lib/log_util"
local entity_util = require "autorename/lib/entity_util"

local Pattern = (require "autorename/enum").Pattern

local rename = {}

local Carrier = game_enum.Carrier

---@type table<number, string|function>
local carrierToTypeStr = {
	[Carrier.ROAD] = function(vehicle)
		return vehicle.config.allCaps[1] > 0 and _("veh_type_bus") or _("veh_type_truck")
	end,
	[Carrier.RAIL] = _("Train"),
	[Carrier.TRAM] = _("Tram"),
	[Carrier.AIR] = _("Plane"),
	[Carrier.WATER] = _("Ship")
}

local function getVehicleTypeStr(vehicle)
	local typeStr = carrierToTypeStr[vehicle.carrier]
	if type(typeStr) == "function" then
		typeStr = typeStr(vehicle)
	end
	return typeStr
end

local function escape(str)
	local res = str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
	return res
end

local function commandCallback(cmd, success)
	if not success then
		debugPrint({commandFailed = cmd})
	end
end

local function getBaseNameByPattern(vehiclePattern, lineName, vehicle)
	if vehiclePattern == Pattern.LineTypeNumber then
		local typeStr = getVehicleTypeStr(vehicle)
		return lineName.." "..typeStr
	elseif vehiclePattern == Pattern.LineNumber then
		return lineName
	else
		log_util.logError("Unsupported vehicle pattern: " .. vehiclePattern)
		return lineName
	end
end

-- Remember last names of lines to save on unnecessary processing.
---@type table<number, {name: string, vehs: table<number, boolean>, maxIdPerName: table<string, number>}>
local renameCache = {
}

local function renameAllVehiclesOnLine(vehiclePattern, lineId, lineName)
	local cachedLineInfo = renameCache[lineId] or {}
	renameCache[lineId] = cachedLineInfo
	local lineNameChanged = lineName ~= cachedLineInfo.name
	local lastVehicles = cachedLineInfo.vehs or {}
	cachedLineInfo.name = lineName
	cachedLineInfo.vehs = {}
	cachedLineInfo.maxIdPerName = cachedLineInfo.maxIdPerName or {}

	local vehIds = api.engine.system.transportVehicleSystem.getLineVehicles(lineId)
	local maxIdPerName = cachedLineInfo.maxIdPerName
	local vehiclesPerName = {}
	local numRenamed = 0

	-- First pass - calculate max numbers and prepare list of vehicles to rename.
	for _, vehId in ipairs(vehIds) do
		cachedLineInfo.vehs[vehId] = true
		-- Skip vehicle processing if we know for sure we processed it already with the same line name.
		if lineNameChanged or not lastVehicles[vehId] then
			local vehicle = api.engine.getComponent(vehId, api.type.ComponentType.TRANSPORT_VEHICLE)
			local curName = api.engine.getComponent(vehId, api.type.ComponentType.NAME).name

			-- If vehicle doesn't match naming pattern - means player set a custom name, so keep it.
			if string.match(curName, "%d+$") then
				local baseName = getBaseNameByPattern(vehiclePattern, lineName, vehicle)
				local num = string.match(curName, "^"..escape(baseName).." (%d+)")
				num = num and tonumber(num)
				-- debugPrint({num = num == nil and "nil" or num, baseName = baseName, maxId = maxIdPerName[baseName] or "nil"})
				if not num then
					-- Not matched the expected pattern, need to rename it.
					if vehiclesPerName[baseName] == nil then
						vehiclesPerName[baseName] = {}
					end
					table.insert(vehiclesPerName[baseName], vehId)
				elseif maxIdPerName[baseName] == nil or num > maxIdPerName[baseName] then
					-- Vehicle already has proper name, don't rename but check for max number.
					maxIdPerName[baseName] = num
				end
			end
		end
	end
	-- Second pass - rename.
	for baseName, idsToRename in pairs(vehiclesPerName) do
		for _, vehId in ipairs(idsToRename) do
			local maxId = (maxIdPerName[baseName] or 0) + 1
			local newName = baseName .. " " .. maxId
			maxIdPerName[baseName] = maxId

			api.cmd.sendCommand(api.cmd.make.setName(vehId, newName), commandCallback)
			numRenamed = numRenamed + 1
		end
	end
	return numRenamed
end

function rename.renameAllVehicles(vehiclePattern)
	local timer = os.clock()
	local lineIds = api.engine.system.lineSystem.getLinesForPlayer(game.interface.getPlayer())
	local numRenamed = 0
	for _, lineId in pairs(lineIds) do
		local lineName = api.engine.getComponent(lineId, api.type.ComponentType.NAME).name

		-- If line name follows default pattern, means player doesn't care about it so don't rename vehicles here.
		if not string.find(lineName, "^"..escape(_("Line")).." %d+$") then
			numRenamed = numRenamed + renameAllVehiclesOnLine(vehiclePattern, lineId, lineName)
		end
	end
	
	local elapsed = os.clock() - timer
	log_util.log(string.format("Renamed %d vehicles across %d lines in %.0f ms.", numRenamed, #lineIds, elapsed * 1000))
end



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


function rename.renameAllIndustryStations()
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
	log_util.log(string.format("Renamed %d stations in %.0f ms.", numRenamed, elapsed * 1000))
end


return rename