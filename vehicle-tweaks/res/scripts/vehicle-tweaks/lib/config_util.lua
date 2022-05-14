--[[
Mod Configuration utilities.
Version: 1.2

Copyright (c)  2022  phobos2077  (https://steamcommunity.com/id/phobos2077)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including the right to distribute and without limitation the rights to use, copy and/or modify
the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.
--]]

local config_util = {}

config_util.fmt = {
	percent = function(v)
		return string.format("%.0f%%", v * 100)
	end,
	timesX = function(v)
		return string.format("%.1fx", v)
	end,
	money = function(v)
		local k = 1000
		local str = ""
		v = math.floor(v)
		while v >= k do
			str = string.format(",%03d", v % k) .. str
			v = math.floor(v / k)
		end
		return "$"..v..str
	end,
	moneyShort = function(v)
		local k = 1000
		local mil = k*k
		local bil = mil*k
		local postfix = ""
		if v >= bil then
			v = v/bil
			postfix = "b"
		elseif v >= mil then
			v = v/mil
			postfix = "m"
		elseif v >= k then
			v = v/k
			postfix = "k"
		end
		return string.format("$%.0f%s", v, postfix)
	end,
}

---Creates ParamTypeData.
---@param values {[1]:any,[2]:string|nil}|any[] List of values or table-pairs of {value, label}.
---@par7am defaultIdx number? 1-based index of default value.
---@param labelFunc fun(v:any):string? Label creation function, used for values without labels provided.
---@param uiType string?
---@return ParamTypeData
function config_util.paramType(values, defaultIdx, labelFunc, uiType)
	local idxToVal = {}
	local labels = {}
	labelFunc = labelFunc or tostring
	for i, value in ipairs(values) do
		if type(value) == "table" then
			value, labels[i] = table.unpack(value)
		end
		if not labels[i] then
			labels[i] = labelFunc(value)
		end
		idxToVal[i - 1] = value
	end
	--- @class ParamTypeData
	local data = {
		uiType = uiType or "SLIDER",
		--- Maps indexes to actual values
		---@type table<number, any>
		values = idxToVal,
		--- Value labels to use in mod.lua params
		---@type string[]
		labels = labels,
		--- Index of default value for mod.lua params
		defaultIdx = defaultIdx and (defaultIdx - 1) or 0
	}
	return data
end

---@param defaultVal number?
---@param ... number[]|number
---@return number[],number
function config_util.linearValues(defaultVal, ...)
	local values = {}
	local defaultIdx = nil
	local ranges = {...}
	local i = 1
	if type(ranges[1]) == "number" then
		ranges = {ranges}
	end
	for _, range in ipairs(ranges) do
		local min, max, step = table.unpack(range)
		for v = min, max + step/2, step do -- Add half step to fix issues with small float values
			values[i] = v
			if defaultIdx == nil and v >= defaultVal then
				defaultIdx = i
			end
			i = i + 1
		end
	end
	return values, defaultIdx or 1
end

---Creates ParamTypeData with values based linear progression: val = min + i*step
---@param labelFunc fun(v:any):string? Label creation function, used for values without labels provided.
---@param uiType string?
---@param defaultVal number? Default value (must be divisible to step value of one of the ranges).
---@param ... number[]|number List of ranges {{min, max, step}, ...} or single range as arguments min, max, step
---@return ParamTypeData
function config_util.genParamLinear(labelFunc, uiType, defaultVal, ...)
	local values, defaultIdx = config_util.linearValues(defaultVal, ...)
	return config_util.paramType(values, defaultIdx, labelFunc, uiType)
end

---Generate values and value labels for mod parameter based on exponential progression:  val = min*(base^i).
---@deprecated
---@param min number Minimum value.
---@param max number Maximum value (must follow progression).
---@param base number?  Base of exponent.
---@param defaultVal number? Default value (must follow progression).
---@param labelFunc function? Label generating function.
---@param uiType string? Param UI control type.
---@return ParamTypeData
function config_util.genParamTypeExp(min, max, base, defaultVal, labelFunc, uiType)
	local values = {}
	local defaultIdx = nil
	base = base or 2
	defaultVal = defaultVal or min

	local i = 0
	local v = min
	while v <= max do
		values[i] = v
		if defaultIdx == nil and v >= defaultVal then
			defaultIdx = i
		end
		v = min * (base ^ i)
		i = i + 1
	end
	return config_util.paramType(values, defaultIdx or 1, labelFunc, uiType)
end

---Converts raw params into actual params.
---@param rawParams table<string, number> Raw params from mod config (0-based indexes).
---@param allParams {[1]:string,[2]:ParamTypeData}[] Table of pairs {paramId, ParamTypeData}.
---@return table<string, any>
function config_util.getActualParams(rawParams, allParams)
	local actualParams = {}
	---@type ParamTypeData
	for _, data in pairs(allParams) do
		local paramId = data[1]
		local paramData = data[2]
		if rawParams ~= nil and rawParams[paramId] ~= nil then
			actualParams[paramId] = paramData.values[rawParams[paramId]]
		else
			actualParams[paramId] = paramData.values[paramData.defaultIdx]
		end
	end
	return actualParams
end

function config_util.checkboxParam(default)
	return config_util.paramType({{false, "OFF"}, {true, "ON"}}, default and 2 or 1, nil, "CHECKBOX")
end

---Combo box
---@param values {[1]=any,[2]=string}[]
---@param default number?
---@return ParamTypeData
function config_util.comboBoxParam(values, default)
	return config_util.paramType(values, default or 1, nil, "COMBOBOX")
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
		uiType = paramData.uiType or "SLIDER",
		values = paramData.labels,
		defaultIndex = paramData.defaultIdx
	}
end

---Generate param info.
---@param allParams table Table of pairs {paramId, ParamTypeData}.
---@return table
function config_util.makeModParams(allParams)
	local result = {}
	for i, data in ipairs(allParams) do
		result[i] = makeParamInfo(data[1], data[2])
	end
	return result
end

return config_util