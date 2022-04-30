--[[
Mod config.

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
local config_util= require "lib/config_util"

---@class ConfigClass
local config = {}



local fmt = config_util.fmt

local paramTypes = {
	--bracketRateStep = function(default) return genParamTypeLinear(0.05, 0.20, 0.25, default or 1, fmt.percent) end,
}
local k = 1000
local mil = 1000*1000
local allParams = {
	{"bracket_rate_step", config_util.paramType({0.05, 0.10, 0.20}, 2, fmt.percent, "BUTTON")},
	{"bracket_rate_min", config_util.genParamTypeLinear(0.00, 0.20, 0.05, 0.00, fmt.percent)},
	{"bracket_rate_max", config_util.genParamTypeLinear(0.40, 0.95, 0.05, 0.60, fmt.percent)},
	{"bracket_top_max", config_util.genParamTypeExp(10*mil, 160*mil, 2, 40*mil, fmt.moneyShort)},
}

local function generateTaxBrackets(params)
	local brackets = {}
	local numBrackets = math.floor((params.bracket_rate_max - params.bracket_rate_min) / params.bracket_rate_step) + 1
	local bracketSize = params.bracket_top_max / (numBrackets - 1)
	for i = 1, numBrackets do
		local bracketRate = params.bracket_rate_min + params.bracket_rate_step*(i-1)
		local bracketTop = i < numBrackets and bracketSize * i or nil
		brackets[i] = {bracketRate, bracketTop}
	end
	return brackets
end

local function getDataFromParams(params)
	-- debugPrint({"getDataFromParams", params})
	---@class ConfigObject : ConfigClass
	local o = {}
	o.taxBrackets = generateTaxBrackets(params)
	return o
end

--- Gets mod config object.
---@return ConfigObject
function config.get()
	return game.config.phobos2077.incomeTax
end

config.__index = config

config.allParams = allParams

--- Create and set mod params. Only call from mod.lua's runFn.
---@param rawParams table Mod parameters as indexes to actual values in values table.
---@return ConfigObject Config instance.
function config.createFromParams(rawParams)
	local o = getDataFromParams(config_util.getActualParams(rawParams, allParams))
	setmetatable(o, config)

	game.config.phobos2077 = game.config.phobos2077 or {}
	game.config.phobos2077.incomeTax = o
	return o
end

function config.getModParams()
	return config_util.makeModParams(allParams)
end

---@type ConfigClass
return config