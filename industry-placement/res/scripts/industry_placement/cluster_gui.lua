local zoneutil = require "mission/zone"
local table_util = require "industry_placement/lib/table_util"
local vector2 = require "industry_placement/lib/vector2"
local industry = require "industry_placement/industry"

local cluster_gui = {}

local IndustryCategory = industry.Category

-- CONSTANTS

local CLUSTER_ZONE_COLORS = {
	-- TODO: colors to be more visible on terrain
	[IndustryCategory.Other] = {1,1,1,1},
	[IndustryCategory.Coal] = {0.2,0.2,0.2,1},
	[IndustryCategory.Iron] = {0.5,0.25,0,1},
	[IndustryCategory.Stone] = {0.65,0.65,0.65,1},
	[IndustryCategory.Crude] = {0.7,0.21,0.47,1},
	[IndustryCategory.Forest] = {0.68,0.49,0.36,1},
	[IndustryCategory.Distribution] = {0.13,0.58,0.62,1},
}
local ENTITY_VIEW_EVENT_EXP = "^temp%.view%.entity_(%d+)"


-- VARIABLES
local guiQueue = {}
local clusterZones = {}
local clustersByCategory = {}


---@param clusterData ClusterData
local function setClusterZone(id, clusterData)
	local zoneData = clusterData and {
		polygon = zoneutil.makeCircleZone(clusterData.pos, clusterData.radius),
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


local function validateClusterPlacement(clusterData, param)
	if clustersByCategory[clusterData.cat] then
		for k, otherClusterData in pairs(clustersByCategory[clusterData.cat]) do
			if vector2.distance(clusterData.pos, otherClusterData.pos) < clusterData.radius + otherClusterData.radius then
				param.data.errorState.critical = true
				param.data.errorState.messages = {_("Cluster Collision")}
			end
		end
	end
end

local function validateIndustryPlacement(con)
	local category = industry.getIndustryCategoryByFileName(con.fileName)
	if category ~= IndustryCategory.Other and clustersByCategory[category] then
		for k, clusterData in pairs(clustersByCategory[category]) do
			if vector2.distance(con.transf:cols(3), clusterData.pos) > clusterData.radius - industry.INDUSTRY_RADIUS then
				param.data.errorState.critical = true
				param.data.errorState.messages = {_("Outside of cluster")}
			end
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
					local otherClusters = clustersByCategory[clusterData.cat]
					otherClusters[#otherClusters+1] = clusterData
					setClusterZone(param.result[1], clusterData)
				end
			elseif con.fileName:find("^industry/") then
				validateIndustryPlacement(con)
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