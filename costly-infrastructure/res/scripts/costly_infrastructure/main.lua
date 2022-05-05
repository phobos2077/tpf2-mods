local table_util = require "costly_infrastructure/lib/table_util"
local serialize_util = require "costly_infrastructure/lib/serialize_util"
local entity_info = require "costly_infrastructure/entity_info"
local config = require "costly_infrastructure/config"
local debugger = require "debugger"
local vehicle_stats = require "costly_infrastructure/vehicle_stats"

local Category = (require "costly_infrastructure/enum").Category

local VEHICLE_STATS_FILENAME = "phobos2077_vehicle_stats.lua"

---@type ConfigObject
local configData = nil

local loadedModuleCosts = {}

---@type VehicleMultCalculator
local vehicleMultCalculator = nil

local function getModuleBaseCost(moduleName)
	local modulePath = "res/construction/" .. moduleName
	local price = 0
	if loadedModuleCosts[modulePath] ~= nil then
		price = loadedModuleCosts[modulePath]
	end
	return price
end

---@return VehicleMultCalculator
local function getVehicleMultCalculator()
	if vehicleMultCalculator == nil then
        local vehicleStats = dofile(VEHICLE_STATS_FILENAME)
        vehicleMultCalculator = vehicle_stats.VehicleMultCalculator.new(configData.vehicleMultParams, vehicleStats)
    end
    return vehicleMultCalculator
end

local function modelModifier(fileName, data)
    -- Modify costs of signals and waypoints based on street/rail multiplier.
	if data.metadata ~= nil and data.metadata.signal ~= nil then
		local cost = data.metadata.cost
		if cost ~= nil and cost.price ~= nil then
			local costMult = 1
			if string.find(fileName, "/model/street/", 1, true) ~= nil then
				costMult = configData.costMultipliers[Category.STREET]
			elseif string.find(fileName, "/model/railroad/", 1, true) ~= nil then
				costMult = configData.costMultipliers[Category.RAIL]
			end
			cost.price = cost.price * costMult
		end
	end
	return data
end

local function trackModifier(fileName, data)
	-- debugPrint({"loadTrack", fileName, data})

	if data.cost ~= nil then
		data.cost = data.cost * configData.costMultipliers[Category.RAIL]
	end
	return data
end

local function streetModifier(fileName, data)
	--print(debugger.pretty(data, 10))

	if data ~= nil and data.cost ~= nil then
		data.cost = data.cost * configData.costMultipliers[Category.STREET]
	end
	return data
end

local function bridgeModifier(fileName, data)
	--debugPrint({"loadBridge", fileName, data})

	if data.cost ~= nil then
		data.cost = data.cost * configData.costMultipliers.bridge
	end
	return data
end

local function tunnelModifier(fileName, data)
	--debugPrint({"loadTunnel", fileName, data})
	if data.cost ~= nil then
		data.cost = data.cost * configData.costMultipliers.tunnel
	end
	return data
end


local function constructionUpdate(params, result, category)
	local vehicleMult = getVehicleMultCalculator():getMultiplier(category, params.year)
	local finalCostMultiplier = configData.costMultipliers[category] * vehicleMult
	local baseCost = result.cost or 0
	if result.cost ~= nil then
		result.cost = baseCost * finalCostMultiplier
	end
	if params.modules ~= nil then
		for _, mod in pairs(params.modules) do
			local moduleBaseCost = getModuleBaseCost(mod.name)
			-- Metadata price is applied on top of original price, so we need to subtract base price to avoid over-pricing.
			mod.metadata.price = moduleBaseCost * (finalCostMultiplier - 1)
			if mod.metadata.price < 0 then
				mod.metadata.price = 0
			end
			-- This doesn't work:
			-- mod.metadata.bulldozePrice = inflatedPrice * game.config.costs.bulldozeRefundFactor

			baseCost = baseCost + moduleBaseCost
		end
	end

	-- Emulating vanilla maintenance based on non-modified costs.
	-- This is needed for dynamic maintenance costs calculations to work properly.
	result.maintenanceCost = baseCost / 120
end

local function constructionModifier(fileName, data)
	-- debugPrint({"loadConstruction", fileName, data})
	local category = entity_info.getCategoryByConstructionTypeStr(data.type)
	if category ~= nil and data.updateFn ~= nil then
		local updateFn = data.updateFn
		data.updateFn = function(params)
			local result = updateFn(params)
			if result ~= nil then
				constructionUpdate(params, result, category)
			end
			-- debugPrint({"constr updateFn", fileName, params})
			return result
		end
	end

	return data
end

local function moduleModifier(fileName, data)
	-- debugPrint({"loadModule", fileName, data.cost})
	loadedModuleCosts[fileName] = data.cost and data.cost.price or nil

	return data
end

local function changeGameConfigCosts(gameCosts, configData)
    -- terrain change per m^3
    gameCosts.terrainRaise = gameCosts.terrainRaise * configData.costMultipliers.terrain
    gameCosts.terrainLower = gameCosts.terrainLower * configData.costMultipliers.terrain

    -- fraction of road/track cost
    gameCosts.railroadCatenary = gameCosts.railroadCatenary * configData.costMultipliers.trackUpgrades
    gameCosts.roadTramLane = gameCosts.roadTramLane * configData.costMultipliers.streetUpgrades
    gameCosts.roadElectricTramLane = gameCosts.roadElectricTramLane * configData.costMultipliers.streetUpgrades
    gameCosts.roadBusLane = gameCosts.roadBusLane * configData.costMultipliers.streetUpgrades

    -- gameCosts.removeField = gameCosts.removeField * configData.costMultipliers.removeField -- original: 200000.0
end



local main = {}
function main.runFn(settings, modParams)
    configData = config.createFromParams(modParams[getCurrentModId()])

    -- debugPrint({"runFn", modParams, getCurrentModId(), configData})

    addModifier("loadModel", modelModifier)
    addModifier("loadTrack", trackModifier)
    addModifier("loadBridge", bridgeModifier)
    addModifier("loadTunnel", tunnelModifier)
    addModifier("loadStreet", streetModifier)
    addModifier("loadModule", moduleModifier)
    addModifier("loadConstruction", constructionModifier)

    changeGameConfigCosts(game.config.costs, configData)
end

function main.postRunFn(settings, params)
	-- debugPrint({"postRunFn", settings, params})

	-- Have to save vehicle info to file, because this is the only way to pass data into a ConstructWithModules function.
	local info = vehicle_stats.getAllVehicleAvailabilityAndScoresByCategory()
	local file = io.open(VEHICLE_STATS_FILENAME, "w")
	if file then
		local infoStr = "return " .. serialize_util.serialize(info)
		file:write(infoStr)
		file:flush()
		file:close()
	else
		print("! ERROR ! Failed to save vehicle stats!")
	end
end

return main