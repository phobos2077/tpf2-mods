local entity_info = require 'costly_infrastructure/entity_info'

local debug = {}

function debug.getAllEntityComponents(entity)
	local cts = getmetatable(api.type.ComponentType).__index
	local result = {}
    for k, ct in pairs(cts) do
        local c = api.engine.getComponent(entity, ct)
        if c ~= nil then
            result[k] = c
        end
    end
	return result
end

-- game.interface.getEntities({radius = 1e10}, {type = "BASE_EDGE"})
-- api.cmd.sendCommand(api.cmd.make.sendScriptEvent("", "debug", "printAllEntityComponents", e))
function debug.printAllEntityComponents(entity)
	debugPrint("Printing all components of entity "..entity)
	debugPrint(debug.getAllEntityComponents(entity))
end

-- api.cmd.sendCommand(api.cmd.make.sendScriptEvent("", "debug", "printTotalEdgeCosts"))
function debug.printTotalEdgeCosts()
	debugPrint("Printing edge costs by type")
	debugPrint(entity_info.getTotalEdgeCostsByCategory())
end

-- api.cmd.sendCommand(api.cmd.make.sendScriptEvent("", "debug", "printTotalConstructionMaintenance"))
function debug.printTotalConstructionMaintenance()
	debugPrint("Printing construction maintenance costs by type")
	debugPrint(entity_info.getTotalConstructionMaintenanceByCategory())
end

-- api.cmd.sendCommand(api.cmd.make.sendScriptEvent("", "debug", "printGameInterface"))
function debug.printGameInterface()
	debugPrint(game.interface)
end

return debug