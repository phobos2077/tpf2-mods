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

local table_util = require "lib/table_util"
local config_util = require "lib/config_util"
local entity_info = require "costly_infrastructure/entity_info"

local Category = entity_info.Category

---@class ConfigClass
local config = {}

-- CONSTANTS

-- Vanilla multiplier of maintenance costs based on construction costs.
config.vanillaMaintenanceCostMult = 1/120


local function getInflationFlatnessByMaxInflation(startYear, endYear, maxInflation)
	-- Don't allow negative inflation and prevent division by zero.
	if maxInflation <= 1 then
		return 9999999
	else
		return (startYear - endYear) / (1 - math.sqrt(maxInflation))
	end
end

--- Calculates inflation based on year and flatness parameter.
---@param year number
---@param startYear number
---@param flatness number More flatness => less inflation at later years.
---@return number
local function getInflationByYearAndFlatness(year, startYear, flatness)
	-- http://fooplot.com/#W3sidHlwZSI6MCwiZXEiOiIoKHgtMTg1MCs4MCkvODApXjIiLCJjb2xvciI6IiMwMDAwMDAifSx7InR5cGUiOjEwMDAsIndpbmRvdyI6WyIxODUwIiwiMjA1MCIsIjAiLCIyMCJdfV0-
	-- ((x-1850+50)/50)^2
	local base = (year - startYear + flatness)/flatness
	if base < 1 then
		base = 1
	end
	return base * base
end

---@class InflationParams
local InflationParams = {}
InflationParams.__index = InflationParams

---@return InflationParams
---@param startYear number Year when inflation starts.
---@param endYear number Year of maximum inflation.
---@param maxInflationByCategory table Maximum inflation at endYear (on top of cost multiplier) - per each category.
function InflationParams:new(startYear, endYear, maxInflationByCategory)
	---@class InflationParams
	local o = {
		startYear = startYear,
		endYear = endYear,
		flatnessByCategory = table_util.map(maxInflationByCategory, function(maxInflation)
			return getInflationFlatnessByMaxInflation(startYear, endYear, maxInflation)
		end),
	}
	setmetatable(o, self)
	return o
end

---@param year number?
---@return number
function InflationParams:processYear(year)
	year = year or game.interface and game.interface.getGameTime().date.year or self.startYear
	-- Cap year to min/max range.
	if year < self.startYear then
		year = self.startYear
	elseif year > self.endYear then
		year = self.endYear
	end
	return year
end

--- Inflation multiplier based on year.
---@param category string
---@param year number?
---@return number
function InflationParams:get(category, year)
	year = self:processYear(year)
	return getInflationByYearAndFlatness(year, self.startYear, self.flatnessByCategory[category])
end

--- Inflation multiplier based on year, for all categories.
---@param year number?
---@return table
function InflationParams:getPerCategory(year)
	year = self:processYear(year)
	return table_util.map(self.flatnessByCategory, function(flatness)
		return getInflationByYearAndFlatness(year, self.startYear, flatness)
	end)
end




local function valueAsPercent(v)
	return math.floor(v * 100) .. "%"
end

local function valueAsX(v)
	return v .. "x"
end

local makeSliderData = config_util.makeParamTypeDataForSlider

local paramTypes = {
	cost = function(default) return makeSliderData(0.25, 8, 0.25, default or 1, valueAsPercent) end,
	upgrade = function(default) return makeSliderData(0.5, 4, 0.5, default or 3, valueAsX) end,
	terrain = function(default) return makeSliderData(0.5, 8, 0.5, default or 1, valueAsX) end,
	inflation = function(default) return makeSliderData(1, 30, 1, default or 10, valueAsX) end,
	year = function (min, max, default)	return makeSliderData(min, max, 10, default) end,
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
	o.inflation = InflationParams:new(params.inflation_year_start, params.inflation_year_end, {
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
---@param rawParams table Mod parameters as indexes to actual values in values table.
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