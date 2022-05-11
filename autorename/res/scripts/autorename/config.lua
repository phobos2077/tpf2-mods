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

local table_util = require "autorename/lib/table_util"
local config_util = require "autorename/lib/config_util"

---@class ConfigClass
local config = {}

local paramTypes = {
}

local separatorValues = {
	{" ", "XXX 111"},
	{"", "XXX111"},
	{"-", "XXX-111"},
	{" - ", "XXX - 111"},
	{"/", "XXX/111"},
	{" / ", "XXX / 111"},
	{" #", "XXX #111"},
}

local numDigitsValues = {
	{false, _("value auto")},
	{1, "1"},
	{2, "01"},
	{3, "001"},
	{4, "0001"},
}

local allParams = {
	--{"enable_vehicles", paramTypes.toggle},
	{"vehicle_add_type", config_util.checkboxParam(true)},
	{"vehicle_num_separator", config_util.comboBoxParam(separatorValues)},
	{"vehicle_num_digits", config_util.comboBoxParam(numDigitsValues, 2)},
	{"vehicle_move_line_num", config_util.checkboxParam(false)},
	{"skip_brackets_square", config_util.checkboxParam(false)},
	{"skip_brackets_curly", config_util.checkboxParam(false)},
	{"skip_brackets_angled", config_util.checkboxParam(false)},
}

---@param params number[]
local function getDataFromParams(params)
	---@class ConfigObject : ConfigClass
	local o = {
		---@type boolean
		renameStations = false, -- TODO
		---@class VehicleRenameConfig
		vehicles = {
			enable = true, -- params.enable_vehicles,
			---@type boolean
			addType = params.vehicle_add_type,
			---@type string
			numberSeparator = params.vehicle_num_separator,
			---@type number
			numDigits = params.vehicle_num_digits,
			---@type boolean
			moveLineNumber = params.vehicle_move_line_num,
			---@class NameFilteringParams
			nameFiltering = {
				skipBrackets = {
					---@type boolean
					square = params.skip_brackets_square,
					---@type boolean
					curly = params.skip_brackets_curly,
					---@type boolean
					angled = params.skip_brackets_angled,
				}
			}
		}
	}
	return o
end

--- Gets mod config object.
---@return ConfigObject
function config.get()
	return game.config.phobos2077.autorename
end

config.__index = config

config.allParams = allParams

--- Create and set mod params. Only call from mod.lua's runFn.
---@param rawParams table<string, number> Mod parameters as indexes to actual values in values table.
---@return ConfigObject Config instance.
function config.createFromParams(rawParams)
	-- debugPrint({"createFromParams", rawParams})
	local o = getDataFromParams(config_util.getActualParams(rawParams, allParams))
	setmetatable(o, config)

	game.config.phobos2077 = game.config.phobos2077 or {}
	game.config.phobos2077.autorename = o
	return o
end

---@type ConfigClass
return config