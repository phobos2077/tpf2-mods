--[[
Vehicle Tweaker mod

Copyright (c)  2022  phobos2077  (https://steamcommunity.com/id/phobos2077)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including the right to distribute and without limitation the rights to use, copy and/or modify
the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.
--]]


local config_util = require "vehicle-tweaks/lib/config_util"

local actualParams

--[[
local Carrier = {
	ROAD = 0,
	RAIL = 1,
	TRAM = 2,
	AIR = 3,
	WATER = 4,
}
]]

local function getVehicleCategory(metadata)
	local carrier = metadata.transportVehicle.carrier
	if carrier == "ROAD" or metadata.roadVehicle then
		return "road"
	elseif carrier == "TRAM" then
		return "tram"
	elseif carrier == "RAIL" or metadata.railVehicle then
		return metadata.railVehicle and metadata.railVehicle.engines and #metadata.railVehicle.engines > 0
			and "loco"
			or "wagon"
	elseif carrier == "AIR" or metadata.airVehicle then
		return "plane"
	elseif carrier == "WATER" or metadata.waterVehicle then
		return "ship"
	else
		print("! ERROR ! Unknown vehicle carrier: " .. (carrier or "nil"))
		return nil
	end
end

local function modelModifier(fileName, data)
	if data.metadata.transportVehicle and not data.metadata.car then
		local category = getVehicleCategory(data.metadata)
		if category then
			local avail = data.metadata.availability
			if avail and avail.yearTo and avail.yearTo > 0 then
				local addYears = actualParams["add_years_"..category]
				if addYears then
					avail.yearTo = avail.yearTo + addYears
				else
					avail.yearTo = 0
				end
			end

			local maintenance = data.metadata.maintenance
			local maintenanceScale = actualParams["maint_"..category]
			if maintenance and maintenance.runningCosts ~= nil and math.abs(maintenanceScale - 1.0) > 0.001 then
				if maintenance.runningCosts < 0 then
					maintenance.runningCostScale = (maintenance.runningCostScale or 1.0) * maintenanceScale
				elseif maintenance.runningCosts > 0 then
					maintenance.runningCosts = maintenance.runningCosts * maintenanceScale
				end
			end
		end
	end
	return data
end

local addYearValues = config_util.linearValues(0, {0, 45, 5}, {50, 100, 10})
table.insert(addYearValues, {false, "∞"})
local paramTypes = {
	addYears = config_util.paramType(addYearValues, 1, nil, "SLIDER"),
	maintenance = config_util.genParamLinear(config_util.fmt.percent, "SLIDER", 1.0, {0.0, 0.7, 0.1}, {0.75, 1.30, 0.05}, {1.4, 2.0, 0.1})
}


local allParams = {
	{"add_years_road", paramTypes.addYears},
	{"add_years_tram", paramTypes.addYears},
	{"add_years_loco", paramTypes.addYears},
	{"add_years_wagon", paramTypes.addYears},
	{"add_years_ship", paramTypes.addYears},
	{"add_years_plane", paramTypes.addYears},

	{"maint_road", paramTypes.maintenance},
	{"maint_tram", paramTypes.maintenance},
	{"maint_loco", paramTypes.maintenance},
	{"maint_wagon", paramTypes.maintenance},
	{"maint_ship", paramTypes.maintenance},
	{"maint_plane", paramTypes.maintenance},
}


function data()
	return {
		info = {
			minorVersion = 1,
			severityAdd = "NONE",
			severityRemove = "NONE",
			name = _("mod name"),
			description = _("mod desc"),
			tags = { "Script Mod" },
			authors = {
				{
					name = "phobos2077",
					role = "CREATOR",
					text = "",
					steamProfile = "76561198025571704",
				},
			},
			params = config_util.makeModParams(allParams)
		},
		runFn = function(settings, modParams)
			actualParams = config_util.getActualParams(modParams[getCurrentModId()], allParams)
		
			-- debugPrint({"vehicletweaks runFn", modParams, getCurrentModId(), actualParams})
		
			addModifier("loadModel", modelModifier)
		end
	}
end

