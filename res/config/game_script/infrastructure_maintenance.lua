local journal_util = require 'costly_infrastructure/journal_util'
local entity_util = require 'costly_infrastructure/entity_util'
local util = require 'costly_infrastructure/util'
local debug = require 'costly_infrastructure/debug'
local config = require 'costly_infrastructure/config'
local debugger = require "debugger"

local persistentData = {}

local function chargeForMaintenance(chargeAmount, carrierType, constructionType)
	chargeAmount = math.floor(chargeAmount)
	if math.abs(chargeAmount) >= 1 then
		journal_util.bookEntry(-chargeAmount, journal_util.Enum.Type.MAINTENANCE, carrierType, constructionType, 1)
	end
	return chargeAmount
end

--- Charge extra maintenance for all edges (roads and tracks).
---@param inflationPerCategory table
---@param statData table
local function chargeExtraEdgeMaintenance(inflationPerCategory, statData)
	local streetMult = inflationPerCategory.street - 1
	local trackMult  = inflationPerCategory.rail - 1

	if streetMult > 0 or trackMult > 0 then
		local costsByType = entity_util.getTotalEdgeCostsByType()
		local costToMaintMult = config.vanillaMaintenanceCostMult
		statData.edgeCosts = costsByType
		return
			-- First multiply by vanilla 1/120 cost-to-maintenance ratio and then by our extra charge multipliers.
			chargeForMaintenance(costsByType.street * costToMaintMult * streetMult, journal_util.Enum.Carrier.ROAD, journal_util.Enum.Construction.ROAD) +
			chargeForMaintenance(costsByType.track  * costToMaintMult * trackMult,  journal_util.Enum.Carrier.RAIL, journal_util.Enum.Construction.TRACK) 
	end
	return 0
end

local typeToCarrier = {
	street = journal_util.Enum.Carrier.ROAD,
	rail   = journal_util.Enum.Carrier.RAIL,
	water  = journal_util.Enum.Carrier.WATER,
	air    = journal_util.Enum.Carrier.AIR
}

--- Charge extra maintenance for all constructions (stations, depos).
---@param inflationPerCategory table
---@param statData table
local function chargeExtraConstructionMaintenance(inflationPerCategory, statData)
	local needExtraCharge = false
	local typeToMult = {}
	local result = 0
	-- Adjust inflation multipliers (minus 1 to account for costs already charged by the game)
	for typ, mult in pairs(inflationPerCategory) do
		typeToMult[typ] = mult - 1
		if typeToMult[typ] > 0 then
			needExtraCharge = true
		end
	end

	if needExtraCharge then
		local maintenanceByType = entity_util.getTotalConstructionMaintenanceByType()
		statData.constructionMaintenance = maintenanceByType
		for typ, mult in pairs(typeToMult) do
			-- Multiply actual un-modded maintenance totals for this type.
			result = result + chargeForMaintenance(maintenanceByType[typ] * mult, typeToCarrier[typ], journal_util.Enum.Construction.INFRASTRUCTURE)
		end
	end
	return result
end

local function chargeExtraMaintenance()
	local configData = config.get()
	local inflationMults = configData.inflation:getPerCategory()
	---@class MaintenanceStatData
	---@field edgeCosts EdgeCostsByType
	---@field constructionMaintenance ConstructionMaintenanceByType
	local statData = {}

	debugPrint({"Trying to charge extra maintenance costs", inflationMults})
	local totalCharged =
		chargeExtraEdgeMaintenance(inflationMults, statData) +
		chargeExtraConstructionMaintenance(inflationMults, statData)

	debugPrint({"Charged extra maintenance costs: " .. totalCharged, statData})
end

function data()
	return {
		save = function()
			return persistentData
		end,
		load = function(loadedState)
			persistentData = loadedState or {}
		end,
		update = function()
			local currentTime = game.interface.getGameTime().time
			local chargeInterval = game.config.chargeMaintenanceInterval
			if persistentData.lastMaintenanceCharge == nil then
				-- Make sure extra maintenance charge is always calculated 1 second after regular maintenance
				persistentData.lastMaintenanceCharge = math.floor(currentTime / chargeInterval) * chargeInterval + 1
			end
			if currentTime > persistentData.lastMaintenanceCharge + chargeInterval then
				chargeExtraMaintenance()
				persistentData.lastMaintenanceCharge = currentTime
			end
		end,
		guiHandleEvent = function(id, name, param)
			-- debugPrint({"guiHandleEvent", id, name, param})
		end,
		handleEvent = function(src, id, name, param)
			-- if src ~= "guidesystem.lua" then
			-- 	debugPrint({"handleEvent", src, id, name, param})
			-- end

			if id == "debug" and type(debug[name]) == "function" then
				if type(param) ~= "table" then
					debug[name](param)
				else
					debug[name](table.unpack(param))
				end
			end
		end
	}
end
