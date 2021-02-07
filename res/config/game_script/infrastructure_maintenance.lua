local journal_util = require 'costly_infrastructure/journal_util'
local entity_util = require 'costly_infrastructure/entity_util'
local util = require 'costly_infrastructure/util'
local debug = require 'costly_infrastructure/debug'

local persistentData = {}

-- Vanilla multiplier of maintenance costs based on construction costs.
local maintenanceCostMult = 1/120

local function getSettings()
	return game.config.phobos2077.costlyInfrastructure
end

local function upgradeCosts()
	local entities = game.interface.getEntities({ radius = 1e100 }, { type = "CONSTRUCTION" })
	print("Trying to upgrade costs, found " .. #entities ..  " entities...")
	for j = 1, #entities do
		local id = entities[j]
		local maintenanceCost = api.engine.getComponent(id, api.type.ComponentType.MAINTENANCE_COST)
		local e = game.interface.getEntity(id)
		local conparams = e.params
		conparams.seed = nil
		if maintenanceCost ~= nil and #(e.townBuildings or {}) == 0 then
			print("Upgrading " .. e.name ..  " (" .. id .. ")")
			game.interface.upgradeConstruction(id, e.fileName, conparams)
		end
	end
end

local function chargeMaintenanceBasedOnCost(mult, cost, carrierType, constructionType)
	local chargeAmount = cost * maintenanceCostMult * mult
	journal_util.bookEntry(-chargeAmount, journal_util.Enum.Type.MAINTENANCE, carrierType, constructionType, 1)
	return chargeAmount
end

local function chargeExtraMaintenance(mult)
	debugPrint("Trying to charge extra maintenance costs, mult = " .. mult)

	if mult > 0 then
		local costsByType = entity_util.getTotalEdgeCostsByType()
		local totalCharged =
			chargeMaintenanceBasedOnCost(mult, costsByType.street, journal_util.Enum.Carrier.ROAD, journal_util.Enum.Construction.ROAD) +
			chargeMaintenanceBasedOnCost(mult, costsByType.track, journal_util.Enum.Carrier.RAIL, journal_util.Enum.Construction.TRACK)

		debugPrint("Charged extra maintenance costs: " .. totalCharged)
	end
end

--[[ 
local loadedBridges = {}
local function getBridgeCostFactors(bridgeName)
	if loadedBridges[bridgeName] == nil then
		local fileName = "./res/config/bridge/" .. bridgeName
		local env = {}
		setmetatable(env, {__index=_G})
		local bridgeFunc = loadfile(fileName, "bt", env)
		if type(bridgeFunc) == "function" then
			bridgeFunc()
			if type(env.data) == "function" then
				loadedBridges[bridgeName] = env.data()
				debugPrint(loadedBridges[bridgeName])
			else
				print("Incorrect bridge script: " .. fileName)	
			end
		else
			print("Error loading bridge: " .. fileName)
		end
	end

	return loadedBridges[bridgeName] and loadedBridges[bridgeName].costFactors
end ]]

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
			-- if lastUpgradeAt == 0 then
			-- 	lastUpgradeAt = currentTime
			-- end
			-- if currentTime > lastUpgradeAt + 30 then
			-- 	upgradeCosts()
			-- 	lastUpgradeAt = currentTime
			-- end

			local chargeInterval = game.config.chargeMaintenanceInterval
			if persistentData.lastMaintenanceCharge == nil then
				-- Make sure extra maintenance charge is always calculated 1 second after regular maintenance
				persistentData.lastMaintenanceCharge = math.floor(currentTime / chargeInterval) * chargeInterval + 1
			end
			if currentTime > persistentData.lastMaintenanceCharge + chargeInterval then
				local settings = getSettings()
				local extraMaintenanceMult = (settings.maintenanceMultBase * settings.getMultByYear()) - 1
				chargeExtraMaintenance(extraMaintenanceMult)
				persistentData.lastMaintenanceCharge = currentTime
			end
		end,
		guiHandleEvent = function(id, name, param)
			-- debugPrint({"guiHandleEvent", id, name, param})
			if id == "trackBuilder" then
				-- if name == "builder.proposalCreate" or name == "builder.apply" then
				-- 	param.data.costs = param.data.costs * 10
				-- end
			end
		end,
		handleEvent = function(src, id, name, param)
			if src ~= "guidesystem.lua" then
				debugPrint({"handleEvent", src, id, name, param})
			end

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
