local journal_util = {}

journal_util.Enum = {
	Type = {
		MAINTENANCE = 4
	},
	Carrier = {
		ROAD = 0,
		RAIL = 1,
		TRAM = 2,
		AIR = 4,
		WATER = 5,
	},
	Construction = {
		ROAD = 0,
		TRACK = 1,
		INFRASTRUCTURE = 2,
		BUILDING = 6,
	}
}

function journal_util.bookEntry(amount, entryType, carrierType, constructionType, maintenanceType)
	local cat = api.type.JournalEntryCategory.new()
	cat.type = entryType
	cat.carrier = carrierType
	cat.construction = constructionType
	cat.maintenance = maintenanceType
	cat.other = 0

	local je = api.type.JournalEntry.new()
	je.amount = math.floor(amount)
	je.category = cat
	je.time = -1

	api.cmd.sendCommand(api.cmd.make.bookJournalEntry(api.engine.util.getPlayer(), je))
end

return journal_util