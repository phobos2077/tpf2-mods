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

return util