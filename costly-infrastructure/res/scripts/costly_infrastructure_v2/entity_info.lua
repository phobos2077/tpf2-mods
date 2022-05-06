local game_enum = require "costly_infrastructure_v2/lib/game_enum"
local table_util = require "costly_infrastructure_v2/lib/table_util"
local enum = require "costly_infrastructure_v2/enum"

local entity_info = {}

local Category = enum.Category

local ConstructionType = game_enum.ConstructionType
local TransportMode = game_enum.TransportMode
local Carrier = game_enum.Carrier

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

local transportModeToCategory = {
	[TransportMode.BUS] = Category.STREET,
	[TransportMode.TRUCK] = Category.STREET,
	[TransportMode.TRAM] = Category.STREET,
	[TransportMode.ELECTRIC_TRAM] = Category.STREET,
	[TransportMode.TRAIN] = Category.RAIL,
	[TransportMode.ELECTRIC_TRAIN] = Category.RAIL,
	[TransportMode.AIRCRAFT] = Category.AIR,
	[TransportMode.SMALL_AIRCRAFT] = Category.AIR,
	[TransportMode.SHIP] = Category.WATER,
	[TransportMode.SMALL_SHIP] = Category.WATER,
}

local carrierStrToCategory = {
	ROAD = Category.STREET,
	RAIL = Category.RAIL,
	TRAM = Category.STREET,
	AIR = Category.AIR,
	WATER = Category.WATER,
}
local carrierToCategory = table_util.mapDict(carrierStrToCategory, function(cat, typeStr) return Carrier[typeStr], cat end)

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

function entity_info.getCategoryByTransportModes(transportModes, context)
    local cat
    for mode, flag in pairs(transportModes) do
        if flag and flag == 1 then
            local potentialCat = transportModeToCategory[mode - 1]
            if potentialCat then
                if not cat then
                    cat = potentialCat
                elseif potentialCat ~= cat then
                    print("! ERROR !  "..(context or "").." matched more than 1 category: ".. potentialCat ..", ".. cat .. " ---- " .. debug.traceback())
                end
            end
        end
    end
    return cat
end


function entity_info.getCategoryByCarriers(carriers)
	for carrierStr, flag in pairs(carriers) do
		if flag then
			local cat = carrierStrToCategory[carrierStr]
			if cat ~= nil then
				return cat
			end
		end
	end
end

return entity_info