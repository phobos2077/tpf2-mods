local game_enum = require "autorename/lib/game_enum"
local table_util = require "autorename/lib/table_util"
local log_util = require "autorename/lib/log_util"
local entity_util = require "autorename/lib/entity_util"
local rename_common = require "autorename/rename_common"

local process_vehicles = {}

local Carrier = game_enum.Carrier
local LOG_TAG = "Automate"

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


local BASE_NUM_PATTERN = "%s+#?(%d+)$"

---@param lineName string
---@param vehicle userdata
---@param renameConfig VehicleProcessConfig
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


---Rename vehicle on given line.
---@param configData VehicleProcessConfig
---@param lineId number
---@param lineName string
---@return integer
local function processAllVehiclesOnLine(configData, lineId, lineName)
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
	local lineColor = api.engine.getComponent(lineId, api.type.ComponentType.COLOR).color
	-- Skip renaming if no vehicles have changed, for performance.
	if lineName == cachedLineInfo.name and not vehiclesChanged then
		return 0
	end

	local vehiclesPerName = {}
	local numRenamed, numRecolored = 0, 0

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
			local baseName = getVehicleBaseName(lineName, vehicle, configData)
			vehiclesPerName[baseName] = vehiclesPerName[baseName] or {}
			table.insert(vehiclesPerName[baseName], vehId)
		end
	end
	-- Second pass - rename.
	for baseName, idsToRename in pairs(vehiclesPerName) do
		local numDigits = configData.vehicleNumDigits or getNumDigits(#idsToRename)
		for i, vehId in ipairs(idsToRename) do
			local newName = getVehicleNewName(baseName, i, numDigits)
			api.cmd.sendCommand(api.cmd.make.setName(vehId, newName), commandCallback)
		end
		numRenamed = numRenamed + #idsToRename
	end
	return numRenamed
end

---Rename vehicle
---@param renameConfig VehicleProcessConfig
function process_vehicles.processVehiclesOnLines(renameConfig)
	local timer = os.clock()
	local lineIds = api.engine.system.lineSystem.getLinesForPlayer(game.interface.getPlayer())
	local totalRenamed, totalRecolored = 0, 0
	for k, lineId in pairs(lineIds) do
		---@type string
		local lineName = api.engine.getComponent(lineId, api.type.ComponentType.NAME).name

		-- If line name follows default pattern, means player doesn't care about it so don't automate.
		-- Also skip line if it has an exclamation mark in the end.
		if not lineName:find("^"..escape(_("Line")).." %d+$") and not lineName:find("%!%s-$") then
			local numRenamed, numRecolored = processAllVehiclesOnLine(renameConfig, lineId, lineName)
		end
	end
	
	local elapsed = os.clock() - timer
	log_util.log(string.format("Renamed %d vehicles across %d lines in %.0f ms.", totalRenamed, #lineIds, elapsed * 1000), LOG_TAG)
end


return process_vehicles