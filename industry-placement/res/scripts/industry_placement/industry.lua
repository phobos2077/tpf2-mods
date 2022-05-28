local table_util = require "industry_placement/lib/table_util"
local box2 = require "industry_placement/lib/box2"
local cluster_config = require "industry_placement/cluster_config"
local world_util = require "industry_placement/world_util"


local industry = {}

local IndustryCategory = cluster_config.IndustryCategory

industry.Category = IndustryCategory

local INDUSTRY_RADIUS = 100
local INDUSTRY_SIZE = {INDUSTRY_RADIUS, INDUSTRY_RADIUS}
local INDUSTRY_AREA = math.pi * INDUSTRY_RADIUS * INDUSTRY_RADIUS

-- TODO: detect data by installed mods
local INDUSTRY_DATA = require "industry_placement/industry_data/vanilla"

local INDUSTRY_INIT_WEIGHT_TOTAL = table_util.sum(INDUSTRY_DATA, function(d) return d[1].initWeight end)

for k, d in pairs(INDUSTRY_DATA) do
	d.relativeWeight = d[1].initWeight / INDUSTRY_INIT_WEIGHT_TOTAL
end

local CATEGORY_BY_OUTPUT = {
	COAL = IndustryCategory.Coal,
	IRON_ORE = IndustryCategory.Iron,
	STONE = IndustryCategory.Stone,
	CRUDE = IndustryCategory.Crude,
	LOGS = IndustryCategory.Forest,
}

local INDUSTRY_CLUSTER_FILENAME = "industry/industry_cluster.con"

local function findAllConstructionIds()
	return game.interface.getEntities({radius = 1e10}, {type = "CONSTRUCTION"})
end

local function getClusterArea(shape, size)
	if shape == cluster_config.ClusterShape.Ellipse then
		return math.pi * size[1] * size[2]
	else
		return 4 * size[1] * size[2]
	end
end

function industry.getIndustryCategoryByFileName(fileName)
	local industryOutput = INDUSTRY_DATA[fileName][2]
	local firstOutput = next(industryOutput)
	return CATEGORY_BY_OUTPUT[firstOutput] or IndustryCategory.Other
end

---@param constr userdata
---@param id number?
---@return ClusterData
function industry.getClusterDataFromConstruction(constr, id)
	if not (constr.params and constr.params.clusterCategory) then
		printPrint({"! ERROR ! Invalid cluster construction params: ", constr.params})
		return nil
	end
	local actualParams = cluster_config.getActualParams(constr.params)
	local category = actualParams.clusterCategory
	local size = {actualParams.clusterSizeX, actualParams.clusterSizeY}
	---@type ClusterShape
	local shape = actualParams.clusterShape
	local vec4 = constr.transf:cols(3)
	local pos = {vec4[1], vec4[2]}
	---@class ClusterData
	local data = {
		id = id,
		cat = category,
		pos = pos,
		shape = shape,
		size = size,
		area = getClusterArea(shape, size),
		box = box2.fromPosAndSize(pos, size),
	}
	return data
end

---@param constr userdata
---@param id number
---@return IndustryData
function industry.getIndustryDataFromConstruction(constr, id)
	local category = industry.getIndustryCategoryByFileName(constr.fileName)
	local vec4 = constr.transf:cols(3)
	---@class IndustryData
	local data = {
		id = id,
		fileName = constr.fileName,
		cat = category,
		pos = {vec4[1], vec4[2]},
		-- size = size,
		-- area = size[1] * size[2],
	}
	return data
end

---@return ClusterData[]
function industry.findAllClustersOnMap()
	local timer = os.clock()

	local clusters = {}
	-- This is much faster for some reason, even though it iterates over all town buildings.
	api.engine.system.streetConnectorSystem.forEach(function(id, con)
		if #con.townBuildings == 0 and con.fileName == "industry/industry_cluster.con" then
			local clusterData = industry.getClusterDataFromConstruction(con, id)
			if clusterData then
				clusters[#clusters+1] = clusterData
			end
		end
	end)

	local elapsed = os.clock() - timer
	print(string.format("Found %d clusters on map in %.0f ms.", #clusters, elapsed * 1000))
	return clusters
end

---@return IndustryData[]
function industry.findAllPlaceableIndustriesOnMap()
	local timer = os.clock()
	
	-- This method is much faster, since it doesn't iterate over every town building, which are very numerous.
	local industries = world_util.findAllIndustries(function(id, con)
		local data = INDUSTRY_DATA[con.fileName]
		return data and data[1].initWeight and data[1].initWeight > 0
	end, function(id, con)
		return industry.getIndustryDataFromConstruction(con, id)
	end)

	local elapsed = os.clock() - timer
	print(string.format("Found %d industries on map in %.0f ms.", #industries, elapsed * 1000))
	return industries
end


--[[
local function allIndustriesIterator()
	local ents = game.interface.getEntities({radius = 1e10}, {type = "CONSTRUCTION"})
	local f = function(s, lastK)
		local k, id = next(ents, lastK)
		while k ~= nil do
			local constr = api.engine.getComponent(id, api.type.ComponentType.CONSTRUCTION)
			if constr and constr.fileName:find("^industry") then
				return k, id, constr
			end

			k, id = next(ents, k)
		end
		return nil
	end
	return f, nil, nil
end
]]

---@return FindIndustryResult
function industry.findAllIndustriesAndClustersOnMap()
	local timer = os.clock()
	local ents = findAllConstructionIds()

	---@class FindIndustryResult
	local result = {}
	---@type IndustryData[]
	local industries = {}
	---@type ClusterData[]
	local clusters = {}
	for _, id in pairs(ents) do
		local constr = api.engine.getComponent(id, api.type.ComponentType.CONSTRUCTION)
		if constr then
			if constr.fileName == INDUSTRY_CLUSTER_FILENAME then
				local clusterData = industry.getClusterDataFromConstruction(constr, id)
				if clusterData then
					clusters[#clusters+1] = clusterData
				end
			elseif INDUSTRY_DATA[constr.fileName] then
				local industryData = industry.getIndustryDataFromConstruction(constr, id)
				industries[#industries+1] = industryData
			end
		end
	end

	---@type table<number, ClusterData[]>
	result.clustersByCategory = table_util.igroupBy(clusters, function(cd) return cd.cat end)
	result.industries = industries
	result.industriesByCategory = table_util.igroupBy(industries, function(cd) return cd.cat end)

	local elapsed = os.clock() - timer
	print(string.format("Found %d industries and %d clusters on map in %.0f ms.", #industries, #clusters, elapsed * 1000))
	return result
end


industry.INDUSTRY_DATA = INDUSTRY_DATA

industry.INDUSTRY_CLUSTER_FILENAME = INDUSTRY_CLUSTER_FILENAME
industry.INDUSTRY_RADIUS = INDUSTRY_RADIUS
industry.INDUSTRY_SIZE = INDUSTRY_SIZE
industry.INDUSTRY_AREA = INDUSTRY_AREA

return industry