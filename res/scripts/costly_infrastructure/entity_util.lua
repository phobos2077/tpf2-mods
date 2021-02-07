local util = require 'costly_infrastructure/util'

local entity_util = {}

--- Gets all entities on the map with a given type.
---@param type string Entitiy type.
---@return table A list of entities.
function entity_util.getAllEntitiesByType(type)
    return game.interface.getEntities({radius = 1e10}, {type = type})
end

function entity_util.getTotalEdgeLengthsByType()
    local playerId = game.interface.getPlayer()
    local allEdges = entity_util.getAllEntitiesByType("BASE_EDGE")
    local result = {street = {}, track = {}}
    for _, edgeId in pairs(allEdges) do
        local playerOwned = api.engine.getComponent(edgeId, api.type.ComponentType.PLAYER_OWNED)
        if playerOwned ~= nil and playerOwned.player == playerId then
            local network = api.engine.getComponent(edgeId, api.type.ComponentType.TRANSPORT_NETWORK)
            if network ~= nil and network.edges ~= nil and network.edges[1] ~= nil then
                local len = network.edges[1].geometry.length
                local street = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_STREET)
                if street ~= nil then
                    util.incInMultiTable(result.street, street.streetType, street.tramTrackType, len)
                else
                    local track = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
                    if track ~= nil then
                        util.incInMultiTable(result.track, track.trackType, track.catenary and 1 or 0, len)
                    end
                end
            end
        end
    end
    return result
end

local function getMultByTramType(tramTrackType)
    if tramTrackType == 1 then
        return 1 + game.config.costs.roadTramLane
    end
    if tramTrackType == 2 then
        return 1 + game.config.costs.roadElectricTramLane
    end
    return 1
end


local function getMultByCatenary(hasCatenary)
    if hasCatenary == 1 then
        return 1 + game.config.costs.railroadCatenary
    end
    return 1
end

function entity_util.getTotalEdgeCostsByType()
    local lengthsByType = entity_util.getTotalEdgeLengthsByType()
    local result = {street = 0, track = 1}
    for streetType, lengthsByTramTrackType in pairs(lengthsByType.street) do
        local streetConfig = api.res.streetTypeRep.get(streetType)
        for tramTrackType, len in pairs(lengthsByTramTrackType) do
            local tramMult = getMultByTramType(tramTrackType)
            local cost = streetConfig.cost * len * tramMult
            util.incInTable(result, "street", cost)
        end
    end
    for trackType, lengthsByCatenary in pairs(lengthsByType.track) do
        local trackConfig = api.res.trackTypeRep.get(trackType)
        for hasCatenary, len in pairs(lengthsByCatenary) do
            local mult = getMultByCatenary(hasCatenary)
            local cost = trackConfig.cost * len * mult
            util.incInTable(result, "track", cost)
        end
    end
    return result
end

return entity_util