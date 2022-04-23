local util = require "costly_infrastructure/util"

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
---@param baseMultAndMaxInflationByCategory table Maximum inflation at endYear (on top of cost multiplier) - per each category.
function InflationParams:new(startYear, endYear, baseMultAndMaxInflationByCategory)
	---@class InflationParams
	local o = {
		startYear = startYear,
		endYear = endYear,
		paramsByCategory = util.map(baseMultAndMaxInflationByCategory, function(params)
			local baseMult, maxInflation = table.unpack(params)
			return {
				baseMult = baseMult,
				flatness = getInflationFlatnessByMaxInflation(startYear, endYear, maxInflation)
			}
		end),
	}
	setmetatable(o, self)
	return o
end

---@param year number
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

--- Inflation multiplier based on year. Used for both construction and maintenance costs.
---@param category string
---@param year number
---@return number
function InflationParams:get(category, year)
	year = self:processYear(year)
	local params = self.paramsByCategory[category]
	return params.baseMult * getInflationByYearAndFlatness(year, self.startYear, params.flatness)
end

---@param category string
---@return number
function InflationParams:getBaseMult(category)
	return self.paramsByCategory[category].baseMult
end

--- Inflation multiplier based on year, for all categories.
---@param year number
---@return table
function InflationParams:getPerCategory(year)
	year = self:processYear(year)
	return util.map(self.paramsByCategory, function(params)
		return params.baseMult * getInflationByYearAndFlatness(year, self.startYear, params.flatness)
	end)
end


local function makeParamTypeData(min, max, step, defaultVal, labelFunc)
	local labels = {}
	local idxToVal = {}
	local i = 0
	local defaultIdx = 0
	defaultVal = defaultVal or min
	labelFunc = labelFunc or function(v) return ""..v end
	for v = min, max, step do
		idxToVal[i] = v
		labels[i + 1] = labelFunc(v, i)
		if v == defaultVal then
			defaultIdx = i
		end
		i = i + 1
	end
	--- @class ParamTypeData
	local data = {values = idxToVal, labels = labels, defaultIdx = defaultIdx}
	return data
end

local function valueAsPercent(v)
	return math.floor(v * 100) .. "%"
end

local function valueAsX(v)
	return v .. "x"
end

local paramTypes = {
	cost = makeParamTypeData(0.25, 8, 0.25, 1, valueAsPercent),
	upgrade = makeParamTypeData(1, 4, 1, 3, valueAsX),
	terrain = makeParamTypeData(1, 8, 1, 1, valueAsX),
	inflation = makeParamTypeData(1, 30, 1, 10, valueAsX),
}

local allParams = {
	{"mult_street", paramTypes.cost},
	{"mult_rail", paramTypes.cost},
	{"mult_water", paramTypes.cost},
	{"mult_air", paramTypes.cost},
	{"mult_bridges_tunnels", paramTypes.terrain},
	{"mult_terrain", paramTypes.terrain},
	{"mult_upgrade_track", paramTypes.upgrade},
	{"mult_upgrade_street", paramTypes.upgrade},
	{"inflation_year_start", makeParamTypeData(1850, 1950, 10)},
	{"inflation_year_end", makeParamTypeData(2000, 2100, 10, 2020)},
	{"inflation_street", paramTypes.inflation},
	{"inflation_rail", paramTypes.inflation},
	{"inflation_water", paramTypes.inflation},
	{"inflation_air", paramTypes.inflation},
}

local function getDataFromParams(params)
	-- debugPrint({"getDataFromParams", params})
	---@class ConfigObject : ConfigClass
	local o = {}
	--- These are applied to loaded resources via modifiers
	o.costMultipliers = {
		terrain = params.mult_terrain,
		tunnel = params.mult_bridges_tunnels,
		bridge = params.mult_bridges_tunnels,
		trackUpgrades = params.mult_upgrade_track,
		streetUpgrades = params.mult_upgrade_street
	}
	--- These are used for both maintenance (all types) and build costs (stations and depos only).
	o.inflation = InflationParams:new(params.inflation_year_start, params.inflation_year_end, {
		street = {params.mult_street, params.inflation_street},
		rail = {params.mult_rail, params.inflation_rail},
		water = {params.mult_water, params.inflation_water},
		air = {params.mult_air, params.inflation_air},
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
	local actualParams = {}
	for _, data in pairs(allParams) do
		local paramId = data[1]
		local paramData = data[2]
		if rawParams ~= nil and rawParams[paramId] ~= nil then
			actualParams[paramId] = paramData.values[rawParams[paramId]]
		else
			actualParams[paramId] = paramData.values[paramData.defaultIdx]
		end
	end
	local o = getDataFromParams(actualParams)
	setmetatable(o, config)

	game.config.phobos2077 = game.config.phobos2077 or {}
	game.config.phobos2077.costlyInfrastructure = o
	return o
end

---@type ConfigClass
return config