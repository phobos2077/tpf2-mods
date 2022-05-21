
--[[

Original Senseless weights, for reference:

ALUMINIUM = 2750
APPLIANCES = 2500
BAUXITE = 2420
BRICKS = 1922
CANS = 2000
CARS = 1000
CEMENT = 2600
CLAY = 1826
COAL = 1350
COMMERCIAL_GOODS = 2500
COMPUTERS = 2600
CONCRETE = 1400
CONSTRUCTION_MATERIALS = 3000
COPPER = 8940
COPPER_ORE = 2400
CRUDE = 961
DEVICES = 800
ELECTRONICS = 2500
FIBER = 1510
FISH = 1200
FODDER = 600
FOOD = 900
FUEL = 830
GLASS = 1900
GOODS = 2500
GRAIN = 600
INDUSTRIAL_GOODS = 3500
IRON_ORE = 2400
IT_GOODS = 2950
LEATHER = 590
LIMESTONE = 2700
LIVESTOCK = 1000
LOGS = 800
MACHINES = 3950
MAIL = 600
MEAT = 1000
MECHANIZED_GOODS = 3500
MILK = 1030
MULTIMEDIA = 2500
OIL = 855
PAPER = 800
PASSENGERS = 200
PLANKS = 528
PLASTIC = 1250
RUBBER = 1200
SAND = 1530
STEEL = 7900
STONE = 1400
SYNTHETIC_FIBER = 1510
TEXTILES = 1350
TIRES = 1400
TOOLS = 2950
TRANSIT_GOODS = 2500
UNSORTED_MAIL = 600
WASTE = 250
WASTE_RESTS = 250
WOOL = 800

]]

local rebalancedWeights = {
	ALUMINIUM = 1500,
	APPLIANCES = 1200,
	BAUXITE = 2400,
	BRICKS = 1800,
	CANS = 1200,
	CARS = 900,
	CEMENT = 2100,
	CLAY = 1900,
	COAL = 1200,
	COMMERCIAL_GOODS = 900,
	COMPUTERS = 1200,
	CONCRETE = 2100,
	CONSTRUCTION_MATERIALS = 1800,
	COPPER = 2100,
	COPPER_ORE = 2400,
	CRUDE = 1200,
	DEVICES = 800,
	ELECTRONICS = 1200,
	FIBER = 1500,
	FISH = 1200,
	FODDER = 600,
	FOOD = 900,
	FUEL = 900,
	GLASS = 1800,
	GOODS = 1200,
	GRAIN = 900,
	INDUSTRIAL_GOODS = 1200,
	IRON_ORE = 2700,
	IT_GOODS = 900,
	LEATHER = 900,
	LIMESTONE = 2700,
	LIVESTOCK = 1200,
	LOGS = 1200,
	MACHINES = 1800,
	MAIL = 600,
	MEAT = 1200,
	MECHANIZED_GOODS = 1200,
	MILK = 1200,
	MULTIMEDIA = 900,
	OIL = 900,
	PAPER = 1200,
--	PASSENGERS = 200,
	PLANKS = 1200,
	PLASTIC = 1200,
	RUBBER = 1200,
	SAND = 1800,
	STEEL = 2400,
	STONE = 1800,
	SYNTHETIC_FIBER = 1200,
	TEXTILES = 1200,
	TIRES = 1200,
	TOOLS = 1500,
	TRANSIT_GOODS = 1200,
	UNSORTED_MAIL = 600,
	WASTE = 1200,
	WASTE_RESTS = 300,
	WOOL = 1200,
}

local function constructionFilter(fileName, data)
	if fileName:find("industry/bioremediation_center.con$") then
		print("Disabled Bioremediation Center.")
		return false
	end
	return true
end

local function patchUpdateFn(data, patchFn)
	if type(data.updateFn) ~= "function" then
		return
	end
	local updateFn = data.updateFn
	data.updateFn = function(params)
		local result = updateFn(params)
		patchFn(result, params)		
		return result
	end
end

local function setIndustryOutput(result, cargoTypeId, value)
	if result and result.rule and result.rule.output then
		result.rule.output[cargoTypeId] = value
	end
end

local function constructionModifier(fileName, data)
	-- print("loadConstruction " .. fileName)

	-- Modify copper mill to output 1 copper instead of 2
	if fileName:find("industry/copper_mill.con$") then
		patchUpdateFn(data, function (result)
			setIndustryOutput(result, "COPPER", 1)
		end)
		print("Updating Copper Mill to produce 1 output.")
	elseif fileName:find("industry/incinerating_plant.con$") then
		patchUpdateFn(data, function (result)
			setIndustryOutput(result, "WASTE_RESTS", nil)
		end)
		print("Updating Incinerating Plant to not produce Waste Rests.")
	elseif fileName:find("industry/recycling_center.con$") then
		patchUpdateFn(data, function (result)
			setIndustryOutput(result, "WASTE_RESTS", nil)
		end)
		print("Updating Recycling Center to not produce Waste Rests.")
	elseif fileName:find("industry/flax_farm.con$") then
		if data.availability then
			data.availability.yearTo = 1880
		end
		print("Updating Flax Farm to last longer.")
	end
	return data
end

function data()
	return {
		info = {
			minorVersion = 0,
			severityAdd = "NONE",
			severityRemove = "NONE",
			name = "Senseless Rebalance",
			description = "Trying to make some sense",
			tags = { "Script Mod" },
			authors = {
				{
					name = "phobos2077",
					role = "CREATOR",
					text = "",
					steamProfile = "76561198025571704",
				},
			},
			params = {
			},
		},
		runFn = function (settings, modParams)
			--local params = modParams[getCurrentModId()]

			addFileFilter("construction", constructionFilter)
			addModifier("loadConstruction", constructionModifier)
		end,
		postRunFn = function()
			local allCargoTypes = api.res.cargoTypeRep.getAll()
			local numModified = 0
			for id, fileName in pairs(allCargoTypes) do
				local cargoType = api.res.cargoTypeRep.get(id)
				if cargoType.id ~= "PASSENGERS" then
					-- Reasonable default for any cargo types added in future
					cargoType.weight = rebalancedWeights[cargoType.id] or 1200
					numModified = numModified + 1
				end
			end
			print("Modified " .. numModified .. " cargo weights.")
		end
	}
end