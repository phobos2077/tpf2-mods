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

local journal_util = require "costly_infrastructure_v2/lib/journal_util"
local table_util = require "costly_infrastructure_v2/lib/table_util"
local math_ex = require "costly_infrastructure_v2/lib/math_ex"

local entity_costs = require "costly_infrastructure_v2/entity_costs"
local line_stats = require "costly_infrastructure_v2/line_stats"
local station_stats = require "costly_infrastructure_v2/station_stats"
local enum = require "costly_infrastructure_v2/enum"
local debug = require "costly_infrastructure_v2/debug"
local config = require "costly_infrastructure_v2/config"

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
---@param usageMultByCategory table
---@param statData table
local function chargeExtraConstructionMaintenance(costMultipliers, usageMultByCategory, statData)
	local maintenanceByType
	for cat, usageMult in pairs(usageMultByCategory) do
		local finalMult = costMultipliers[cat] * usageMult - 1
		if finalMult > 0 then
			maintenanceByType = maintenanceByType or entity_costs.getTotalConstructionMaintenanceByCategory()
			-- Multiply actual un-modded maintenance totals for this type.
			local chargedAmount = chargeForMaintenance(maintenanceByType[cat] * finalMult, categoryToCarrier[cat], journal_util.Enum.Construction.STATION)
			table_util.incInTable(statData.chargedByCategory, cat, chargedAmount)
		end
	end
	statData.constructionMaintenance = maintenanceByType
end

---Calculate infrastructure usage multiplier.
---@param linesRate number Total rates (line.rate * #line.stops) of all lines for this category.
---@param stationsCapacity number Total capacities of all stations for category.
---@param params MaintenanceCostParam
local function calculateUsageMult(linesRate, stationsCapacity, params)
	local mult = stationsCapacity > 0
		and (linesRate / stationsCapacity)^params.exp * params.mult
		or 0
	return math.max(mult, 1)
end

---@param configData ConfigObject
local function chargeExtraMaintenance(configData)
	local stationCapacityByCat = station_stats.getTotalCapacityOfAllStationsByCategory()
	local linesRateByCat = line_stats.getTotalLineRatesByCategory()
	local usageMultByCat = table_util.mapDict(Category, function(cat)
		return cat, calculateUsageMult(linesRateByCat[cat], stationCapacityByCat[cat], configData.maintenanceCostParams[cat])
	end)
	
	---@class MaintenanceStatData
	---@field edgeCosts EdgeCostsByCategory
	---@field constructionMaintenance ConstructionMaintenanceByCategory
	local statData = {chargedByCategory = table_util.map(usageMultByCat, function() return 0 end)}
	--debugPrint({"Trying to charge extra maintenance costs", inflationMults})
	chargeExtraEdgeMaintenance(usageMultByCat, statData)
	chargeExtraConstructionMaintenance(configData.costMultipliers, usageMultByCat, statData)

	debugPrint({msg = "Charged Extra Maintenance", stats = statData, usageMult = usageMultByCat, rates = linesRateByCat, capacity = stationCapacityByCat,
		costMult = configData.costMultipliers, maint = configData.maintenanceCostParams})

	--[[
	local charged = statData.chargedByCategory
	local total = table_util.sum(charged)
	local mults = table_util.map(usageMultByCat, function(mult, cat) return mult * configData.costMultipliers[cat] end)
	 print(string.format("Charged extra maintenance costs. Rail: $%d, Road: $%d, Water: $%d, Air: $%d. TOTAL = $%d", charged.rail, charged.street, charged.water, charged.air, total)..
		string.format("\nFinal multipliers: Rail: %.2f, Road: %.2f, Water: %.2f, Air: %.2f", mults.rail, mults.street, mults.water, mults.air))]]
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
				chargeExtraMaintenance(configData)
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
