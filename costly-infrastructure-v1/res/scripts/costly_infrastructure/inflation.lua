--[[
Inflation parameters.

Copyright (c)  2022  phobos2077  (https://steamcommunity.com/id/phobos2077)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including the right to distribute and without limitation the rights to use, copy and/or modify
the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.
--]]

local table_util = require "costly_infrastructure/lib/table_util"

local inflation = {}


local function getInflationFlatnessByMaxInflation(startYear, endYear, maxInflation)
	-- Don't allow negative inflation and prevent division by zero.
	if maxInflation <= 1 then
		return 9999999
	else
		return (startYear - endYear) / (1 - math.sqrt(maxInflation))
	end
end

--- Calculates inflation based on year and flatness parameter.
---@param year number
---@param startYear number
---@param flatness number More flatness => less inflation at later years.
---@return number
local function getInflationByYearAndFlatness(year, startYear, flatness)
	-- http://fooplot.com/#W3sidHlwZSI6MCwiZXEiOiIoKHgtMTg1MCs4MCkvODApXjIiLCJjb2xvciI6IiMwMDAwMDAifSx7InR5cGUiOjEwMDAsIndpbmRvdyI6WyIxODUwIiwiMjA1MCIsIjAiLCIyMCJdfV0-
	-- ((x-1850+50)/50)^2
	local base = (year - startYear + flatness)/flatness
	if base < 1 then
		base = 1
	end
	return base * base
end

---@class InflationParams
local InflationParams = {}
InflationParams.__index = InflationParams

---@return InflationParams
---@param startYear number Year when inflation starts.
---@param endYear number Year of maximum inflation.
---@param maxInflationByCategory table Maximum inflation at endYear (on top of cost multiplier) - per each category.
function InflationParams:new(startYear, endYear, maxInflationByCategory)
	---@class InflationParams
	local o = {
		startYear = startYear,
		endYear = endYear,
		flatnessByCategory = table_util.map(maxInflationByCategory, function(maxInflation)
			return getInflationFlatnessByMaxInflation(startYear, endYear, maxInflation)
		end),
	}
	setmetatable(o, self)
	return o
end

---@param year number?
---@return number
function InflationParams:processYear(year)
	year = year or game.interface and game.interface.getGameTime().date.year or self.startYear
	-- Cap year to min/max range.
	if year < self.startYear then
		year = self.startYear
	elseif year > self.endYear then
		year = self.endYear
	end
	return year
end

--- Inflation multiplier based on year.
---@param category string
---@param year number?
---@return number
function InflationParams:get(category, year)
	year = self:processYear(year)
	return getInflationByYearAndFlatness(year, self.startYear, self.flatnessByCategory[category])
end

--- Inflation multiplier based on year, for all categories.
---@param year number?
---@return table
function InflationParams:getPerCategory(year)
	year = self:processYear(year)
	return table_util.map(self.flatnessByCategory, function(flatness)
		return getInflationByYearAndFlatness(year, self.startYear, flatness)
	end)
end


inflation.InflationParams = InflationParams

return inflation