--[[
Line stats calculations.

Copyright (c)  2022  phobos2077  (https://steamcommunity.com/id/phobos2077)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including the right to distribute and without limitation the rights to use, copy and/or modify
the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.
--]]

local table_util = require 'lib/table_util'
local math_ex = require 'lib/math_ex'
local game_enum = require 'lib/game_enum'
local Category = (require 'costly_infrastructure/entity_info').Category
local TransportMode = game_enum.TransportMode

local line_stats = {}

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

local function calculateLineStatsByMode()
    local lineIds = api.engine.system.lineSystem.getLines()
    local stats = {}
    for _, id in pairs(lineIds) do
        local lineInfo = game.interface.getEntity(id)
        local line = api.engine.getComponent(id, api.type.ComponentType.LINE)
        for mode, flag in pairs(line.vehicleInfo.transportModes) do
            if flag and flag == 1 then
                local stat = stats[mode]
                if stat == nil then
                    stats[mode] = {0, 0}
                    stat = stats[mode]
                end
                stat[1] = stat[1] + 1
                stat[2] = stat[2] + lineInfo.rate
            end
        end
    end
    for _, stat in pairs(stats) do
        stat[3] = stat[2]/stat[1]
    end
    return stats
end

local function getCategoryByTransportModes(transportModes, lineId)
    local cat
    for mode, flag in pairs(transportModes) do
        if flag and flag == 1 then
            local potentialCat = transportModeToCategory[mode - 1]
            if potentialCat then
                if not cat then
                    cat = potentialCat
                elseif potentialCat ~= cat then
                    print("! ERROR ! Line "..lineId.." matched more than 1 category: "..potentialCat..", "..cat)
                end
            end
        end
    end
    return cat
end

function line_stats.calculateAverageLineRatesByCategory()
    local lineIds = api.engine.system.lineSystem.getLines()
    local stats = table_util.mapDict(Category, function(cat) return cat, {0, 0} end)
    for _, id in pairs(lineIds) do
        local lineInfo = game.interface.getEntity(id)
        local line = api.engine.getComponent(id, api.type.ComponentType.LINE)
        local cat = getCategoryByTransportModes(line.vehicleInfo.transportModes, id)
        if cat then
            local stat = stats[cat]
            stat[1] = stat[1] + 1
            stat[2] = stat[2] + lineInfo.rate
        end
    end
    return table_util.map(stats, function(stat) return stat[1] > 0 and stat[2]/stat[1] or 0 end)
end

return line_stats