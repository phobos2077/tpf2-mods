--[[
TODO:

Copyright (c)  2022  phobos2077  (https://steamcommunity.com/id/phobos2077)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including the right to distribute and without limitation the rights to use, copy and/or modify
the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.
--]]

local journal_util = require 'lib/journal_util'
local table_util = require 'lib/table_util'

local persistentData = {}
local chargeInterval = 365.25

local Type = journal_util.Enum.Type
local Carrier = journal_util.Enum.Carrier
local Construction = journal_util.Enum.Construction
local Maintenance = journal_util.Enum.Maintenance

local function chargeTax(gameTime)
	local journal = journal_util.getJournalForPeriod(gameTime - chargeInterval, gameTime)
	local taxBase = journal.income._sum + journal.maintenance._sum
	local taxRate = 0.2
	local taxAmount = taxBase * taxRate
	if taxAmount > 0 then
		journal_util.bookEntry(-taxAmount, Type.OTHER, Carrier.OTHER, Construction.OTHER, Maintenance.OTHER)
	end
	print(string.format("Tax = Tax Base * Rate = $%d * %df = $%d", taxBase, taxRate * 100, taxAmount))
end

function data()
	return {
		save = function()
			return persistentData
		end,
		load = function(loadedState)
			persistentData = loadedState or {}
		end,
		update = function()
			local currentTime = game.interface.getGameTime().time
			-- Mod started for the first time.
			if persistentData.nextTaxTime == nil then
				-- Make sure extra maintenance charge is always calculated at fixed year intervals from game start.
				persistentData.nextTaxTime = math.ceil(currentTime / chargeInterval) * chargeInterval
			end
			if currentTime > persistentData.nextTaxTime then
				chargeTax(currentTime)
				persistentData.nextTaxTime = persistentData.nextTaxTime + chargeInterval
			end
		end,
		guiHandleEvent = function(id, name, param)
			-- debugPrint({"guiHandleEvent", id, name, param})
		end,
		handleEvent = function(src, id, name, param)
			-- if src ~= "guidesystem.lua" then
			--	debugPrint({"handleEvent", src, id, name, param})
			--end
		end
	}
end
