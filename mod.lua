local util = require "costly_infrastructure/util"
local entity_util = require "costly_infrastructure/entity_util"
local config = require "costly_infrastructure/config"
local debugger = require "debugger"


---@type ConfigObject
local configData = nil

local loadedModuleCosts = {}

local function modelCallback(fileName, data)
	if data.metadata ~= nil and data.metadata.signal ~= nil then
		-- debugPrint({"loadModel", fileName, data})
		local cost = data.metadata.cost
		if cost ~= nil and cost.price ~= nil then
			local costMult = 1
			if string.find(fileName, "/model/street/", 1, true) ~= nil then
				costMult = configData.inflation:getBaseMult("street")
			elseif string.find(fileName, "/model/railroad/", 1, true) ~= nil then
				costMult = configData.inflation:getBaseMult("rail")
			end
			cost.price = cost.price * costMult
		end
	end
	return data
end

local function trackCallback(fileName, data)
	-- debugPrint({"loadTrack", fileName, data})

	if data.cost ~= nil then
		data.cost = data.cost * configData.inflation:getBaseMult("rail")
	end
	return data
end

local function streetCallback(fileName, data)
	--print(debugger.pretty(data, 10))

	if data ~= nil and data.cost ~= nil then
		data.cost = data.cost * configData.inflation:getBaseMult("street")
	end
	return data
end

local function bridgeCallback(fileName, data)
	--debugPrint({"loadBridge", fileName, data})

	if data.cost ~= nil then
		data.cost = data.cost * configData.costMultipliers.bridge
	end
	return data
end

local function tunnelCallback(fileName, data)
	--debugPrint({"loadTunnel", fileName, data})
	if data.cost ~= nil then
		data.cost = data.cost * configData.costMultipliers.tunnel
	end
	return data
end

local function getModuleBaseCost(moduleName)
	local modulePath = "res/construction/" .. moduleName
	local price = 0
	if loadedModuleCosts[modulePath] ~= nil then
		price = loadedModuleCosts[modulePath]
	end
	return price
end

local function constructionCallback(fileName, data)
	-- debugPrint({"loadConstruction", fileName, data})
	local category = entity_util.getCategoryByConstructionTypeStr(data.type)
	if category ~= nil and data.updateFn ~= nil then
		local updateFn = data.updateFn
		data.updateFn = function(params)
			local result = updateFn(params)
			local inflation = configData.inflation:get(category, params.year)
			if result ~= nil then
				local baseCost = result.cost or 0
				if result.cost ~= nil then
					result.cost = baseCost * inflation
				end
				if params.modules ~= nil then
					for _, mod in pairs(params.modules) do
						local moduleBaseCost = getModuleBaseCost(mod.name)
						local inflatedPrice = moduleBaseCost * inflation
						-- Metadata price is applied on top of original price, so we need to subtract base price to avoid over-pricing.
						mod.metadata.price = inflatedPrice - moduleBaseCost
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

			--debugPrint({"constr updateFn", fileName, category, params.year, params.modules, inflation, result.cost, result.maintenanceCost})
			return result
		end
	end

	return data
end

local function moduleCallback(fileName, data)
	-- debugPrint({"loadModule", fileName, data.cost})
	loadedModuleCosts[fileName] = data.cost and data.cost.price or nil

	return data
end

---Generate param info for mod settings.
---@param key string
---@param paramData ParamTypeData
---@return table
local function makeParamInfo(key, paramData)
	return {
		key = key,
		name = _("param "..key),
		tooltip = _("param "..key.." tip"),
		uiType = "SLIDER",
		values = paramData.labels,
		defaultIndex = paramData.defaultIdx
	}
end

function data()
	return {
		info = {
			minorVersion = 2,
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
			params = util.map(config.allParams, function(data)
				return makeParamInfo(data[1], data[2])
			end)
		},
		runFn = function (settings, modParams)
			configData = config.createFromParams(modParams[getCurrentModId()])

			-- debugPrint({"runFn", modParams, getCurrentModId(), configData})

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
			game.config.costs.railroadCatenary = game.config.costs.railroadCatenary * configData.costMultipliers.trackUpgrades
			game.config.costs.roadTramLane = game.config.costs.roadTramLane * configData.costMultipliers.streetUpgrades
			game.config.costs.roadElectricTramLane = game.config.costs.roadElectricTramLane * configData.costMultipliers.streetUpgrades
			game.config.costs.roadBusLane = game.config.costs.roadBusLane * configData.costMultipliers.streetUpgrades

			-- game.config.costs.removeField = game.config.costs.removeField * configData.costMultipliers.removeField -- original: 200000.0
		end,
		postRunFn = function(settings, params)
		end
	}
end

