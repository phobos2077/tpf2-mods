--[[
Advanced Advanced Settings mod

Copyright (c)  2022  phobos2077  (https://steamcommunity.com/id/phobos2077)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including the right to distribute and without limitation the rights to use, copy and/or modify
the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.
--]]


local config_util = require "advanced-advanced-settings/lib/config_util"
local table_util = require "advanced-advanced-settings/lib/table_util"

local actualParams

local fmt = {
	months = function(numMonths)
		return numMonths < 12
			and tostring(numMonths) .. "m"
			or tostring(math.floor(numMonths / 12)) .. "y " .. tostring(numMonths % 12) .. "m"
	end
}

local paramTypes = {
	maxNumberPerArea = function(default) return config_util.genParamLinear(nil, "SLIDER", default, {0.0, 0.1, 0.02}, {0.15, 0.40, 0.05}, {0.5, 1.5, 0.1}) end,
	timeSpanMonths = function(default, ...) return config_util.genParamLinear(fmt.months, "SLIDER", default, ...) end,
	probabilityExponent = function (default)
		local values, defaultIdx = config_util.linearValues(default, 0, 4, 1)
		local expValues = table_util.map(config_util.expValues(5, 10000, 1.5), math.floor)
		table_util.iappend(values, expValues)
		return config_util.paramType(values, defaultIdx, nil, "SLIDER")
	end,
	cargoNeeds = function(default) return config_util.genParamLinear(nil, "SLIDER", default, 0, 6, 1) end,
	absoluteMinimum = function(default) return config_util.genParamLinear(nil, "SLIDER", default, 0, 20, 1) end,
}

--[[

game.config.locations = {
		town = {
				maxNumberPerArea = 0.2,			-- km^(-2)
			    allowInRoughTerrain = false
		},
		
		industry = {
			absoluteMinimum = 5,
			maxNumberPerArea = 0.8,			    -- km^(-2)
			targetMaxNumberPerArea = 0.8,		-- km^(-2)
		},
		
		makeInitialStreets = true				-- default true, false experimental
}

game.config.economy = {
	industryDevelopment = {
		spawnTargetTimeSpan = 50 * 365.25 * 2000,
		spawnProbabilityExponent = 3.0,
		spawnIndustries = false,
		closureCountdownTimeSpan =  730.5 * 2000,
		closureProbability = 1,
	},
	townDevelopment = {
		cargoNeedsPerTown = 2,
	}
}

]]


local allParams = {
	{"locs_town_maxNumberPerArea", paramTypes.maxNumberPerArea(0.2)},
	{"locs_town_allowInRoughTerrain", config_util.checkboxParam(false)},
	{"locs_industry_maxNumberPerArea", paramTypes.maxNumberPerArea(0.8)},
	{"locs_industry_absoluteMinimum", paramTypes.absoluteMinimum(5)},
	{"locs_industry_targetMaxNumberPerArea", paramTypes.maxNumberPerArea(0.8)},
	{"locs_makeInitialStreets", config_util.checkboxParam(true)},

	{"econ_industryDevelopment_spawnTargetTimeSpan", paramTypes.timeSpanMonths(12*50, {1, 6, 1}, {9, 12*3, 3}, {12*3+6, 12*10, 6}, {12*11, 12*20, 12}, {12*25, 12*100, 12*5})},
	{"econ_industryDevelopment_spawnProbabilityExponent", paramTypes.probabilityExponent(3)},
	{"econ_industryDevelopment_spawnIndustries", config_util.checkboxParam(false)},

	{"econ_industryDevelopment_closureCountdownTimeSpan", paramTypes.timeSpanMonths(12*2, {1, 6, 1}, {9, 12*3, 3}, {12*3+6, 12*10, 6})},
	{"econ_industryDevelopment_closureProbability", paramTypes.probabilityExponent(1)},

	--{"econ_townDevelopment_cargoNeedsPerTown", paramTypes.cargoNeeds(2)},
}

function monthsToTime(numMonths)
	return numMonths * 30.4375 * 2000
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
			params = config_util.makeModParams(allParams)
		},
		runFn = function(settings, modParams)
			actualParams = config_util.getActualParams(modParams[getCurrentModId()], allParams)
		

			game.config.locations.town.maxNumberPerArea = actualParams["locs_town_maxNumberPerArea"]
			game.config.locations.town.allowInRoughTerrain = actualParams["locs_town_allowInRoughTerrain"]
			game.config.locations.industry.maxNumberPerArea = actualParams["locs_industry_maxNumberPerArea"]
			game.config.locations.industry.targetMaxNumberPerArea = actualParams["locs_industry_targetMaxNumberPerArea"]
			game.config.locations.industry.absoluteMinimum = actualParams["locs_industry_absoluteMinimum"]
			game.config.locations.makeInitialStreets = actualParams["locs_makeInitialStreets"]

			game.config.economy.industryDevelopment.spawnTargetTimeSpan = monthsToTime(actualParams["econ_industryDevelopment_spawnTargetTimeSpan"])
			game.config.economy.industryDevelopment.spawnProbabilityExponent = actualParams["econ_industryDevelopment_spawnProbabilityExponent"]
			game.config.economy.industryDevelopment.spawnIndustries = actualParams["econ_industryDevelopment_spawnIndustries"]
			game.config.economy.industryDevelopment.closureCountdownTimeSpan = monthsToTime(actualParams["econ_industryDevelopment_closureCountdownTimeSpan"])
			game.config.economy.industryDevelopment.closureProbability = actualParams["econ_industryDevelopment_closureProbability"]
			-- game.config.economy.townDevelopment.cargoNeedsPerTown = actualParams["econ_townDevelopment_cargoNeedsPerTown"]

			
			-- debugPrint({"advanced-advanced runFn", modParams, getCurrentModId(), actualParams, game.config.locations, game.config.economy})
		end
	}
end

