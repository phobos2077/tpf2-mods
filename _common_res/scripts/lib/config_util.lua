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

---Creates ParamTypeData
---@param valuesAndLabels any
---@param defaultIdx any
---@param uiType any
---@return ParamTypeData
function config_util.makeParamTypeData(valuesAndLabels, defaultIdx, uiType)
	local idxToVal = {}
    local labels = {}
    for i, pair in ipairs(valuesAndLabels) do
        local value, label = table.unpack(pair)
		idxToVal[i - 1] = value
        labels[i] = label or tostring(value)
	end
	--- @class ParamTypeData
	local data = {
        uiType = uiType,
        --- Maps indexes to actual values
        values = idxToVal,
        --- Value labels to use in mod.lua params
        labels = labels,
        --- Index of default value for mod.lua params
        defaultIdx = defaultIdx - 1
    }
    return data
end

---Generate values and value labels for mod parameter based on linear progression.
---@param min number Minimum value.
---@param max number Maximum value (inclusive).
---@param step number Step between values.
---@param defaultVal number? Default value (must be divisible to step value).
---@param labelFunc function? Label generating function.
---@return ParamTypeData
function config_util.makeParamTypeDataForSlider(min, max, step, defaultVal, labelFunc)
	local values = {}
	local defaultIdx = 1
	defaultVal = defaultVal or min
	labelFunc = labelFunc or function(v) return ""..v end

    local i = 1
	for v = min, max, step do
        values[i] = {v, labelFunc(v)}
		if v == defaultVal then
			defaultIdx = i
		end
		i = i + 1
	end
	return config_util.makeParamTypeData(values, defaultIdx, "SLIDER")
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