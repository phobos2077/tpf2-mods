local table_util = require "industry_placement/lib/table_util"
local cluster_config = require "industry_placement/cluster_config"

local industry = {}

local IndustryCategory = cluster_config.IndustryCategory

industry.Category = IndustryCategory

local INDUSTRY_RADIUS = 150

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
		return size[1] * size[2]
	end
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
	---@type Vec3f
	local position = api.type.Vec3f.new(vec4[1], vec4[2], vec4[3])
	---@class ClusterData
	local data = {
		id = id,
		cat = category,
		pos = position,
		shape = shape,
		size = size,
		area = getClusterArea(shape, size)
	}
	return data
end

---@return ClusterData[]
function industry.findAllClustersOnMap()
	local timer = os.clock()
	local ents = findAllConstructionIds()
	local clusters = {}
	for _, id in pairs(ents) do
		local constr = api.engine.getComponent(id, api.type.ComponentType.CONSTRUCTION)
		if constr and constr.fileName == INDUSTRY_CLUSTER_FILENAME then
			local clusterData = industry.getClusterDataFromConstruction(constr, id)
			if clusterData then
				clusters[#clusters+1] = clusterData
			end
		end
	end

	local elapsed = os.clock() - timer
	print(string.format("Found %d clusters on map in %.0f ms.", #clusters, elapsed * 1000))
	return clusters
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


function industry.findAllIndustriesAndClustersOnMap()
	local timer = os.clock()
	local ents = findAllConstructionIds()
	local idsByFileName = {_total = 0}
	local clustersByCategory = {_total = 0}
	for _, id in pairs(ents) do
		local constr = api.engine.getComponent(id, api.type.ComponentType.CONSTRUCTION)
		if constr then
			if constr.fileName == INDUSTRY_CLUSTER_FILENAME then
				local clusterData = industry.getClusterDataFromConstruction(constr, id)
				if clusterData then
					local clusterList = clustersByCategory[clusterData.cat] or {}
					clustersByCategory[clusterData.cat] = clusterList
					clusterList[#clusterList+1] = clusterData
					clustersByCategory._total = clustersByCategory._total + 1
				end
			elseif INDUSTRY_DATA[constr.fileName] then
				local ids = idsByFileName[constr.fileName] or {}
				idsByFileName[constr.fileName] = ids
				ids[#ids+1] = id
				idsByFileName._total = idsByFileName._total + 1
			end
		end
	end

	local elapsed = os.clock() - timer
	print(string.format("Found %d industries and %d clusters on map in %.0f ms.", idsByFileName._total, clustersByCategory._total, elapsed * 1000))
	return clustersByCategory, idsByFileName
end

function industry.getIndustryCategoryByFileName(fileName)
	local industryOutput = INDUSTRY_DATA[fileName][2]
	local firstOutput = next(industryOutput)
	return CATEGORY_BY_OUTPUT[firstOutput] or IndustryCategory.Other
end


industry.INDUSTRY_DATA = INDUSTRY_DATA

industry.INDUSTRY_CLUSTER_FILENAME = INDUSTRY_CLUSTER_FILENAME
industry.INDUSTRY_RADIUS = INDUSTRY_RADIUS

return industry