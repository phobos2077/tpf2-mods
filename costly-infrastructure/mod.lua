--[[
Costly Infrastructure Mod

Copyright (c)  2022  phobos2077  (https://steamcommunity.com/id/phobos2077)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including the right to distribute and without limitation the rights to use, copy and/or modify
the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.
--]]


local table_util = require "lib/table_util"
local config_util = require "lib/config_util"
local entity_info = require "costly_infrastructure/entity_info"
local config = require "costly_infrastructure/config"
local debugger = require "debugger"

local Category = entity_info.Category

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
				costMult = configData.costMultipliers[Category.STREET]
			elseif string.find(fileName, "/model/railroad/", 1, true) ~= nil then
				costMult = configData.costMultipliers[Category.RAIL]
			end
			cost.price = cost.price * costMult
		end
	end
	return data
end

local function trackCallback(fileName, data)
	-- debugPrint({"loadTrack", fileName, data})

	if data.cost ~= nil then
		data.cost = data.cost * configData.costMultipliers[Category.RAIL]
	end
	return data
end

local function streetCallback(fileName, data)
	--print(debugger.pretty(data, 10))

	if data ~= nil and data.cost ~= nil then
		data.cost = data.cost * configData.costMultipliers[Category.STREET]
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
	local category = entity_info.getCategoryByConstructionTypeStr(data.type)
	if category ~= nil and data.updateFn ~= nil then
		local updateFn = data.updateFn
		data.updateFn = function(params)
			local result = updateFn(params)
			local inflation = configData.inflation:get(category, params.year)
			local finalCostMultiplier = configData.costMultipliers[category] * inflation
			if result ~= nil then
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

function data()
	return {
		info = {
			minorVersion = 4,
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
			params = config_util.makeModParams(config.allParams)
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

