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

local function chargeForMaintenance(chargeAmount, carrierType, constructionType)
	chargeAmount = math.floor(chargeAmount)
	if math.abs(chargeAmount) >= 1 then
		journal_util.bookEntry(-chargeAmount, journal_util.Enum.Type.MAINTENANCE, carrierType, constructionType, 1)
	end
	return chargeAmount
end

local function chargeExtraMaintenance(mult)
	debugPrint("Trying to charge extra maintenance costs, mult = " .. mult)

	if mult > 0 then
		local costsByType = entity_util.getTotalEdgeCostsByType()
		local maintenanceByType = entity_util.getTotalConstructionMaintenanceByType()

		-- TODO: separate multipliers to balance out different types of maintenance
		local totalCharged =
			chargeForMaintenance(costsByType.street * maintenanceCostMult * mult, journal_util.Enum.Carrier.ROAD, journal_util.Enum.Construction.ROAD) +
			chargeForMaintenance(costsByType.track  * maintenanceCostMult * mult, journal_util.Enum.Carrier.RAIL, journal_util.Enum.Construction.TRACK) +

			chargeForMaintenance(maintenanceByType.street * mult, journal_util.Enum.Carrier.ROAD,  journal_util.Enum.Construction.INFRASTRUCTURE) +
			chargeForMaintenance(maintenanceByType.rail   * mult, journal_util.Enum.Carrier.RAIL,  journal_util.Enum.Construction.INFRASTRUCTURE) +
			chargeForMaintenance(maintenanceByType.water  * mult, journal_util.Enum.Carrier.WATER, journal_util.Enum.Construction.INFRASTRUCTURE) +
			chargeForMaintenance(maintenanceByType.air    * mult, journal_util.Enum.Carrier.AIR,   journal_util.Enum.Construction.INFRASTRUCTURE)

		debugPrint("Charged extra maintenance costs: " .. totalCharged)
	end
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
				local settings = getSettings()
				local extraMaintenanceMult = (settings.maintenanceMultBase * settings.getMultByYear()) - 1
				chargeExtraMaintenance(extraMaintenanceMult)
				persistentData.lastMaintenanceCharge = currentTime
			end
		end,
		guiHandleEvent = function(id, name, param)
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
