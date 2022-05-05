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

local table_util = require 'costly_infrastructure/lib/table_util'
local math_ex = require 'costly_infrastructure/lib/math_ex'
local entity_info = require 'costly_infrastructure/entity_info'
local enum = require 'costly_infrastructure/enum'

local Category = enum.Category

local line_stats = {}

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

function line_stats.calculateTotalLineRatesByCategory()
    local lineIds = api.engine.system.lineSystem.getLines()
    local rates = table_util.mapDict(Category, function(cat) return cat, 0 end)
    for _, id in pairs(lineIds) do
        local lineInfo = game.interface.getEntity(id)
        local line = api.engine.getComponent(id, api.type.ComponentType.LINE)
        if lineInfo ~= nil and line ~= nil then
            local numStops = #line.stops
            local cat = entity_info.getCategoryByTransportModes(line.vehicleInfo.transportModes, "Line "..id)
            if cat then
                rates[cat] = rates[cat] + lineInfo.rate * numStops
            end
        end
    end
    return rates
end

return line_stats