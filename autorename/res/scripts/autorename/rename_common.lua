local rename_common = {}

function rename_common.getNumDigits(num)
	return num > 0 and math.floor(math.log(num, 10) + 1) or 1
end

---@param sourceName string
---@param filterParams NameFilteringParams
---@return string
function rename_common.filterSourceName(sourceName, filterParams)
	-- Remove stuff in various types of brackets.
	local skipBrackets = filterParams.skipBrackets
	if skipBrackets.square then
		sourceName = sourceName:gsub("%s?%b[]", "")
	end
	if skipBrackets.curly then
		sourceName = sourceName:gsub("%s?%b{}", "")
	end
	if skipBrackets.angled then
		sourceName = sourceName:gsub("%s?%b<>", "")
	end
	return sourceName
end

return rename_common