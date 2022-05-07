local game_enum = require "autorename/lib/game_enum"
local table_util = require "autorename/lib/table_util"
local log_util = require "autorename/lib/log_util"
local Pattern = (require "autorename/enum").Pattern

local rename = {}

local Carrier = game_enum.Carrier

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

local carrierToDefaultName = {
	[Carrier.ROAD] = _("Road vehicle"),
	[Carrier.RAIL] = "Train",
	[Carrier.TRAM] = "Tram",
	[Carrier.AIR] = "Plane",
	[Carrier.WATER] = "Ship"
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

function rename.renameVehicles(vehiclePattern)
	local timer = os.clock()
	local lineIds = api.engine.system.lineSystem.getLinesForPlayer(game.interface.getPlayer())
	local numRenamed = 0
	for _, lineId in pairs(lineIds) do
		local lineName = api.engine.getComponent(lineId, api.type.ComponentType.NAME).name

		-- If line name follows default pattern, means player doesn't care about it so don't rename vehicles here.
		if not string.find(lineName, "^Line %d+$") then
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

			-- First pass - calculate max numbers and prepare list of vehicles to rename.
			for _, vehId in ipairs(vehIds) do
				cachedLineInfo.vehs[vehId] = true
				-- Skip vehicle processing if we know for sure we processed it already with the same line name.
				if lineNameChanged or not lastVehicles[vehId] then
					local vehicle = api.engine.getComponent(vehId, api.type.ComponentType.TRANSPORT_VEHICLE)
					local curName = api.engine.getComponent(vehId, api.type.ComponentType.NAME).name
					local defaultName = carrierToDefaultName[vehicle.carrier]

					-- If vehicle doesn't match naming pattern - means player set a custom name, so keep it.
					if string.match(curName, "%d+$") then
						local baseName = getBaseNameByPattern(vehiclePattern, lineName, vehicle)
						local num = string.match(curName, "^"..escape(baseName).." (%d+)")
						num = num and tonumber(num)
						debugPrint({num = num == nil and "nil" or num, baseName = baseName, maxId = maxIdPerName[baseName] or "nil"})
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
				else
					print("Skipping veh "..vehId)
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
		end
	end
	
	local elapsed = os.clock() - timer
	log_util.log(string.format("Renamed %d vehicles across %d lines in %.0f ms.", numRenamed, #lineIds, elapsed * 1000))
end

return rename