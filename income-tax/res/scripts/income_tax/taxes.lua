--[[
Tax calculations.

Copyright (c)  2022  phobos2077  (https://steamcommunity.com/id/phobos2077)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including the right to distribute and without limitation the rights to use, copy and/or modify
the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.
--]]

local taxes = {}

--- Calculate progressive tax based on tax base and brackets.
---@param taxBase number
---@param taxBrackets table
---@return ProgressiveTaxResult
function taxes.calculateProgressiveTax(taxBase, taxBrackets)
    ---@class ProgressiveTaxResult
	local tax = {total = 0, base = taxBase, brackets = {}}
	local lastTop = 0
	for i, bracket in ipairs(taxBrackets) do
		local rate, top = table.unpack(bracket)
		local bracketTax = 0
		if taxBase <= lastTop then
			break
		elseif i < #taxBrackets and taxBase >= top then
			bracketTax = math.floor((top - lastTop) * rate)
		else
			bracketTax = math.floor((taxBase - lastTop) * rate)
		end
		tax.total = tax.total + bracketTax
		tax.brackets[i] = bracketTax
		lastTop = top
	end
	tax.averageRate = tax.total / taxBase
	return tax
end


return taxes