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

-- local table_util = require "costly_infrastructure/lib/table_util"
local config_util = require "costly_infrastructure/lib/config_util"
local inflation = require "costly_infrastructure/inflation"

local Category = (require "costly_infrastructure/enum").Category

---@class ConfigClass
local config = {}

-- CONSTANTS

-- Vanilla multiplier of maintenance costs based on construction costs.
config.vanillaMaintenanceCostMult = 1/120


local function genSlider(min, max, step, defaultVal, labelFunc) return config_util.genParamLinear(labelFunc, "SLIDER", defaultVal, min, max, step) end
local fmt = config_util.fmt

local paramTypes = {
	cost = function(default) return genSlider(0.25, 8, 0.25, default or 1, fmt.percent) end,
	upgrade = function(default) return genSlider(0.5, 4, 0.5, default or 3, fmt.timesX) end,
	terrain = function(default) return genSlider(0.5, 8, 0.5, default or 1, fmt.timesX) end,
	inflation = function(default) return genSlider(1, 30, 1, default or 10, fmt.timesX) end,
	year = function (min, max, default)	return genSlider(min, max, 10, default, fmt.timesX) end,
}

local allParams = {
	{"mult_street", paramTypes.cost(1.5)},
	{"mult_rail", paramTypes.cost(2)},
	{"mult_water", paramTypes.cost(1.5)},
	{"mult_air", paramTypes.cost(0.5)},
	{"mult_bridges_tunnels", paramTypes.terrain(3)},
	{"mult_terrain", paramTypes.terrain(1)},
	{"mult_upgrade_track", paramTypes.upgrade()},
	{"mult_upgrade_street", paramTypes.upgrade()},
	{"inflation_year_start", paramTypes.year(1850, 1950, 1880)},
	{"inflation_year_end", paramTypes.year(2000, 2100, 2000)},
	{"inflation_street", paramTypes.inflation(10)},
	{"inflation_rail", paramTypes.inflation(15)},
	{"inflation_water", paramTypes.inflation(10)},
	{"inflation_air", paramTypes.inflation(10)},
}
---@param params number[]
local function getDataFromParams(params)
	-- debugPrint({"getDataFromParams", params})
	---@class ConfigObject : ConfigClass
	local o = {}
	--- These are applied to loaded resources via modifiers
	o.costMultipliers = {
		[Category.STREET] = params.mult_street,
		[Category.RAIL] = params.mult_rail,
		[Category.WATER] = params.mult_water,
		[Category.AIR] = params.mult_air,
		terrain = params.mult_terrain,
		tunnel = params.mult_bridges_tunnels,
		bridge = params.mult_bridges_tunnels,
		trackUpgrades = params.mult_upgrade_track,
		streetUpgrades = params.mult_upgrade_street
	}
	--- These are used for both maintenance (all types) and build costs (stations and depos only).
	o.inflation = inflation.InflationParams:new(params.inflation_year_start, params.inflation_year_end, {
		[Category.STREET] = params.inflation_street,
		[Category.RAIL] = params.inflation_rail,
		[Category.WATER] = params.inflation_water,
		[Category.AIR] = params.inflation_air,
	})
	return o
end

--- Gets mod config object.
---@return ConfigObject
function config.get()
	return game.config.phobos2077.costlyInfrastructure
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
	game.config.phobos2077.costlyInfrastructure = o
	return o
end

---@type ConfigClass
return config