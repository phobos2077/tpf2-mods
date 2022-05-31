local journal_util = require "costly_infrastructure_v2/lib/journal_util"
local game_enum = require "costly_infrastructure_v2/lib/game_enum"

local enum = require "costly_infrastructure_v2/enum"
local entity_info = require "costly_infrastructure_v2/entity_info"
local vehicle_stats = require "costly_infrastructure_v2/vehicle_stats"
local config = require "costly_infrastructure_v2/config"

local Category = enum.Category


local categoryToCarrier = {
	[Category.STREET] = journal_util.Enum.Carrier.ROAD,
	[Category.RAIL]   = journal_util.Enum.Carrier.RAIL,
	[Category.WATER]  = journal_util.Enum.Carrier.WATER,
	[Category.AIR]    = journal_util.Enum.Carrier.AIR
}

local vehicleMultCalculator

---@return VehicleMultCalculator
local function getVehicleMultCalculator()
	if vehicleMultCalculator == nil then
		vehicleMultCalculator = vehicle_stats.VehicleMultCalculator.new(config.get().vehicleMultParams, vehicle_stats.loadVehicleStats())
	end
	return vehicleMultCalculator
end

local function bookExtraBuildCosts(amount, carrier, construction)
	if amount == 0 then return end
	print(string.format("%s extra for construction: %d, carrier: %d, constr: %d", amount > 0 and "Pay" or "Refund", amount, carrier, construction))
	journal_util.bookEntry(-amount, journal_util.Enum.Type.CONSTRUCTION, carrier, construction, 0, 0)
end

local function getConstructionForJournal(eventId, category)
	if eventId == "bulldozer" then
		return journal_util.Enum.Construction.BULLDOZER
	end
	return category == Category.RAIL
		and journal_util.Enum.Construction.TRACK
		or journal_util.Enum.Construction.STREET
end

local builder_events = {}

function builder_events.guiHandleEvent(id, name, param)
	-- Scales build & refund costs for:
	-- 1) Tracks & roads build and bulldoze
	-- 2) Signal, waypoint, road station build and bulldoze.
	-- 3) Track & road constructions.
	-- 4) Station module bulldoze (to work around issue where refund amount didn't change for module)
	-- 
	-- TODO: use this for everything? (depos and stations, instead of modifiers)
	-- Big difference from normal cost changes is terrain alignment costs!

	if (id == "trackBuilder" or id == "streetBuilder" or id == "streetTerminalBuilder" or id == "constructionBuilder" or id == "bulldozer") and
		(name == "builder.proposalCreate" or name == "builder.apply") then

		local prop = param.proposal
		local segment = prop.proposal.addedSegments[1] or prop.proposal.removedSegments[1]
		local conType = prop.toAdd[1] and entity_info.getConstructionTypeByFileName(prop.toAdd[1].fileName) or false

		local category
		if segment then
			category = segment.type == 1 and Category.RAIL or Category.STREET
		elseif conType then
			category = entity_info.getCategoryByConstructionType(conType)
		end

		local isEdgeProposal = (#prop.toAdd == 0 and #prop.toRemove == 0) or conType == game_enum.ConstructionType.STREET_CONSTRUCTION or conType == game_enum.ConstructionType.TRACK_CONSTRUCTION
		local isModuleRefund = id == "bulldozer" and #prop.toRemove == 1 and #prop.toAdd == 1 and prop.toAdd[1].params and prop.toAdd[1].params.modules

		-- if name == "builder.apply" then
		-- 	debugPrint({"builder apply", param.proposal, param.data.costs, param.data.errorState, category, conType, isEdgeProposal, isModuleRefund})
		-- end
		
		if category and (isEdgeProposal or isModuleRefund) then
			local mult = getVehicleMultCalculator():getMultiplier(category, game.interface.getGameTime().date.year)
			if #prop.proposal.edgeObjectsToAdd == 0 then
				mult = 1 + (mult - 1) * config.get().edgeCostScaleFactor
			end
			if name == "builder.apply" then
				-- debugPrint({"apply", param.data.costs, category, game.interface.getGameTime().date.year, mult})
				if mult > 1 then
					local carrier = categoryToCarrier[category]
					local construction = getConstructionForJournal(id, category)
					bookExtraBuildCosts(math.floor(param.data.costs * (mult - 1)), carrier, construction)
				end
			end
			param.data.costs = math.floor(param.data.costs * mult)
		end
	end
end

function builder_events.handleEvent(id, name, param)
	-- Support for Auto-Parallel Tracks and AutoSig mods.
	if (id == "__ptracks__" or id == "__autosig2__") and name == "costs" and param.costs then
		local mult = getVehicleMultCalculator():getMultiplier(Category.RAIL, game.interface.getGameTime().date.year)
		if id == "__ptracks__" then
			mult = 1 + (mult - 1) * config.get().edgeCostScaleFactor
		end
		if mult > 1 then
			local constr = (id == "__ptracks__")
				and journal_util.Enum.Construction.TRACK
				or journal_util.Enum.Construction.SIGNAL
				
			bookExtraBuildCosts(math.floor(param.costs * (mult - 1)), journal_util.Enum.Carrier.RAIL, constr)
		end
	end
end

return builder_events