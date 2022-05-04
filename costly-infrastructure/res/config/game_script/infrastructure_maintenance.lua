--[[
Charges extra maintenance costs after every normal maintenance charge.

Copyright (c)  2022  phobos2077  (https://steamcommunity.com/id/phobos2077)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including the right to distribute and without limitation the rights to use, copy and/or modify
the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.
--]]

local journal_util = require 'lib/journal_util'
local table_util = require 'lib/table_util'
local entity_costs = require 'costly_infrastructure/entity_costs'
local enum = require 'costly_infrastructure/enum'
local debug = require 'costly_infrastructure/debug'
local config = require 'costly_infrastructure/config'
local debugger = require "debugger"

--- CONSTANTS

local Category = enum.Category

local categoryToCarrier = {
	[Category.STREET] = journal_util.Enum.Carrier.ROAD,
	[Category.RAIL]   = journal_util.Enum.Carrier.RAIL,
	[Category.WATER]  = journal_util.Enum.Carrier.WATER,
	[Category.AIR]    = journal_util.Enum.Carrier.AIR
}

local edgeCategoryToConstruction = {
	[Category.STREET] = journal_util.Enum.Construction.STREET,
	[Category.RAIL]   = journal_util.Enum.Construction.TRACK,
}


--- VARIABLES

local persistentData = {}


--- FUNCTIONS

local function chargeForMaintenance(chargeAmount, carrierType, constructionType)
	chargeAmount = math.floor(chargeAmount)
	if math.abs(chargeAmount) >= 1 then
		journal_util.bookEntry(-chargeAmount, journal_util.Enum.Type.MAINTENANCE, carrierType, constructionType, 1)
		return chargeAmount
	else
		return 0
	end
end

--- Charge extra maintenance for all edges (roads and tracks).
---@param inflationByCategory table
---@param statData table
local function chargeExtraEdgeMaintenance(inflationByCategory, statData)
	local edgeCostsByCategory
	for cat, constructionType in pairs(edgeCategoryToConstruction) do
		-- First multiply by vanilla 1/120 cost-to-maintenance ratio and then by inflation minus 1 to account for maintenance charged by game engine.
		local finalMult = config.vanillaMaintenanceCostMult * (inflationByCategory[cat] - 1)
		if finalMult > 0 then
			edgeCostsByCategory = edgeCostsByCategory or entity_costs.getTotalEdgeCostsByCategory()
			local chargedAmount = chargeForMaintenance(edgeCostsByCategory[cat] * finalMult, categoryToCarrier[cat], constructionType)
			table_util.incInTable(statData.chargedByCategory, cat, chargedAmount)
		end
	end
	statData.edgeCosts = edgeCostsByCategory
end

--- Charge extra maintenance for all constructions (stations, depos).
---@param costMultipliers table
---@param inflationByCategory table
---@param statData table
local function chargeExtraConstructionMaintenance(costMultipliers, inflationByCategory, statData)
	local maintenanceByType
	for cat, inflation in pairs(inflationByCategory) do
		local finalMult = costMultipliers[cat] * inflation - 1
		if finalMult > 0 then
			maintenanceByType = maintenanceByType or entity_costs.getTotalConstructionMaintenanceByCategory()
			-- Multiply actual un-modded maintenance totals for this type.
			local chargedAmount = chargeForMaintenance(maintenanceByType[cat] * finalMult, categoryToCarrier[cat], journal_util.Enum.Construction.STATION)
			table_util.incInTable(statData.chargedByCategory, cat, chargedAmount)
		end
	end
	statData.constructionMaintenance = maintenanceByType
end

local function chargeExtraMaintenance(configData)
	local inflationMults = configData.inflation:getPerCategory()
	---@class MaintenanceStatData
	---@field edgeCosts EdgeCostsByCategory
	---@field constructionMaintenance ConstructionMaintenanceByCategory
	local statData = {chargedByCategory = table_util.map(inflationMults, function() return 0 end)}
	--debugPrint({"Trying to charge extra maintenance costs", inflationMults})
	chargeExtraEdgeMaintenance(inflationMults, statData)
	chargeExtraConstructionMaintenance(configData.costMultipliers, inflationMults, statData)

	local charged = statData.chargedByCategory
	local total = table_util.sum(charged)
	local mults = table_util.map(inflationMults, function(infl, cat) return infl * configData.costMultipliers[cat] end)
	
	--debugPrint({msg = "Charged Extra Maintenance", stats = statData, inflation = inflationMults, mults = configData.costMultipliers})
	print(string.format("Charged extra maintenance costs. Rail: $%d, Road: $%d, Water: $%d, Air: $%d. TOTAL = $%d", charged.rail, charged.street, charged.water, charged.air, total)..
		string.format("\nCurrent multipliers: Rail: %.2f, Road: %.2f, Water: %.2f, Air: %.2f", mults.rail, mults.street, mults.water, mults.air))
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
			local configData = config.get()

			local chargeInterval = game.config.chargeMaintenanceInterval
			if persistentData.lastMaintenanceCharge == nil then
				-- Make sure extra maintenance charge is always calculated 1 second after regular maintenance
				persistentData.lastMaintenanceCharge = math.floor(currentTime / chargeInterval) * chargeInterval + 1
			end
			if currentTime > persistentData.lastMaintenanceCharge + chargeInterval then
				-- chargeExtraMaintenance(configData)
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
