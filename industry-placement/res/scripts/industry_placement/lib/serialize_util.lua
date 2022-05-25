--[[
Data serialization.
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


local serialize_util = {}

---Serializes given value of any type to string. Only use for very simple values and tables, it is very naive.
---@param value any
---@return string
function serializeValue(value)
	if type(value) == "number" then
		return tostring(value)
	elseif type(value) == "string" then
		return "\""..value:gsub('"','\\"').."\""
	elseif type(value) == "boolean" then
		return value and "true" or "false"
	elseif type(value) == "table" or type(value) == "userdata" then
		local tableStr = ""
		local i = 1
		local isFirst = true
		for k, v in pairs(value) do
			local keyStr
			if k == i then
				keyStr = ""
				i = i + 1
			else
				keyStr = (type(k) == "string" and k or "["..serializeValue(k).."]") .. "="
			end
			tableStr = tableStr .. (not isFirst and "," or "") .. keyStr .. serializeValue(v)
			isFirst = false
		end
		return "{" .. tableStr .. "}"
	else
		return "nil"
	end
end

serialize_util.serialize = serializeValue

return serialize_util