local util = require "costly_infrastructure/util"
local config = require "costly_infrastructure/config"
local debugger = require "debugger"


---@type ConfigObject
local configData = nil

local loadedModules = {}

local function modelCallback(fileName, data)
	if data.metadata ~= nil and data.metadata.signal ~= nil then
		debugPrint({"loadModel", fileName, data})
		local cost = data.metadata.cost
		if cost ~= nil and cost.price ~= nil then
			local costMult = 1
			if string.find(fileName, "/model/street/", 1, true) ~= nil then
				costMult = configData.costMultipliers.street
			elseif string.find(fileName, "/model/railroad/", 1, true) ~= nil then
				costMult = configData.costMultipliers.track
			end
			cost.price = cost.price * costMult
		end
		local origUpdateFn = data.metadata.updateFn
		data.metadata.updateFn = function(data, ...)
			if (origUpdateFn ~= nil) then
				origUpdateFn(data, ...)
			end
			debugPrint({"model UpdateFn", data})
		end
	end
	return data
end

local function trackCallback(fileName, data)
	-- debugPrint({"loadTrack", fileName, data})

	if data.cost ~= nil then
		data.cost = data.cost * configData.costMultipliers.track
	end
	data.updateFn = function(data)
		debugPrint({"track UpdateFn", data})
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
	-- debugPrint({"loadConstruction", fileName, data})

	if data.updateFn ~= nil then
		local updateFn = data.updateFn
		data.updateFn = function(params)
			local result = updateFn(params)
			if result ~= nil then
				result.baseCost = result.cost or 0
				if result.cost ~= nil then
					result.cost = result.baseCost * configData:getInflation(params.year)
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
			params.modules[slotId].metadata.price = moduleBaseCost * (configData:getInflation(params.year) - 1)
			result.baseCost = (result.baseCost or 0) + moduleBaseCost

			-- debugPrint({"module updateFn", params.modules[slotId].name, params.modules[slotId].metadata.price})

			return result
		end
	end

	return data
end

local function makeParamValuesForMult(min, max, step)
	local values = {}
	local paramToMult = {}
	local i = 0
	for v = min, max, step do
		paramToMult[i] = v
		values[i + 1] = math.floor(v * 100) .. "%"
		i = i + 1
	end
	return paramToMult, values
end

function data()
	local paramToCostMult, costMultParamValues = makeParamValuesForMult(1, 4, 0.5)
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
				{
					key = "mult_edge_cost",
					name = _("param edge cost"),
					uiType = "SLIDER",
					values = costMultParamValues,
					defaultIndex = 0,
					-- tooltip = _("brutal recommended")
				},
				{
					key = "mult_constr_cost",
					name = _("param constr cost"),
					uiType = "SLIDER",
					values = costMultParamValues,
					defaultIndex = 0,
					-- tooltip = _("brutal recommended")
				}
			},
		},
		runFn = function (settings, modParams)
			configData = config.createFromParams(modParams[getCurrentModId()], paramToCostMult)

			addModifier("loadModel", modelCallback)
			addModifier("loadTrack", trackCallback)
			addModifier("loadBridge", bridgeCallback)
			addModifier("loadTunnel", tunnelCallback)
			addModifier("loadStreet", streetCallback)
			addModifier("loadModule", moduleCallback)
			addModifier("loadConstruction", constructionCallback)

			-- terrain change per m^3
			game.config.costs.terrainRaise = game.config.costs.terrainRaise * configData.costMultipliers.terrain
			game.config.costs.terrainLower = game.config.costs.terrainLower * configData.costMultipliers.terrain

			-- fraction of road/track cost
			-- game.config.costs.railroadCatenary = configData.costMultipliers.railroadCatenary
			-- game.config.costs.roadTramLane = configData.costMultipliers.roadTramLane
			-- game.config.costs.roadElectricTramLane = configData.costMultipliers.roadElectricTramLane

			-- game.config.costs.removeField = game.config.costs.removeField * configData.costMultipliers.removeField -- original: 200000.0

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

