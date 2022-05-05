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
		LOAN = 0,
		INTEREST = 1,
		CONSTRUCTION = 2,
		ACQUISITION = 3,
		MAINTENANCE = 4,
		INCOME = 5,
		OTHER = 6
	},
	Carrier = {
		ROAD = 0,
		RAIL = 1,
		TRAM = 2,
		OTHER = 3,
		AIR = 4,
		WATER = 5,
	},
	Construction = {
		STREET = 0,
		TRACK = 1,
		SIGNAL = 2,
		STATION = 3,
		DEPOT = 4,
		BULLDOZER = 5,
		OTHER = 6,
	},
	Maintenance = {
		VEHICLE = 0,
		INFRASTRUCTURE = 1,
		OTHER = 2,
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

--[[ Example of short journal:
{
  _sum = 65884212,
  acquisition = {
    _sum = -10382242,
  },
  construction = {
    _sum = -7339,
  },
  income = {
    _sum = 207822279,
  },
  interest = 0,
  loan = 0,
  maintenance = {
    _sum = -131548486,
  },
  other = 0,
}
]]


---Gets journal for period of last N days.
---@param startTime number
---@param endTime number
---@param short? boolean Short version of journal?
---@return table
function journal_util.getJournalForPeriod(startTime, endTime, short)
	return game.interface.getPlayerJournal(1000.0 * startTime, 1000.0 * endTime, short and true or false)
end

return journal_util