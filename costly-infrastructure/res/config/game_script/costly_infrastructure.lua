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
local vehicle_stats = require "costly_infrastructure_v2/vehicle_stats"
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

local vehicleMultCalculator

---@return VehicleMultCalculator
local function getVehicleMultCalculator()
	if vehicleMultCalculator == nil then
		vehicleMultCalculator = vehicle_stats.VehicleMultCalculator.new(config.get().vehicleMultParams, vehicle_stats.loadVehicleStats())
	end
	return vehicleMultCalculator
end


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
---@param costMultipliers StaticCostMultipliers
---@param usageByCategory table
---@param statData table
local function chargeExtraEdgeMaintenance(costMultipliers, usageByCategory, statData)
	local costByCat
	for cat, constructionType in pairs(edgeCategoryToConstruction) do
		-- Because bridges and tunnels use separate cost multiplier, we need to correct for this by re-applying category-specific multiplier.
		local bridgeCorrectionMult = costMultipliers[cat] / costMultipliers.bridge
		local tunnelCorrectionMult = costMultipliers[cat] / costMultipliers.tunnel

		-- Subtract 1 from dynamic multipliers to account for maintenance charged by game engine.
		local usageMult = usageByCategory[cat]
		local edgeMult = math.max(usageMult - 1, 0)
		local bridgeMult = math.max(usageMult * bridgeCorrectionMult - 1, 0)
		local tunnelMult = math.max(usageMult * tunnelCorrectionMult - 1, 0)

		if edgeMult > 0 or bridgeMult > 0 or tunnelMult > 0 then
			costByCat = costByCat or entity_costs.getTotalEdgeCostsByCategory()
			local costData = costByCat[cat]

			-- Multiply by vanilla 1/120 cost-to-maintenance ratio.
			local chargedAmount = (costData.edge*edgeMult + costData.bridge*bridgeMult + costData.tunnel*tunnelMult) * config.vanillaMaintenanceCostMult

			chargedAmount = chargeForMaintenance(chargedAmount, categoryToCarrier[cat], constructionType)
			table_util.incInTable(statData.chargedByCategory, cat, chargedAmount)
		end
	end
	statData.edgeCosts = costByCat
end

--- Charge extra maintenance for all constructions (stations, depos).
---@param costMultipliers table
---@param usageByCategory table
---@param statData table
local function chargeExtraConstructionMaintenance(costMultipliers, usageByCategory, statData)
	local maintenanceByType
	for cat, usageMult in pairs(usageByCategory) do
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
	---@field edgeCosts EdgeCostData
	---@field constructionMaintenance ConstructionMaintenanceByCategory
	local statData = {chargedByCategory = table_util.map(usageMultByCat, function() return 0 end)}
	--debugPrint({"Trying to charge extra maintenance costs", inflationMults})
	chargeExtraEdgeMaintenance(configData.costMultipliers, usageMultByCat, statData)
	chargeExtraConstructionMaintenance(configData.costMultipliers, usageMultByCat, statData)

	-- debugPrint({msg = "Charged Extra Maintenance", stats = statData, usageMult = usageMultByCat, rates = linesRateByCat, capacity = stationCapacityByCat,
	-- 	costMult = configData.costMultipliers, maint = configData.maintenanceCostParams})

	local charged = statData.chargedByCategory
	local total = table_util.sum(charged)
	local mults = table_util.map(usageMultByCat, function(mult, cat) return mult * configData.costMultipliers[cat] end)
	 print(string.format("Charged extra maintenance costs. Rail: $%d, Road: $%d, Water: $%d, Air: $%d. TOTAL = $%d", charged.rail, charged.street, charged.water, charged.air, total)..
		string.format("\nFinal multipliers: Rail: %.2f, Road: %.2f, Water: %.2f, Air: %.2f", mults.rail, mults.street, mults.water, mults.air))
end

local function bookExtraBuildCosts(amount, carrier, construction)
	print(string.format("Charge extra for construction: %d, carrier: %d, constr: %d", amount, carrier, construction))
	journal_util.bookEntry(-amount, journal_util.Enum.Type.CONSTRUCTION, carrier, construction, 0, 0)
end


local guiState = {}

local noSpam = false

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
			-- if id ~= "constructionBuilder" then
			-- 	debugPrint({"guiHandleEvent", id, name, param})
			-- end
			
			-- Track, road, signal, waypoint, road station: build costs scaling.
			if (id == "trackBuilder" or id == "streetBuilder" or id == "streetTerminalBuilder") and
				(name == "builder.proposalCreate" or name == "builder.apply") and
				config.get().scaleEdgeCosts then

				-- if name == "builder.apply" then
				-- 	debugPrint({"builder apply", param})
				-- end
				local addedSegments = param.proposal.proposal.addedSegments
				if #addedSegments > 0 then
					local category = addedSegments[1].type == 1 and Category.RAIL or Category.STREET
					local mult = getVehicleMultCalculator():getMultiplier(category, game.interface.getGameTime().date.year)
					if name == "builder.apply" then
						-- debugPrint({"apply", param.data.costs, category, game.interface.getGameTime().date.year, mult})
						if mult > 1 then
							local carrier = category == Category.RAIL
								and journal_util.Enum.Carrier.RAIL
								or journal_util.Enum.Carrier.ROAD
							local construction = category == Category.RAIL
								and journal_util.Enum.Construction.TRACK
								or journal_util.Enum.Construction.STREET
							bookExtraBuildCosts(math.floor(param.data.costs * (mult - 1)), carrier, construction)
						end
					end
					param.data.costs = math.floor(param.data.costs * mult)
				end
			end
		end,
		handleEvent = function(src, id, name, param)
			-- if src ~= "guidesystem.lua" then
			-- 	debugPrint({"handleEvent", src, id, name, param})
			-- end

			-- Support for Auto-Parallel Tracks and AutoSig mods.
			if (id == "__ptracks__" or id == "__autosig2__") and name == "costs" and param.costs and config.get().scaleEdgeCosts then
				local mult = getVehicleMultCalculator():getMultiplier(Category.RAIL, game.interface.getGameTime().date.year)
				if mult > 1 then
					local constr = (id == "__ptracks__")
						and journal_util.Enum.Construction.TRACK
						or journal_util.Enum.Construction.SIGNAL
						
					bookExtraBuildCosts(math.floor(param.costs * (mult - 1)), journal_util.Enum.Carrier.RAIL, constr)
				end
			end
		end
	}
end
