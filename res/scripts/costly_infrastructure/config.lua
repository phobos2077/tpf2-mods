---@class ConfigClass
local config = {}

-- CONSTANTS

local inflationStartYear = 1850

-- Vanilla multiplier of maintenance costs based on construction costs.
config.vanillaMaintenanceCostMult = 1/120


-- DYNAMIC DATA

local function getDataFromParams(params)
	---@class ConfigObject : ConfigClass
	local o = {}
	--- These are applied when charging extra maintenance costs. Multiplied by inflation factor and based on vanilla costs.
	o.extraMaintenanceMultipliers = {
		---@class ConfigObject.EdgeMaintenanceMultipliers
		edge = {
			street = 4,
			track = 4,
		},
		---@class ConfigObject.ConstructionMaintenanceMultipliers
		construction = {
			street = 4,
			rail = 4,
			water = 5,
			air = .7,
		}
	}
	--- These are applied to loaded resources via modifiers
	o.costMultipliers = {
		terrain = 4.0,
		tunnel = 3.0,
		bridge = 3.0,
		track = 2.0,
		street   = 4.0,
		bulldoze_field = 1.0,

		railroadCatenary 		= 1.0, -- original: 0.3
		roadTramLane 			= 0.3, -- original: 0.2
		roadElectricTramLane	= 1.0, -- original: 0.4
	}
	-- More flatness => less inflation at later years.
	o.inflationFlatness = {
		construction = 64,
		maintenance = 64
	}
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
---@return ConfigObject Config instance.
function config.createFromParams(params)
	local o = getDataFromParams(params)
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

--- Inflation multiplier for maintenance.
---@param self ConfigObject
---@return number
function config.getMaintenanceInflation(self)
	local year = game.interface and game.interface.getGameTime().date.year or inflationStartYear
	return config.getInflationByYearAndFlatness(year, self.inflationFlatness.maintenance)
end

--- Inflation multiplier for construction based on year.
---@param self ConfigObject
---@param year number
---@return number
function config.getConstructionInflation(self, year)
	year = year or game.interface and game.interface.getGameTime().date.year or inflationStartYear
	return config.getInflationByYearAndFlatness(year, self.inflationFlatness.construction)
end

---@type ConfigClass
return config