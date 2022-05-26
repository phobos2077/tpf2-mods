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

-- local table_util = require "costly_infrastructure_v2/lib/table_util"
local config_util = require "costly_infrastructure_v2/lib/config_util"
-- local inflation = require "costly_infrastructure_v2/inflation"

local Category = (require "costly_infrastructure_v2/enum").Category

---@class ConfigClass
local config = {}

-- CONSTANTS

-- Vanilla multiplier of maintenance costs based on construction costs.
config.vanillaMaintenanceCostMult = 1/120


local function genSlider(labelFunc, defaultVal, ...) return config_util.genParamLinear(labelFunc, "SLIDER", defaultVal, ...) end
local fmt = config_util.fmt

local paramTypes = {
	cost = function(default) return genSlider(fmt.percent, default or 1, {0.25, 2.0, 0.25}, {2.5, 4.0, 0.5}, {5, 10, 1}) end,
	--maint = function(default) return genSlider(fmt.percent, default or 1, {0.25, 1.5, 0.25}, {2.0, 4.0, 0.5}) end,
	vehMult = function(default) return genSlider(fmt.timesX, default or 10, {1, 4, 0.5}, {5, 10, 1}, {12, 30, 2}) end,
	upgrade = function(default) return genSlider(fmt.timesX, default or 3, 0.5, 5, 0.5) end,
	terrain = function(default) return genSlider(fmt.timesX, default or 1, {0.5, 3, 0.5}, {4, 8, 1}) end,
	--inflation = function(default) return genSlider(fmt.timesX, default or 10, 1, 30, 1) end,
	--year = function (min, max, default)	return genSlider(nil, default, min, max, 10) end,
	flag = function(default) return config_util.checkboxParam(default) end,
}

local allParams = {
	{"mult_street", paramTypes.cost(1)},
	{"mult_rail", paramTypes.cost(1)},
	{"mult_water", paramTypes.cost(1)},
	{"mult_air", paramTypes.cost(1)},
	{"mult_bridges_tunnels", paramTypes.terrain(3)},
	{"mult_terrain", paramTypes.terrain(1)},
	{"mult_upgrade_edge", paramTypes.upgrade()},
	{"veh_mult_street", paramTypes.vehMult(6)},
	{"veh_mult_rail", paramTypes.vehMult(6)},
	{"veh_mult_water", paramTypes.vehMult(6)},
	{"veh_mult_air", paramTypes.vehMult(3)},
	{"scale_edge_costs", paramTypes.flag(true)},
	{"maint_mult_street", paramTypes.cost(1)},
	{"maint_mult_rail", paramTypes.cost(3)},
	{"maint_mult_water", paramTypes.cost(3)},
	{"maint_mult_air", paramTypes.cost(2)},
--[[
	{"inflation_year_start", paramTypes.year(1850, 1950, 1880)},
	{"inflation_year_end", paramTypes.year(2000, 2100, 2000)},
	{"inflation_street", paramTypes.inflation(10)},
	{"inflation_rail", paramTypes.inflation(15)},
	{"inflation_water", paramTypes.inflation(10)},
	{"inflation_air", paramTypes.inflation(10)},
	]]
}

---@param params number[]
local function getDataFromParams(params)
	-- debugPrint({"getDataFromParams", params})
	---@class ConfigObject : ConfigClass
	local o = {}
	--- These are applied to loaded resources via modifiers
	---@class StaticCostMultipliers
	o.costMultipliers = {
		[Category.STREET] = params.mult_street,
		[Category.RAIL] = params.mult_rail,
		[Category.WATER] = params.mult_water,
		[Category.AIR] = params.mult_air,
		terrain = params.mult_terrain,
		tunnel = params.mult_bridges_tunnels,
		bridge = params.mult_bridges_tunnels,
		trackUpgrades = params.mult_upgrade_edge,
		streetUpgrades = params.mult_upgrade_edge
	}
	--- These are calculated against roster of available vehicles and result is change construction build costs.
	---@type table<string, VehicleMultParam>
	o.vehicleMultParams = {
		---@class VehicleMultParam
		[Category.STREET] = {
			base = 20, -- Stagecoach
			max = 1000, -- Cascadia Tank Truck
			exp = 0.5,
			mult = params.veh_mult_street
		},
		[Category.RAIL] = {
			base = 70, -- Baldwin's Six-Wheels
			max = 6500, -- Russian Class VL80S
			exp = 0.5,
			mult = params.veh_mult_rail,
		},
		[Category.WATER] = {
			base = 550, -- Zoroaster
			max = 3200, -- Cascadia Tank Truck
			exp = 0.5,
			mult = params.veh_mult_water,
		},
		[Category.AIR] = {
			base = 330, -- Vickers Victoria
			max = 13000, -- Tupolev TU-204
			exp = 0.5,
			mult = params.veh_mult_air,
		},
	}
	---@type boolean
	o.scaleEdgeCosts = params.scale_edge_costs
	--- Additional multiplier for bridge and tunnel maintenance. TODO?
	-- o.bridgeAndTunnelMaintenanceFactor = 1
	---@type table<string,MaintenanceCostParam>
	o.maintenanceCostParams = {
		---@class MaintenanceCostParam
		[Category.STREET] = {
			mult = params.maint_mult_street,
			exp = 1.0,
		},
		[Category.RAIL] = {
			mult = params.maint_mult_rail,
			exp = 1.0,
		},
		[Category.WATER] = {
			mult = params.maint_mult_water,
			exp = 1.0,
		},
		[Category.AIR] = {
			mult = params.maint_mult_air,
			exp = 1.0,
		},
	}
	--- These are used for both maintenance (all types) and build costs (stations and depos only).
--[[
	o.inflation = inflation.InflationParams:new(params.inflation_year_start, params.inflation_year_end, {
		[Category.STREET] = params.inflation_street,
		[Category.RAIL] = params.inflation_rail,
		[Category.WATER] = params.inflation_water,
		[Category.AIR] = params.inflation_air,
	})]]
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