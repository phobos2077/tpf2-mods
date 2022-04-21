---@class ConfigClass
local config = {}

-- CONSTANTS

local inflationStartYear = 1850

-- Vanilla multiplier of maintenance costs based on construction costs.
config.vanillaMaintenanceCostMult = 1/120




-- DYNAMIC DATA

local function getDataFromParams(params, paramToMult)
	-- debugPrint({"getDataFromParams", params, paramToMult})
	local edgeCost = paramToMult[params.mult_edge_cost]
	local constrCost = paramToMult[params.mult_constr_cost]
	
	---@class ConfigObject : ConfigClass
	local o = {}
	--- These are applied when charging extra maintenance costs. Multiplied by inflation factor and based on vanilla costs.
	o.extraMaintenanceMultipliers = {
		edge = edgeCost,
		construction = constrCost
	}
	--- These are applied to loaded resources via modifiers
	o.costMultipliers = {
		terrain = 1.0,
		tunnel = edgeCost,
		bridge = edgeCost,
		track = edgeCost,
		street   = edgeCost,
		-- removeField = 1.0
	}
	-- More flatness => less inflation at later years.
	o.inflationFlatness = 64
	return o
end

--- Gets mod config object.
---@return ConfigObject
function config.get()
	return game.config.phobos2077.costlyInfrastructure
end

config.__index = config

--- Create and set mod params. Only call from mod.lua's runFn.
---@param params table Mod parameters.
---@param paramToMult table Maps param values to actual cost multiplier values.
---@return ConfigObject Config instance.
function config.createFromParams(params, paramToMult)
	local o = getDataFromParams(params, paramToMult)
	setmetatable(o, config)

	game.config.phobos2077 = game.config.phobos2077 or {}
	game.config.phobos2077.costlyInfrastructure = o
	return o
end

--- Calculates inflation based on year and flatness parameter.
---@param year number
---@param flatness number
---@return number
function config.getInflationByYearAndFlatness(year, flatness)
	-- http://fooplot.com/#W3sidHlwZSI6MCwiZXEiOiIoKHgtMTg1MCs4MCkvODApXjIiLCJjb2xvciI6IiMwMDAwMDAifSx7InR5cGUiOjEwMDAsIndpbmRvdyI6WyIxODUwIiwiMjA1MCIsIjAiLCIyMCJdfV0-
	-- ((x-1850+50)/50)^2
	local base = (year - inflationStartYear + flatness)/flatness
	if base < 1 then
		base = 1
	end
	return base * base
end

--- Inflation multiplier based on year. Used for both construction and maintenance costs.
---@param self ConfigObject
---@param year number
---@return number
function config.getInflation(self, year)
	year = year or game.interface and game.interface.getGameTime().date.year or inflationStartYear
	return config.getInflationByYearAndFlatness(year, self.inflationFlatness)
end

---@type ConfigClass
return config