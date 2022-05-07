local entity_util = {}

--- Gets all entities on the map with a given type.
---@param type string Entity type.
---@return table A list of entities.
function entity_util.findAllEntitiesOfType(type)
	return game.interface.getEntities({radius = 1e10}, {type = type})
end

function entity_util.isPlayerOwned(entityId, playerId)
	local playerOwned = api.engine.getComponent(entityId, api.type.ComponentType.PLAYER_OWNED)
	return playerOwned ~= nil and playerOwned.player == playerId
end

return entity_util