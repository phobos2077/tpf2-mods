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

local log_util = require "costly_infrastructure_v2/lib/log_util"
local table_util = require "costly_infrastructure_v2/lib/table_util"
local math_ex = require "costly_infrastructure_v2/lib/math_ex"
local game_enum = require "costly_infrastructure_v2/lib/game_enum"
local serialize_util = require "costly_infrastructure_v2/lib/serialize_util"
local Category = (require "costly_infrastructure_v2/enum").Category

local vehicle_stats = {}

local Carrier = game_enum.Carrier
local carrierToCategory = {
	[Carrier.ROAD] = Category.STREET,
	[Carrier.TRAM] = Category.STREET,
	[Carrier.RAIL] = Category.RAIL,
	[Carrier.AIR] = Category.AIR,
	[Carrier.WATER] = Category.WATER
}


local function isAvailable(year, yearFrom, yearTo)
	return (not yearFrom or yearFrom == 0 or year >= yearFrom) and
		(not yearTo or yearTo == 0 or year <= yearTo)
end

local function getAllTransportVehiclesFromRep()
	local numModels = #api.res.modelRep.getAll()
	local result = {}
	for id = 0, numModels - 1, 1 do
		local modelRes = api.res.modelRep.get(id)
		if modelRes.metadata and modelRes.metadata.transportVehicle then
			table.insert(result, modelRes.metadata)
		end
	end
	return result
end

local function getBestAvailableVehicleScoreByCategory(year, statsByCat)
	local result = table_util.map(statsByCat, function(vehicles)
		return table_util.max(vehicles, function(vehicle)
			local yearFrom, yearTo, score = table.unpack(vehicle)
			return isAvailable(year, yearFrom, yearTo) and score or 0
		end)
	end)
	return result
end

local function getCapacity(transportVehicle)
	-- Sums capacities from all compartments.
	return transportVehicle.compartments ~= nil
		and table_util.sum(transportVehicle.compartments, function(comp)
			-- Finds load config with biggest capacity.
			return comp.loadConfigs ~= nil
				and	table_util.max(comp.loadConfigs, function(loadCfg)
					return loadCfg.cargoEntries and loadCfg.cargoEntries[1] and loadCfg.cargoEntries[1].capacity or 0
				end)
				or 0
		end)
		or 0
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
	return typeSpecific and typeSpecific.topSpeed or 0
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

---Calculate vehicle multiplier.
---@param paramsByCat {string: VehicleMultParam}
---@param statsByCat {string: table}
---@param year number
---@return {string: number}
function vehicle_stats.calculateVehicleMultipliers(paramsByCat, statsByCat, year)
	local bestScoreByCategory = getBestAvailableVehicleScoreByCategory(year, statsByCat)
	local result = table_util.map(paramsByCat, function(params, cat)
		local score = bestScoreByCategory[cat]
		if score ~= nil and score > 0 then
			-- This formula basically remaps whatever scaling of the vehicle score to the user-defined scaling from 1 up to mult.
			return ((math_ex.clamp(score, params.base, params.max) / params.base) ^ params.exp - 1) /
						((params.max / params.base) ^ params.exp - 1) *
						(params.mult - 1) + 1
		else
			return 1
		end
	end)
	-- debugPrint({"Calculated vehicle multipliers", result, paramsByCat, year})
	return result
end

--- For saving into lua file.
function vehicle_stats.getAllVehicleAvailabilityAndScoresByCategory()
	local allVehicles = getAllTransportVehiclesFromRep()
	local result = table_util.mapDict(Category, function(cat) return cat, {} end)
	for _, metadata in pairs(allVehicles) do
		if not metadata.transportVehicle.multipleUnitOnly then
			local score = calculateVehicleScore(metadata)
			if score > 0 then
				local carrier = metadata.transportVehicle.carrier
				local cat = carrierToCategory[carrier]
				local avail = metadata.availability
				table.insert(result[cat], {
					avail and avail.yearFrom or 0,
					avail and avail.yearTo or 0,
					score
				})
			end
		end
	end
	return result
end

--- For data analysis.
function vehicle_stats.printVehicleStats()
	local allVehicles = getAllTransportVehiclesFromRep()
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

---@class VehicleMultCalculator
local Calculator = {}

---Create new instance.
---@param paramsByCat table<string, VehicleMultParam>
---@param vehicleStatsByCat table<string, number[]> Lists of vehicle stats {yearFrom,yearTo,score} by category.
---@return VehicleMultCalculator
function Calculator.new(paramsByCat, vehicleStatsByCat)
	---@class VehicleMultCalculator
	local o = {}
	---@type table<string, VehicleMultParam>
	o.paramsByCat = paramsByCat
	o.statsByCat = vehicleStatsByCat
	o.multByCat = nil
	o.multsYear = nil
	setmetatable(o, vehicle_stats.VehicleMultCalculator)

	-- debugPrint({"VehicleMultCalculator.new", o})
	return o
end

---@param self VehicleMultCalculator
function Calculator:getMultiplier(category, year)
	if not self.multByCat or not self.multsYear or self.multsYear ~= year then
		self.multByCat = vehicle_stats.calculateVehicleMultipliers(self.paramsByCat, self.statsByCat, year)
		self.multsYear = year
	end
	return self.multByCat[category]
end

Calculator.__index = Calculator

vehicle_stats.VehicleMultCalculator = Calculator


local VEHICLE_STATS_FILENAME = "_tmp_phobos2077_vehicle_stats.lua"
local FALLBACK_VEHICLE_STATS_MODULE = "costly_infrastructure_v2/fallback_vanilla_vehicles"

function vehicle_stats.generateVehicleStatsFile()
	log_util.log("Calculating vehicle stats for cost scaling...")
	local info = vehicle_stats.getAllVehicleAvailabilityAndScoresByCategory()
	local file, err = io.open(VEHICLE_STATS_FILENAME, "w")
	if file then
		log_util.log("Writing vehicle stats to "..VEHICLE_STATS_FILENAME)
		local infoStr = "return " .. serialize_util.serialize(info)
		file:write(infoStr)
		file:flush()
		file:close()
	else
		log_util.logError("Failed to save vehicle stats: " .. (err or "unknown error"))
	end
end

---Loads vehicle stats from generated lua file.
---@return table<string, number[]>
function vehicle_stats.loadVehicleStats()
	local vehicleStats
	local luaChunk, err = loadfile(VEHICLE_STATS_FILENAME, "bt", {})
	if type(luaChunk) == "function" then
		local success, result = pcall(luaChunk)
		if success then
			vehicleStats = result
		else
			err = result
		end
	end
	if type(vehicleStats) ~= "table" then
		log_util.logError("Failed to read vehicle stats from " .. VEHICLE_STATS_FILENAME .. ":\n"..err.."\nWill use vanilla vehicle stats.")
		vehicleStats = require(FALLBACK_VEHICLE_STATS_MODULE)
	end
	return vehicleStats
end

return vehicle_stats