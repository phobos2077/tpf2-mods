--[[
Vehicle stats calculations.

Copyright (c)  2022  phobos2077  (https://steamcommunity.com/id/phobos2077)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including the right to distribute and without limitation the rights to use, copy and/or modify
the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.
--]]

local table_util = require 'lib/table_util'
local math_ex = require 'lib/math_ex'
local game_enum = require 'lib/game_enum'
local Category = (require 'costly_infrastructure/entity_info').Category

local vehicle_stats = {}

local Carrier = game_enum.Carrier
local carrierToCategory = {
	[Carrier.ROAD] = Category.STREET,
	[Carrier.TRAM] = Category.STREET,
	[Carrier.RAIL] = Category.RAIL,
	[Carrier.AIR] = Category.AIR,
	[Carrier.WATER] = Category.WATER
}

local function currentYear()
	return game.interface.getGameTime().date.year
end

local function isAvailable(year, avail)
	return avail ~= nil and
		(avail.yearFrom == 0 or year >= avail.yearFrom) and
		(avail.yearTo == 0 or year <= avail.yearTo)
end

local function getAllTransportVehicles()
	local id = 0
	local modelRes = api.res.modelRep.get(id)
	local result = {}
	while modelRes ~= nil do
		local transpData = modelRes.metadata.transportVehicle
		if transpData ~= nil then
			table.insert(result, modelRes.metadata)
		end
		id = id + 1
		modelRes = api.res.modelRep.get(id)
	end
	return result
end

local function getAllAvailableVehiclesByCategory(year)
	local allVehicles = getAllTransportVehicles()
	local result = table_util.mapDict(Category, function(cat) return cat, {} end)
	for _, metadata in pairs(allVehicles) do
		if isAvailable(year, metadata.availability) and not metadata.transportVehicle.multipleUnitOnly then
			local cat = carrierToCategory[metadata.transportVehicle.carrier]
			table.insert(result[cat], metadata)
		end
	end
	return result
end

local function getCapacity(transportVehicle)
	-- Sums capacities from all compartments.
	return table_util.sum(transportVehicle.compartments, function(comp)
		-- Finds load config with biggest capacity.
		return table_util.max(comp.loadConfigs, function(loadCfg)
			return loadCfg.cargoEntries and loadCfg.cargoEntries[1] and loadCfg.cargoEntries[1].capacity or 0
		end)
	end)
end

--- Approximates vanilla vehicle price calculation. Can't use price directly because mods might've changed it.
local function calculateVehiclePrice(metadata)
	local capacity = getCapacity(metadata.transportVehicle)

	if metadata.roadVehicle ~= nil then
		local topSpeed = metadata.roadVehicle.topSpeed
		return 1086 * capacity * (topSpeed + 0.5)
	elseif metadata.railVehicle ~= nil then
		local engines = metadata.railVehicle.engines
		local power = engines and engines[1] and engines[1].power or 0
		return 3600 * power
	elseif metadata.waterVehicle ~= nil then
		local topSpeed = metadata.waterVehicle.topSpeed
		return 1768 * capacity * (topSpeed - 2.5)
	elseif metadata.airVehicle ~= nil then
		local topSpeed = metadata.airVehicle.topSpeed
		return 1832 * capacity * (topSpeed + 10)
	end
end

local function getTopSpeed(metadata)
	local typeSpecific = metadata.roadVehicle or metadata.railVehicle or metadata.waterVehicle or metadata.airVehicle
	return typeSpecific and typeSpecific.topSpeed or nil
end

--- Vehicle score is similar to game automatic price calculation, but simpler and used to calculate vehicle-based cost multipliers.
local function calculateVehicleScore(metadata)
	local capacity = getCapacity(metadata.transportVehicle)
	local topSpeed = getTopSpeed(metadata)

	if metadata.railVehicle ~= nil then
		local engines = metadata.railVehicle.engines
		local power = engines and engines[1] and engines[1].power or 0
		return power
	else
		return capacity * topSpeed
	end
end

function vehicle_stats.calculateVehicleMultipliers(paramsByCat, year)
	local metadataByCategory = getAllAvailableVehiclesByCategory(year)
	local result = {}
	for cat, metadatas in pairs(metadataByCategory) do
		local params = paramsByCat[cat]
		local bestVehicle = table_util.max(metadatas, function(metadata) return calculateVehicleScore(metadata) end)
		local score = calculateVehicleScore(bestVehicle)

		-- This formula basically remaps whatever scaling of the vehicle score to the user-defined scaling from 1 up to mult.
		result[cat] = ((math_ex.clamp(score, params.base, params.max) / params.base) ^ params.exp - 1) /
					  ((params.max / params.base) ^ params.exp - 1) *
					  (params.mult - 1) + 1
	end
	debugPrint({"Calculated vehicle multipliers", result, paramsByCat, year})
	return result
end

function vehicle_stats.printVehicleStats()
	local allVehicles = getAllTransportVehicles()
	local carrierToStr = table_util.mapDict(game_enum.Carrier, function(v, k) return v, k end)
	print("Carrier,Name,YearFrom,YearTo,Capacity,Speed (m/s),Power (kW),Price ($)")
	for _, metadata in pairs(allVehicles) do
		local name = metadata.description and metadata.description.name or "N/A"
		local carrier = carrierToStr[metadata.transportVehicle.carrier]
		local capacity = getCapacity(metadata.transportVehicle)
		local topSpeed = getTopSpeed(metadata)
		local power = 0
		if metadata.railVehicle then
			local engines = metadata.railVehicle.engines
			power = engines and engines[1] and engines[1].power or 0
		end
		local yearFrom = metadata.availability and metadata.availability.yearFrom or -1
		local yearTo = metadata.availability and metadata.availability.yearTo or -1
		local price = metadata.cost and metadata.cost.price or -1
		print(string.format("%s,%s,%d,%d,%d,%.2f,%.2f,%d", carrier, name, yearFrom, yearTo, capacity, topSpeed, power, price))
	end
end

return vehicle_stats