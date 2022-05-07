--[[
Mod config.

Copyright (c)  2022  phobos2077  (https://steamcommunity.com/id/phobos2077)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including the right to distribute and without limitation the rights to use, copy and/or modify
the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.
--]]

local table_util = require "autorename/lib/table_util"
local config_util = require "autorename/lib/config_util"
local Pattern = require("autorename/enum").Pattern

---@class ConfigClass
local config = {}

local paramTypes = {
	toggle = config_util.paramType({{false, "Disable"}, {true, "Enable"}}, 2, nil, "CHECKBOX")
}

local patternValues = table_util.tableValues(table_util.map(Pattern, function(pattern, key) return {pattern, _("pattern "..key)} end))
table.sort(patternValues, function(a, b) return a[1] < b[1] end)
local allParams = {
	--{"enable_vehicles", paramTypes.toggle},
	{"vehicle_pattern", config_util.paramType(patternValues, 1, nil, "COMBOBOX")}
}

---@param params number[]
local function getDataFromParams(params)
	---@class ConfigObject : ConfigClass
	local o = {
		---@type boolean
		renameVehicles = true, -- params.enable_vehicles,
		---@type number
		vehiclePattern = params.vehicle_pattern,
	}
	return o
end

--- Gets mod config object.
---@return ConfigObject
function config.get()
	return game.config.phobos2077.autorename
end

config.__index = config

config.allParams = allParams

--- Create and set mod params. Only call from mod.lua's runFn.
---@param rawParams table<string, number> Mod parameters as indexes to actual values in values table.
---@return ConfigObject Config instance.
function config.createFromParams(rawParams)
	-- debugPrint({"createFromParams", rawParams})
	local o = getDataFromParams(config_util.getActualParams(rawParams, allParams))
	setmetatable(o, config)

	game.config.phobos2077 = game.config.phobos2077 or {}
	game.config.phobos2077.autorename = o
	return o
end

---@type ConfigClass
return config