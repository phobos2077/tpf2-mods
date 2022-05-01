--[[
Mod Configuration utilities.
Version: 1.0

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


local config_util = {}


config_util.fmt = {
    percent = function(v)
        return math.floor(v * 100) .. "%"
    end,
    timesX = function(v)
        return v .. "x"
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
---@param values table List of values or table-pairs of {value, label}.
---@param defaultIdx number? 1-based index of default value.
---@param labelFunc function? Label creation function, used for values without labels provided.
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
        values = idxToVal,
        --- Value labels to use in mod.lua params
        labels = labels,
        --- Index of default value for mod.lua params
        defaultIdx = defaultIdx and (defaultIdx - 1) or 0
    }
    return data
end

---Generate values and value labels for mod parameter based on linear progression: val = min + i*step
---@param min number Minimum value.
---@param max number Maximum value (inclusive).
---@param step number Step between values.
---@param defaultVal number? Default value (must be divisible to step value).
---@param labelFunc function? Label generating function.
---@param uiType string? Param UI control type.
---@return ParamTypeData
function config_util.genParamTypeLinear(min, max, step, defaultVal, labelFunc, uiType)
	local values = {}
	local defaultIdx = nil
	defaultVal = defaultVal or min

    local i = 1
	for v = min, max + step/2, step do -- Add half step to fix issues with small float values
        values[i] = v
		if defaultIdx == nil and v >= defaultVal then
			defaultIdx = i
		end
		i = i + 1
	end
	return config_util.paramType(values, defaultIdx or 1, labelFunc, uiType)
end

---Generate values and value labels for mod parameter based on exponential progression:  val = min*(base^i).
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
---@param rawParams table Raw params from mod config (0-based indexes).
---@param allParams table Table of pairs {paramId, ParamTypeData}.
---@return table
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
    return table_util.map(allParams, function(data)
        return makeParamInfo(data[1], data[2])
    end)
end

return config_util