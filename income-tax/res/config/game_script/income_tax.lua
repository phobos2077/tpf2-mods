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

local journal_util = require 'income_tax/lib/journal_util'
local table_util = require 'income_tax/lib/table_util'
local taxes = require 'income_tax/taxes'
local config = require 'income_tax/config'

local persistentData = {}
local financePeriod = 365.25 * 2 -- two timescale-independent "years" are equal to one in-game finance-period

local Type = journal_util.Enum.Type
local Carrier = journal_util.Enum.Carrier
local Construction = journal_util.Enum.Construction
local Maintenance = journal_util.Enum.Maintenance


local function chargeTax(gameTime)
	local taxParams = config.get().taxRateParams
	local journal = journal_util.getJournalForPeriod(gameTime - financePeriod, gameTime)
	local taxBase = journal.income._sum + journal.maintenance._sum
	--local tax = taxes.calculateProgressiveTaxBrackets(taxBase, configData.taxBrackets)
	local tax = taxes.calculateProgressiveTaxArcTan(taxBase, taxParams.rateMin, taxParams.rateMax, taxParams.halfRateBase, taxParams.taxableMin)
	if tax.total > 0 then
		journal_util.bookEntry(-tax.total, Type.OTHER, Carrier.OTHER, Construction.OTHER, Maintenance.OTHER)
	end
	--debugPrint(tax)
	--local bracketsStr = table_util.listToString(tax.brackets, ";", "$%d")
	--print(string.format("Tax Total = $%d, Base = $%d, Average Rate = %.1f%%, Brackets = (%s)", tax.total, tax.base, tax.averageRate * 100, bracketsStr))

	print(string.format("Progressive Income Tax. Total = $%d, Base = $%d, Rate = %.1f%%", tax.total, tax.base, tax.rate * 100))
end

local nextTaxTime

function data()
	return {
		save = function()
			-- return persistentData
		end,
		load = function(loadedState)
			-- persistentData = loadedState or {}
		end,
		update = function()
			local currentTime = game.interface.getGameTime().time
			-- First update after game loaded.
			if nextTaxTime == nil then
				-- Make sure extra maintenance charge is always calculated at the end of current finance period.
				nextTaxTime = math.ceil(currentTime / financePeriod) * financePeriod
			end
			if currentTime > nextTaxTime then
				chargeTax(currentTime)
				nextTaxTime = nextTaxTime + financePeriod
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
