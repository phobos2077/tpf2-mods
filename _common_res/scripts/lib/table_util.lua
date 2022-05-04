--[[
Table Utilities
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

local table_util = {}

--- Gets a specified sequence of keys from a multi-level table, creating sub-tables as needed.
---@param t table
---@param key any
---@return table
function table_util.getOrAdd(t, key, ...)
	if key == nil then
		return t
	end
	if t[key] == nil then
		t[key] = {}
	end
	return table_util.getOrAdd(t[key], ...)
end

--- Increment number value in a table.
---@param t table
---@param key any
---@param num number Amount to increment.
---@return number The incremented value.
function table_util.incInTable(t, key, num)
    t[key] = (t[key] or 0) + num
    return t[key]
end

function table_util.tableKeys(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

function table_util.tableValues(t)
    local values = {}
    for _, v in pairs(t) do
        table.insert(values, v)
    end
    return values
end

--- Increment number value in a multi-dimensional table. Last parameter should be number. Second from last - they key corresponding to the number to increment.
---@param t table
function table_util.incInMultiTable(t, ...)
    local params = {...}
    if #params < 2 then
        print("[util.incInMultiTable] Invalid number of parameters: " .. #params + 1 .. " expected 3 or more.")
        return
    end
    local num = table.remove(params, #params)
    local key = table.remove(params, #params)
    if #params > 0 then
        t = table_util.getOrAdd(t, table.unpack(params))
    end
    return table_util.incInTable(t, key, num)
end

--- Append values from other list into a given list.
---@param list table List to insert values to.
---@param other table
function table_util.iinsert(list, other)
    for _, v in ipairs(other) do
        table.insert(list, v)
    end
end


--- Map table values.
---@param t table
---@param func function Map function(value, key).
function table_util.map(t, func)
    local result = {}
    for k, v in pairs(t) do
        result[k] = func(v, k)
    end
    return result
end


--- Map table values as dictionary, changing keys.
---@param t table
---@param func function Map function(value, key) - should return two values: new key and new value.
function table_util.mapDict(t, func)
    local result = {}
    for k, v in pairs(t) do
        local newKey, newValue = func(v, k)
        result[newKey] = newValue
    end
    return result
end

--- Reduce table values.
---@param t table
---@param func function Reduce function(current, value, key).
---@param result any Initial value.
function table_util.reduce(t, func, result)
    for k, v in pairs(t) do
        result = func(result, v, k)
    end
    return result
end

--- Groups values from list into a new dictionary using key selector function.
---@param t table
---@param func function Key selector (value, key).
function table_util.groupBy(t, func)
    local result = {}
    for k, v in pairs(t) do
        local key = func(v, k)
        if not result[key] then
            result[key] = {}
        end
        result[key][k] = v
    end
    return result
end

--- Sum values from table.
---@param t table
---@param selectorFunc function? If nil, table values will be summed.
function table_util.sum(t, selectorFunc)
    if selectorFunc == nil then
        selectorFunc = function (v) return v end
    end
    return table_util.reduce(t, function(sum, value, key)
        return sum + selectorFunc(value, key)
    end, 0)
end

--- Returns max value from table.
---@param t table
---@param selectorFunc function? If nil, table values will be compared.
function table_util.max(t, selectorFunc)
    if selectorFunc == nil then
        selectorFunc = function (v) return v end
    end
    return table_util.reduce(t, function(cur, value, key)
        local cmpValue = selectorFunc(value, key)
        return (cur == nil or cmpValue > cur) and cmpValue or cur
    end, nil)
end

--- Find first value in list satisfies predicate.
---@param t table List
---@param selectorFunc function? If nil, first value will be returned.
---@return any First value.
function table_util.ifirst(t, selectorFunc)
    if selectorFunc == nil then
        selectorFunc = function () return true end
    end
    for i, v in ipairs(t) do
        if selectorFunc(v, i) then
            return v
        end
    end
end

---Concats list table to string
---@param t table
---@param separator string?
---@param formatFunc string|function?
function table_util.listToString(t, separator, formatFunc)
    separator = separator or ","
    if type(formatFunc) == "string" then
        local format = formatFunc
        formatFunc = function(v) return string.format(format, v) end
    elseif type(formatFunc) ~= "function" then
        formatFunc = function(v) return tostring(v) end
    end
    local result = ""
    for i, v in ipairs(t) do
        result = result .. (i == 1 and "" or separator) .. formatFunc(v)
    end
    return result
end

return table_util