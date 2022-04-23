local util = {}

--- Gets a specified sequence of keys from a multi-level table, creating sub-tables as needed.
---@param t table
---@param key any
---@return table
function util.getOrAdd(t, key, ...)
	if key == nil then
		return t
	end
	if t[key] == nil then
		t[key] = {}
	end
	return util.getOrAdd(t[key], ...)
end

--- Increment number value in a table.
---@param t table
---@param key any
---@param num number Amount to increment.
---@return number The incremented value.
function util.incInTable(t, key, num)
    t[key] = (t[key] or 0) + num
    return t[key]
end

function util.tableKeys(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

function util.tableValues(t)
    local values = {}
    for _, v in pairs(t) do
        table.insert(values, v)
    end
    return values
end

--- Increment number value in a multi-dimensional table. Last parameter should be number. Second from last - they key corresponding to the number to increment.
---@param t table
function util.incInMultiTable(t, ...)
    local params = {...}
    if #params < 2 then
        print("[util.incInMultiTable] Invalid number of parameters: " .. #params + 1 .. " expected 3 or more.")
        return
    end
    local num = table.remove(params, #params)
    local key = table.remove(params, #params)
    if #params > 0 then
        t = util.getOrAdd(t, table.unpack(params))
    end
    return util.incInTable(t, key, num)
end


--- Map table values.
---@param t table
---@param func function Map function(value, key).
function util.map(t, func)
    local result = {}
    for k, v in pairs(t) do
        result[k] = func(v, k)
    end
    return result
end

--- Map table values as dictionary, changing keys.
---@param t table
---@param func function Map function(value, key) - should return two values: new key and new value.
function util.mapDict(t, func)
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
function util.reduce(t, func, result)
    for k, v in pairs(t) do
        result = func(result, v, k)
    end
    return result
end

--- Sum values from table.
---@param t table
---@param selectorFunc function If nil, table values will be summed.
function util.sum(t, selectorFunc)
    if selectorFunc == nil then
        selectorFunc = function (v) return v end
    end
    return util.reduce(t, function(sum, value, key)
        return sum + selectorFunc(value, key)
    end, 0)
end

return util