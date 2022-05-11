local game_enum = require "autorename/lib/game_enum"
local table_util = require "autorename/lib/table_util"
local log_util = require "autorename/lib/log_util"
local entity_util = require "autorename/lib/entity_util"

local rename = {}

local Carrier = game_enum.Carrier
local LOG_TAG = "Auto-Rename"

---@type table<number, string|function>
local carrierToTypeStr = {
	[Carrier.ROAD] = function(vehicle)
		return vehicle.config.allCaps[1] > 0 and _("Bus") or _("Truck")
	end,
	[Carrier.RAIL] = _("Train"),
	[Carrier.TRAM] = _("Tram"),
	[Carrier.AIR] = _("Plane"),
	[Carrier.WATER] = _("Ship")
}

---@param vehicle userdata
---@return string
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

---@param sourceName string
---@param filterParams NameFilteringParams
---@return string
local function filterSourceName(sourceName, filterParams)
	-- Remove stuff in various types of brackets.
	local skipBrackets = filterParams.skipBrackets
	if skipBrackets.square then
		sourceName = sourceName:gsub("%s?%b[]", "")
	end
	if skipBrackets.curly then
		sourceName = sourceName:gsub("%s?%b{}", "")
	end
	if skipBrackets.angled then
		sourceName = sourceName:gsub("%s?%b<>", "")
	end
	return sourceName
end

local BASE_NUM_PATTERN = "%s+#?(%d+)$"

---@param lineName string
---@param vehicle userdata
---@param renameConfig VehicleRenameConfig
---@return string name
local function getVehicleBaseName(lineName, vehicle, renameConfig)
	local lineNumber
	local baseName = filterSourceName(lineName, renameConfig.nameFiltering)
	if renameConfig.moveLineNumber then
		lineNumber = baseName:match(BASE_NUM_PATTERN)
		if lineNumber then
			baseName = baseName:gsub(BASE_NUM_PATTERN, "")
		end
	end
	if renameConfig.addType then
		baseName = baseName.." "..getVehicleTypeStr(vehicle)
	end
	return baseName .. renameConfig.numberSeparator .. (lineNumber or "")
end

---@param baseName string
---@param num number
---@param numDigits number
---@return string
local function getVehicleNewName(baseName, num, numDigits)
	-- local digits = configData.vehicleNumDigits
	return string.format("%s%0"..numDigits.."d", baseName, num)
end

-- Remember last names of lines to save on unnecessary processing.
---@type table<number, {name: string, vehs: table<number, boolean>, maxIdPerName: table<string, number>}>
local lineVehiclesCache = {
}

local function getNumDigits(num)
	return num > 0 and math.floor(math.log(num, 10) + 1) or 1
end

---Rename vehicle on given line.
---@param renameConfig VehicleRenameConfig
---@param lineId number
---@param lineName string
---@return integer
local function renameAllVehiclesOnLine(renameConfig, lineId, lineName)
	local cachedLineInfo = lineVehiclesCache[lineId] or {}
	lineVehiclesCache[lineId] = cachedLineInfo
	
	local vehIds = api.engine.system.transportVehicleSystem.getLineVehicles(lineId)
	local vehiclesChanged = not cachedLineInfo.vehIdsSet or cachedLineInfo.vehNum ~= #vehIds
	if not vehiclesChanged then
		for i, vehId in pairs(vehIds) do
			if not cachedLineInfo.vehIdsSet[vehId] then
				vehiclesChanged = true
				break
			end
		end
	end
	-- Skip renaming if no vehicles have changed, for performance.
	if lineName == cachedLineInfo.name and not vehiclesChanged then
		return 0
	end

	local vehiclesPerName = {}
	local numRenamed = 0

	cachedLineInfo.name = lineName
	cachedLineInfo.vehNum = #vehIds
	cachedLineInfo.vehIdsSet = {}

	local sortedVehIds = table_util.tableValues(vehIds)
	table.sort(sortedVehIds)
	
	-- First pass - prepare list of vehicles to rename per base name.
	for i, vehId in ipairs(sortedVehIds) do
		cachedLineInfo.vehIdsSet[vehId] = true

		local curName = api.engine.getComponent(vehId, api.type.ComponentType.NAME).name

		-- If vehicle doesn't match naming pattern - means player set a custom name, so keep it.
		if string.match(curName, "%d+$") then
			local vehicle = api.engine.getComponent(vehId, api.type.ComponentType.TRANSPORT_VEHICLE)
			local baseName = getVehicleBaseName(lineName, vehicle, renameConfig)
			vehiclesPerName[baseName] = vehiclesPerName[baseName] or {}
			table.insert(vehiclesPerName[baseName], vehId)
		end
	end
	-- Second pass - rename.
	for baseName, idsToRename in pairs(vehiclesPerName) do
		local numDigits = renameConfig.vehicleNumDigits or getNumDigits(#idsToRename)
		for i, vehId in ipairs(idsToRename) do
			local newName = getVehicleNewName(baseName, i, numDigits)
			api.cmd.sendCommand(api.cmd.make.setName(vehId, newName), commandCallback)
		end
		numRenamed = numRenamed + #idsToRename
	end
	return numRenamed
end

---Rename vehicle
---@param renameConfig VehicleRenameConfig
function rename.renameAllVehicles(renameConfig)
	local timer = os.clock()
	local lineIds = api.engine.system.lineSystem.getLinesForPlayer(game.interface.getPlayer())
	local numRenamed = 0
	for k, lineId in pairs(lineIds) do
		---@type string
		local lineName = api.engine.getComponent(lineId, api.type.ComponentType.NAME).name

		-- If line name follows default pattern, means player doesn't care about it so don't rename vehicles here.
		-- Also skip line if it has an exclamation mark in the end.
		if not lineName:find("^"..escape(_("Line")).." %d+$") and not lineName:find("%!%s-$") then
			numRenamed = numRenamed + renameAllVehiclesOnLine(renameConfig, lineId, lineName)
		end
	end
	
	local elapsed = os.clock() - timer
	log_util.log(string.format("Renamed %d vehicles across %d lines in %.0f ms.", numRenamed, #lineIds, elapsed * 1000), LOG_TAG)
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


return rename