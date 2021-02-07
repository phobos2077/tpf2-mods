local journal_util = {}

journal_util.Enum = {
	Type = {
		MAINTENANCE = 4
	},
	Carrier = {
		ROAD = 0,
		RAIL = 1,
		TRAM = 2,
		WATER = 3,
		AIR = 4
	},
	Construction = {
		ROAD = 0,
		TRACK = 1,
		INFRASTRUCTURE = 2,
		BUILDING = 6,
	}
}

function journal_util.getPlayerJournal()
	return api.engine.getComponent(api.engine.util.getPlayer(), api.type.ComponentType.ACCOUNT).journal
end

function journal_util.getMaintenancePaymentAmountsFromJournal(journal, minTimeMs)
	local result = {}
	local numEntries = 0
	for i = journal:size(), 1, -1 do
		local je = journal:get(i)
		if je ~= nil then
			if i % 10 == 0 then
				print("Calculating... " .. i .. " time = " .. je.time)
			end
			if je.time < minTimeMs then
				break
			end
			local cat = je.category
			if cat.type == JournalEnum.Type.MAINTENANCE then
				local t = getOrAdd(result, cat.carrier)
				t[cat.construction] = (t[cat.construction] or 0) + je.amount
				numEntries = numEntries + 1
			end
		end
	end
	debugPrint({"Maintenance Payment Amounts from last period based on " .. numEntries .. " entries:", result})
	return result
end

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