local game_enum = require "lib/game_enum"
local table_util = require "lib/table_util"
local enum = require "costly_infrastructure/enum"

local entity_info = {}

local Category = enum.Category

local ConstructionType = game_enum.ConstructionType

local constructionTypeStrToCategory = {
	AIRPORT = Category.AIR,
	AIRPORT_CARGO = Category.AIR,

	HARBOR = Category.WATER,
	HARBOR_CARGO = Category.WATER,
	WATER_DEPOT = Category.WATER,
	WATER_WAYPOINT = Category.WATER,

	RAIL_DEPOT = Category.RAIL,
	RAIL_STATION = Category.RAIL,
	RAIL_STATION_CARGO = Category.RAIL,

	STREET_CONSTRUCTION = Category.STREET,
	STREET_DEPOT = Category.STREET,
	STREET_STATION = Category.STREET,
	STREET_STATION_CARGO = Category.STREET,
}

local constructionTypeToCategory = table_util.mapDict(constructionTypeStrToCategory, function(cat, typeStr) return ConstructionType[typeStr], cat end)

local cachedConstructionTypes = {}
local function getConstructionTypeByFileName(fileName)
    if cachedConstructionTypes[fileName] == nil then
		local index = api.res.constructionRep.find(fileName)
		if index ~= -1 then
			local config = api.res.constructionRep.get(index)
			cachedConstructionTypes[fileName] = config and config.type or false
		else
			cachedConstructionTypes[fileName] = false
		end
    end
    return cachedConstructionTypes[fileName]
end

local function getCategoryByConstructionType(constructionType)
	return constructionTypeToCategory[constructionType]
end

---@param fileName string
---@return string
function entity_info.getCategoryByConstructionFileName(fileName)
	return getCategoryByConstructionType(getConstructionTypeByFileName(fileName))
end

function entity_info.getCategoryByConstructionTypeStr(typeStr)
	return constructionTypeStrToCategory[typeStr]
end

return entity_info