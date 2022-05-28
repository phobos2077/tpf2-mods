local table_util = require "industry_placement/lib/table_util"
local vector2 = require "industry_placement/lib/vector2"
local box2 = require "industry_placement/lib/box2"
local industry = require "industry_placement/industry"
local world_util = require "industry_placement/world_util"
local cluster_config = require "industry_placement/cluster_config"

local cluster_gui = {}

local IndustryCategory = industry.Category
local ClusterShape = cluster_config.ClusterShape

-- CONSTANTS

local CLUSTER_ZONE_COLORS = {
	-- TODO: colors to be more visible on terrain
	[IndustryCategory.Other] = {1,1,1,1},
	[IndustryCategory.Coal] = {0.2,0.2,0.2,1},
	[IndustryCategory.Iron] = {0.5,0.25,0,1},
	[IndustryCategory.Stone] = {0.65,0.65,0.65,1},
	[IndustryCategory.Crude] = {0.7,0.21,0.47,1},
	[IndustryCategory.Forest] = {0.95,0.49,0.36,1},
	[IndustryCategory.Distribution] = {0.13,0.58,0.82,1},
}
local ENTITY_VIEW_EVENT_EXP = "^temp%.view%.entity_(%d+)"


-- VARIABLES
local guiQueue = {}
local clusterZones = {}
---@type table<number, ClusterData[]>
local clustersByCategory = {}

local function makeEllipseZone(pos, size)
	local num = math.pi * (size[1] + size[2])/50
	local result = { }
	for i = 1, num do
		local s = 2.0 * math.pi * (i - 1) / num
		result[i] = { pos[1] + size[1] * math.cos(s), pos[2] + size[2] * math.sin(s) }
	end
	return result
end

local function makeRectZone(pos, size)
	local result = {
		vector2.add(pos, vector2.mul(size, {1, 1})),
		vector2.add(pos, vector2.mul(size, {1, -1})),
		vector2.add(pos, vector2.mul(size, {-1, -1})),
		vector2.add(pos, vector2.mul(size, {-1, 1})),
	}
	return result
end

---@param clusterData ClusterData
local function makeClusterPolygon(clusterData)
	if clusterData.shape == ClusterShape.Ellipse then
		return makeEllipseZone(clusterData.pos, clusterData.size)
	else
		return makeRectZone(clusterData.pos, clusterData.size)
	end
end

---@param clusterData ClusterData
local function setClusterZone(id, clusterData)
	local zoneData = clusterData and {
		polygon = makeClusterPolygon(clusterData),
		draw = true,
		drawColor = CLUSTER_ZONE_COLORS[clusterData.cat] or {1,0,1,1}
	} or nil
	clusterZones[id] = zoneData
	game.interface.setZone("industry_cluster_"..id, zoneData)
end

local function clearClusterZones()
	local ids = table_util.tableKeys(clusterZones)
	for _, id in pairs(ids) do
		setClusterZone(id, nil)
	end
end

---@param clusterData ClusterData
---@param param userdata
local function validateClusterPlacement(clusterData, param)
	local worldHalfSize = vector2.mul(world_util.getWorldSizeCached(), 500)
	local worldBox = box2.fromPosAndSize({0, 0}, worldHalfSize)
	if not worldBox:contains(clusterData.box) then
		param.data.errorState.critical = true
		param.data.errorState.messages = {_("Cluster outside of world")}
	elseif clustersByCategory[clusterData.cat] then
		for k, otherClusterData in pairs(clustersByCategory[clusterData.cat]) do
			if clusterData.box:intersects(otherClusterData.box) then
				param.data.errorState.critical = true
				param.data.errorState.messages = {_("Cluster collision")}
				break
			end
		end
	end
end

local function validateIndustryPlacement(con, param)
	local category = industry.getIndustryCategoryByFileName(con.fileName)
	if category ~= IndustryCategory.Other and clustersByCategory[category] then
		local industryBox = box2.fromPosAndSize(con.transf:cols(3), industry.INDUSTRY_SIZE)
		local isFound = false
		for k, clusterData in pairs(clustersByCategory[category]) do
			if clusterData.box:contains(industryBox) then
				isFound = true
				break
			end
		end
		if not isFound then
			param.data.errorState.critical = true
			param.data.errorState.messages = {_("Outside of cluster")}
		end
	end
end


function cluster_gui.load(loadedState)
end

function cluster_gui.guiUpdate()
	if #guiQueue > 0 then
		for i, f in ipairs(guiQueue) do
			f()
		end
		guiQueue = {}
	end
end


-- "temp.view.entity_55924", "idAdded",
-- "temp.view.entity_55924", "window.close"

function cluster_gui.guiHandleEvent(id, name, param)
	if id == "constructionBuilder" then
		local con = param.proposal and param.proposal.toAdd and param.proposal.toAdd[1]
		if con then
			if con.fileName == industry.INDUSTRY_CLUSTER_FILENAME then
				if name == "builder.proposalCreate" then
					local clusterData = industry.getClusterDataFromConstruction(con)
					setClusterZone("tmp", clusterData)
					validateClusterPlacement(clusterData, param)
				elseif name == "builder.apply" then
					local clusterData = industry.getClusterDataFromConstruction(con)
					local otherClusters = clustersByCategory[clusterData.cat] or {}
					clustersByCategory[clusterData.cat] = otherClusters
					otherClusters[#otherClusters+1] = clusterData
					setClusterZone(param.result[1], clusterData)
				end
			elseif con.fileName:find("^industry/") then
				validateIndustryPlacement(con, param)
			end
		end
	elseif id == "bulldozer" and name == "builder.apply" and #param.proposal.toRemove > 0 and clusterZones[param.proposal.toRemove[1]] then
		setClusterZone(param.proposal.toRemove[1], nil)
	elseif id == "menu.construction.industrymenu" and name == "visibilityChange" then
		if param then
			local clusterList = industry.findAllClustersOnMap()
			clustersByCategory = table_util.igroupBy(clusterList, function(cd) return cd.cat end)
			for i, clusterData in ipairs(clusterList) do
				setClusterZone(clusterData.id, clusterData)
			end
		else
			clearClusterZones()
		end
	elseif id:find(ENTITY_VIEW_EVENT_EXP) then
		local entity = tonumber(id:match(ENTITY_VIEW_EVENT_EXP))
		if name == "idAdded" then
			local con = api.engine.getComponent(entity, api.type.ComponentType.CONSTRUCTION)
			if con.fileName == industry.INDUSTRY_CLUSTER_FILENAME then
				setClusterZone(entity, industry.getClusterDataFromConstruction(con, entity))
			end
		elseif name == "window.close" then
			setClusterZone(entity, nil)
		end
	end
end

return cluster_gui