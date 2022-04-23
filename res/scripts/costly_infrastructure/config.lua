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
---@param flatness number
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
function InflationParams:new(startYear, endYear, minInflation, maxInflation)
	---@class InflationParams
	local o = {
		mult = minInflation,
		startYear = startYear,
		endYear = endYear,
		-- More flatness => less inflation at later years.
		flatness = getInflationFlatnessByMaxInflation(startYear, endYear, maxInflation / minInflation),
	}
	setmetatable(o, self)
	return o
end

--- Inflation multiplier based on year. Used for both construction and maintenance costs.
---@param year number
---@return number
function InflationParams:get(year)
	year = year or game.interface and game.interface.getGameTime().date.year or self.startYear
	-- Cap year to min/max range.
	if year < self.startYear then
		year = self.startYear
	elseif year > self.endYear then
		year = self.endYear
	end
	return self.mult * getInflationByYearAndFlatness(year, self.startYear, self.flatness)
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
	cost = makeParamTypeData(0.25, 4, 0.25, 1, valueAsPercent),
	upgrade = makeParamTypeData(1, 4, 1, valueAsX),
	terrain = makeParamTypeData(1, 4, 1, valueAsX),
	inflationMin = makeParamTypeData(1, 8, 1, 1, valueAsX),
	inflationMax = makeParamTypeData(1, 31, 2, 15, valueAsX),
}

local allParams = {
	{"inflation_min", paramTypes.inflationMin},
	{"inflation_max", paramTypes.inflationMax},
	{"inflation_year_start", makeParamTypeData(1850, 1950, 10)},
	{"inflation_year_end", makeParamTypeData(2000, 2100, 10)},
	{"mult_track_cost", paramTypes.cost},
	{"mult_street_cost", paramTypes.cost},
	{"mult_bridges_tunnels", paramTypes.terrain},
	{"mult_terrain", paramTypes.terrain},
	{"mult_upgrade_track", paramTypes.upgrade},
	{"mult_upgrade_street", paramTypes.upgrade},
}

local function getDataFromParams(params)
	debugPrint({"getDataFromParams", params})
	---@class ConfigObject : ConfigClass
	local o = {}
	--- These are applied when charging extra maintenance costs. Multiplied by inflation factor and based on vanilla costs.
	o.extraMaintenanceMultipliers = {
		---@class ConfigObject.EdgeCostMultipliers
		edge = {
			street = params.mult_street_cost,
			track = params.mult_track_cost,
		},
		---@class ConfigObject.ConstructionCostMultipliers
		construction = {
			street = 4,
			rail = 4,
			water = 5,
			air = .7,
		}
	}
	--- These are applied to loaded resources via modifiers
	o.costMultipliers = {
		terrain = params.mult_terrain,
		tunnel = params.mult_bridges_tunnels,
		bridge = params.mult_bridges_tunnels,
		track = params.mult_track_cost,
		street = params.mult_street_cost,
		trackUpgrades = params.mult_upgrade_track,
		streetUpgrades = params.mult_upgrade_street,

		-- TODO:
		---@class ConfigObject.ConstructionCostMultipliers
		construction = {
			street = 1,
			rail = 1,
			water = 1,
			air = 1,
		}
	}
	o.inflation = InflationParams:new(params.inflation_year_start, params.inflation_year_end, params.inflation_min, params.inflation_max)
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

---@param self ConfigObject
---@param baseCost number
---@param year number
---@return number
function config:getConstructionCost(baseCost, year)
	
	return baseCost * self.costMultipliers.construction
end

---@type ConfigClass
return config