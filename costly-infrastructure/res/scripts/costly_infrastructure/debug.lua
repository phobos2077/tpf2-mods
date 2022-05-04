local entity_info = require 'costly_infrastructure/entity_info'
local vehicle_stats = require 'costly_infrastructure/vehicle_stats'
local line_stats = require 'costly_infrastructure/line_stats'

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

-- api.cmd.sendCommand(api.cmd.make.sendScriptEvent("", "debug", "printVehicleStats"))
function debug.printVehicleStats()
	debugPrint("Printing Vehicle stats CSV")
	debugPrint(vehicle_stats.printVehicleStats())
end

-- api.cmd.sendCommand(api.cmd.make.sendScriptEvent("", "debug", "printLineStats"))
function debug.printLineStats()
	debugPrint("Printing Averag Line Rates")
	debugPrint(line_stats.calculateAverageLineRatesByCategory())
end

-- api.cmd.sendCommand(api.cmd.make.sendScriptEvent("", "debug", "printGameInterface"))
function debug.printGameInterface()
	debugPrint(game.interface)
end

return debug