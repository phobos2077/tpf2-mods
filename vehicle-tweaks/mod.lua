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
	if carrier == "ROAD" then
		return "road"
	elseif carrier == "TRAM" then
		return "tram"
	elseif carrier == "RAIL" then
		return metadata.railVehicle and metadata.railVehicle.engines and #metadata.railVehicle.engines > 0
			and "loco"
			or "wagon"
	elseif carrier == "AIR" then
		return "plane"
	elseif carrier == "WATER" then
		return "ship"
	else
		print("! ERROR ! Unknown vehicle carrier: " .. carrier)
		return nil
	end
end

local function modelModifier(fileName, data)
	if data.metadata.transportVehicle and not data.metadata.car then
		local avail = data.metadata.availability
		local category = getVehicleCategory(data.metadata)
		if category and avail and avail.yearFrom and avail.yearFrom > 0 and avail.yearTo and avail.yearTo > avail.yearFrom then
			local mult = actualParams["mult_"..category]
			local lifetime = avail.yearTo - avail.yearFrom
			lifetime = math.ceil(lifetime * mult)
			avail.yearTo = avail.yearFrom + lifetime
		end
	end
	return data
end

local multParamType = config_util.paramType({0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0}, 3, config_util.fmt.percent, "SLIDER")

local allParams = {
	{"mult_road", multParamType},
	{"mult_tram", multParamType},
	{"mult_loco", multParamType},
	{"mult_wagon", multParamType},
	{"mult_ship", multParamType},
	{"mult_plane", multParamType},
}



function data()
	return {
		info = {
			minorVersion = 0,
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
		
			debugPrint({"vehicletweaks runFn", modParams, getCurrentModId(), actualParams})
		
			addModifier("loadModel", modelModifier)
		end
	}
end

