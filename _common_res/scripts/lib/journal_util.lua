--[[
Journal (Book) Utilities
Version: 1.0

Copyright (c)  2022  phobos2077  (https://steamcommunity.com/id/phobos2077)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including the right to distribute and without limitation the rights to use, copy and/or modify
the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.
--]]

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

function journal_util.bookEntry(amount, entryType, carrierType, constructionType, maintenanceType, other)
	local cat = api.type.JournalEntryCategory.new()
	cat.type = entryType
	cat.carrier = carrierType
	cat.construction = constructionType
	cat.maintenance = maintenanceType
	cat.other = other or 0

	local je = api.type.JournalEntry.new()
	je.amount = math.floor(amount)
	je.category = cat
	je.time = -1

	api.cmd.sendCommand(api.cmd.make.bookJournalEntry(api.engine.util.getPlayer(), je))
end

return journal_util