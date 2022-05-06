local entity_costs = require "costly_infrastructure_v2/entity_costs"
local vehicle_stats = require "costly_infrastructure_v2/vehicle_stats"
local line_stats = require "costly_infrastructure_v2/line_stats"
local station_stats = require "costly_infrastructure_v2/station_stats"

local debug = {}

-- mydebug = require "costly_infrastructure_v2/debug"

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

function debug.findEntities(type, radius)
	return game.interface.getEntities({pos = game.gui.getTerrainPos(), radius = radius or 100}, {type = type or "CONSTRUCTION"})
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
	debugPrint(entity_costs.getTotalEdgeCostsByCategory())
end

-- api.cmd.sendCommand(api.cmd.make.sendScriptEvent("", "debug", "printTotalConstructionMaintenance"))
function debug.printTotalConstructionMaintenance()
	debugPrint("Printing construction maintenance costs by type")
	debugPrint(entity_costs.getTotalConstructionMaintenanceByCategory())
end

-- api.cmd.sendCommand(api.cmd.make.sendScriptEvent("", "debug", "printVehicleStats"))
function debug.printVehicleStats()
	debugPrint("Printing Vehicle stats CSV")
	debugPrint(vehicle_stats.printVehicleStats())
end

-- api.cmd.sendCommand(api.cmd.make.sendScriptEvent("", "debug", "printLineStats"))
function debug.printLineStats()
	debugPrint("Printing Total Line Rates")
	debugPrint(line_stats.getTotalLineRatesByCategory())
end

-- api.cmd.sendCommand(api.cmd.make.sendScriptEvent("", "debug", "printStationStats"))
function debug.printStationStats()
	debugPrint("Printing Station Capacities")
	debugPrint(station_stats.getTotalCapacityOfAllStationsByCategory())
end

-- api.cmd.sendCommand(api.cmd.make.sendScriptEvent("", "debug", "printGameInterface"))
function debug.printGameInterface()
	debugPrint(game.interface)
end

function debug.unloadMod()
	for name,_ in pairs(package.loaded) do
		if string.find(name,"costly_infrastructure") == 1 then
			package.loaded[name] = nil
		end
	end
end

return debug