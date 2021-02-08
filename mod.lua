local util = require "costly_infrastructure/util"
local config = require "costly_infrastructure/config"


---@type ConfigObject
local configData = nil

local loadedModules = {}

local function trackCallback(fileName, data)
	-- debugPrint({"loadTrack", fileName})

	if data.cost ~= nil then
		data.cost = data.cost * configData.costMultipliers.track
	end
	return data
end

local function bridgeCallback(fileName, data)
	-- debugPrint({"loadBridge", fileName, data})
	-- api.cmd.sendCommand(api.cmd.make.sendScriptEvent("mod.lua", "loadBridge", fileName, data))
	if data.cost ~= nil then
		data.cost = data.cost * configData.costMultipliers.bridge
	end
	return data
end

local function tunnelCallback(fileName, data)
	if data.cost ~= nil then
		data.cost = data.cost * configData.costMultipliers.tunnel
	end
	return data
end

local function streetCallback(fileName, data)
	--print(debugger.pretty(data, 10))

	if data ~= nil and data.cost ~= nil then
		data.cost = data.cost * configData.costMultipliers.street
	end
	return data
end

local function getModuleBasePrice(moduleName)
	local modulePath = "res/construction/" .. moduleName
	local price = 0
	if loadedModules[modulePath] ~= nil and loadedModules[modulePath].cost ~= nil and loadedModules[modulePath].cost.price ~= nil then
		price = loadedModules[modulePath].cost.price
	end
	return price
end

local function moduleTotalPrice(modules)
	local sum = 0
	if modules ~= nil then
		for id, data in pairs(modules) do
			sum = sum + getModuleBasePrice(data.name)
		end
	end
	return sum
end

local function constructionCallback(fileName, data)
	-- print(debugger.pretty({fileName, data.type, data.cost}, 10))

	if data.updateFn ~= nil then
		local updateFn = data.updateFn
		data.updateFn = function(params)
			local result = updateFn(params)
			if result ~= nil then
				result.baseCost = result.cost or 0
				if result.cost ~= nil then
					result.cost = result.baseCost * configData:getConstructionInflation(params.year)
				end
			end

			-- debugPrint({"constr updateFn", fileName, params})
			return result
		end
	end

	return data
end

local function moduleCallback(fileName, data)

	-- debugPrint({"loadModule", fileName, data.cost and data.cost.price})

	loadedModules[fileName] = data

	if data.updateFn ~= nil then
		local updateFn = data.updateFn
		data.updateFn = function(result, transform, tag, slotId, addModelFn, params)
			updateFn(result, transform, tag, slotId, addModelFn, params)

			local moduleBaseCost = getModuleBasePrice(params.modules[slotId].name)
			params.modules[slotId].metadata.price = moduleBaseCost * (configData:getConstructionInflation(params.year) - 1)
			result.baseCost = (result.baseCost or 0) + moduleBaseCost

			-- debugPrint({"module updateFn", params.modules[slotId].name, params.modules[slotId].metadata.price})

			return result
		end
	end

	return data
end

function data()
	return {
		info = {
			minorVersion = 0,
			severityAdd = "NONE",
			severityRemove = "NONE",
			name = _("mod name"),
			description = _("mod desc"),
			tags = { "Script Mod" },
			authors = {
				{
					name = "phobos2077",
					role = "CREATOR",
					text = "",
					steamProfile = "76561198025571704",
				},
			},
			params = {
			},
		},
		runFn = function (settings, modParams)
			configData = config.createFromParams(modParams)

			addModifier("loadTrack", trackCallback)
			addModifier("loadBridge", bridgeCallback)
			addModifier("loadTunnel", tunnelCallback)
			addModifier("loadStreet", streetCallback)
			addModifier("loadModule", moduleCallback)
			addModifier("loadConstruction", constructionCallback)

			-- terrain change per m^3
			game.config.costs.terrainRaise = .75 * 18  -- original: .75 * 6.0,
			game.config.costs.terrainLower = .75 * 14  -- original: .75 * 7.0,

			-- fraction of road/track cost
			game.config.costs.railroadCatenary = configData.costMultipliers.railroadCatenary
			game.config.costs.roadTramLane = configData.costMultipliers.roadTramLane
			game.config.costs.roadElectricTramLane = configData.costMultipliers.roadElectricTramLane

			-- game.config.costs.removeField = game.config.costs.removeField * configData.costMultipliers.bulldoze_field -- original: 200000.0

			local constr = game.config.ConstructWithModules
			game.config.ConstructWithModules = function(params)
				local result = constr(params)
				-- result.cost = (result.cost + moduleTotalPrice(params.constrParams.modules)) * getMultByYear(params.year)

				-- emulating vanilla maintenance based on non-modified costs
				result.maintenanceCost = result.baseCost / 120

				-- debugPrint({"Construct", result.cost, result.baseCost, result.maintenanceCost})

				return result
			end
		end,
		postRunFn = function(settings, params)
		end
	}
end

