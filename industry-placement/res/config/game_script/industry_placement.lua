local zoneutil = require "mission/zone"
local table_util = require "industry_placement/lib/table_util"
local vector2 = require "industry_placement/lib/vector2"


-- TYPES

local IndustryCategory = {
	Other = 1,
	Coal = 2,
	Iron = 3,
	Stone = 4,
	Crude = 5,
	Forest = 6,
	Distribution = 7
}


-- CONSTANTS

local INDUSTRY_DATA = {
	["industry/chemical_plant.con"] = {{distanceWeights={INPUT_OIL=-2,INPUT_PLASTIC=1},initWeight=1,tags={"INPUT_OIL"},buildOrder=14},{PLASTIC=1}},
	["industry/coal_mine.con"] = {{distanceWeights={INPUT_COAL=1,TOWN=-1},initWeight=4,buildOrder=11},{COAL=1}},
	["industry/construction_material.con"] = {{distanceWeights={INPUT_CONSTRUCTION_MATERIALS=1,INPUT_STONE=-2},initWeight=1,tags={"INPUT_STONE"},buildOrder=3},{CONSTRUCTION_MATERIALS=1}},
	["industry/farm.con"] = {{distanceWeights={INPUT_GRAIN=1,TOWN=-1},initWeight=4,tags={},buildOrder=2},{GRAIN=1}},
	["industry/food_processing_plant.con"] = {{distanceWeights={INPUT_FOOD=1,INPUT_GRAIN=-2},initWeight=1,tags={"INPUT_GRAIN"},buildOrder=1},{FOOD=1}},
	["industry/forest.con"] = {{distanceWeights={INPUT_LOGS=1,TOWN=-1},initWeight=4,buildOrder=8},{LOGS=1}},
	["industry/fuel_refinery.con"] = {{distanceWeights={INPUT_OIL=-2,INPUT_FUEL=1},initWeight=1,tags={"INPUT_OIL"},buildOrder=13},{FUEL=1}},
	["industry/goods_factory.con"] = {{distanceWeights={INPUT_GOODS=1,INPUT_PLASTIC=-1,INPUT_STEEL=-1},initWeight=1,tags={"INPUT_PLASTIC","INPUT_STEEL"},buildOrder=9},{GOODS=1}},
	["industry/iron_ore_mine.con"] = {{distanceWeights={INPUT_IRON_ORE=1,TOWN=-1},initWeight=4,buildOrder=12},{IRON_ORE=1}},
	["industry/machines_factory.con"] = {{distanceWeights={INPUT_PLANKS=-1,INPUT_MACHINES=1,INPUT_STEEL=-1},initWeight=1,tags={"INPUT_PLANKS","INPUT_STEEL"},buildOrder=6},{MACHINES=1}},
	["industry/oil_refinery.con"] = {{distanceWeights={INPUT_CRUDE=-2,INPUT_OIL=1},initWeight=2,tags={"INPUT_CRUDE"},buildOrder=15},{OIL=1}},
	["industry/oil_well.con"] = {{distanceWeights={INPUT_CRUDE=1,TOWN=-1},initWeight=4,buildOrder=16},{CRUDE=1}},
	["industry/quarry.con"] = {{distanceWeights={INPUT_STONE=1,TOWN=-1},initWeight=1,buildOrder=4},{STONE=1}},
	["industry/saw_mill.con"] = {{distanceWeights={INPUT_PLANKS=1,INPUT_LOGS=-2},initWeight=2,tags={"INPUT_LOGS"},buildOrder=7},{PLANKS=1}},
	["industry/steel_mill.con"] = {{distanceWeights={INPUT_COAL=-1,INPUT_IRON_ORE=-1,INPUT_STEEL=1},initWeight=2,tags={"INPUT_IRON_ORE","INPUT_COAL"},buildOrder=10},{STEEL=1}},
	["industry/tools_factory.con"] = {{distanceWeights={INPUT_PLANKS=-2,INPUT_TOOLS=1},initWeight=1,tags={"INPUT_PLANKS"},buildOrder=5},{TOOLS=1}},
}

local INDUSTY_INIT_WEIGHT_TOTAL = table_util.sum(INDUSTRY_DATA, function(d) return d[1].initWeight end)

local CATEGORY_BY_OUTPUT = {
	COAL = IndustryCategory.Coal,
	IRON_ORE = IndustryCategory.Iron,
	STONE = IndustryCategory.Stone,
	CRUDE = IndustryCategory.Crude,
	LOGS = IndustryCategory.Forest,
}

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

local PROCESS_INTERVAL = 10 -- in game time
local CLUSTER_RADIUSES = { 200, 400, 800, 1600, 3200 }
local MAX_PLACEMENT_ATTEMPTS = 10
local MAX_HEIGHT_DIFF = 30
local SPAWN_PROB = 0.1
local INDUSTRY_RADIUS = 150
local INDUSTRY_CLUSTER_FILENAME = "industry/industry_cluster.con"

-- VARIABLES

local nextProcessing
local state = {
	-- showZones = false,
	-- clusterZones = {}
}


-- FUNCTIONS

local function randomPointInCircle(pos, radius)
	local r = (radius or 1) * math.sqrt(math.random())
	local theta = math.random() * 2 * math.pi
	return {
		pos[1] + r * math.cos(theta),
		pos[2] + r * math.sin(theta)
	}
end

local function getWorldSize()
	local ter = api.engine.getComponent(game.interface.getWorld(), api.type.ComponentType.TERRAIN)
	return {
		ter.size.x / ter.baseResolution.x,
		ter.size.y / ter.baseResolution.y
	}
end


---@param constr userdata
---@param id number?
---@return ClusterData
local function getClusterDataFromConstruction(constr, id)
	if not (constr.params and constr.params.clusterCategory) then
		printPrint({"! ERROR ! Invalid cluster construction params: ", constr.params})
		return nil
	end
	local category = constr.params.clusterCategory + 1
	local radius = constr.params.clusterRadius and CLUSTER_RADIUSES[constr.params.clusterRadius+1] or 400
	local vec4 = constr.transf:cols(3)
	---@type Vec3f
	local position = api.type.Vec3f.new(vec4[1], vec4[2], vec4[3])
	---@class ClusterData
	local data = {
		id = id,
		pos = position,
		cat = category,
		radius = radius,
		area = math.pi*radius*radius
	}
	return data
end


local function placeIndustryProposal(fileName, name, pos)
	local newCon = api.type.SimpleProposal.ConstructionEntity.new()
	newCon.fileName = fileName
	newCon.params = {seed = 0}
	newCon.name = name
	newCon.transf = api.type.Mat4f.new(
		api.type.Vec4f.new(1, 0, 0, 0),
		api.type.Vec4f.new(0, 1, 0, 0),
		api.type.Vec4f.new(0, 0, 1, 0),
		api.type.Vec4f.new(pos[1], pos[2], pos[3], 1))

	-- newCon.playerEntity = api.engine.util.getPlayer()
	local proposal = api.type.SimpleProposal.new()
	proposal.constructionsToAdd[1] = newCon

	local context = api.type.Context:new()
	-- context.checkTerrainAlignment = true
	-- context.cleanupStreetGraph = true
	-- context.gatherBuildings = false -- default is false
	-- context.gatherFields = true -- default is true
	-- context.player = api.engine.util.getPlayer()
	return proposal, context
end

local function validateIndustryPlacement(fileName, pos)
	-- TODO: need to also prevent placement on very uneven terrain, such as on the mountain
	local vec2c = api.type.Vec2f.new
	local center = vec2c(pos[1], pos[2])
	local dist = INDUSTRY_RADIUS
	local heightPoints = {
		pos[3],
		api.engine.terrain.getBaseHeightAt(center + vec2c(dist,dist)),
		api.engine.terrain.getBaseHeightAt(center + vec2c(dist,-dist)),
		api.engine.terrain.getBaseHeightAt(center + vec2c(-dist,-dist)),
		api.engine.terrain.getBaseHeightAt(center + vec2c(-dist,dist))
	}
	table.sort(heightPoints)

	local heightDiff = heightPoints[#heightPoints] - heightPoints[1]
	if heightDiff > MAX_HEIGHT_DIFF then
		print("validateIndustryPlacement: FALSE, height diff is "..heightDiff)
		return false
	end

	local proposal, context = placeIndustryProposal(fileName, "test", pos)
	local proposalData = api.engine.util.proposal.makeProposalData(proposal, context)
	local errState = proposalData.errorState
	local result = not (errState.critical or false) and not (errState.messages and #errState.messages > 0 or false)
	if not result then
		debugPrint("validateIndustryPlacement: FALSE, error: "..(errState.messages and errState.messages[1] or "none")..", critical: "..tostring(errState.critical))
	end
	return result
end

local function createIndustry(fileName, name, pos, onComplete)
	local proposal, context = placeIndustryProposal(fileName, name, pos)
	debugPrint({"createIndustry", fileName, name, pos})
	api.cmd.sendCommand(api.cmd.make.buildProposal(proposal, context, true), function(cmd, result)
		if result then
			onComplete()
		else
			print("! ERROR ! Creating industry:"..cmd.resultProposalData.errorState.message)
		end
	end)
end

local function getIndustryRes(fileName)
	return api.res.constructionRep.get(api.res.constructionRep.find(fileName))
end

local function getClosestTown(position)
	local towns = game.interface.getEntities({pos = {position[1], position[2]}, radius = 1e10}, {type = "TOWN", includeData = true})
	local minDistance = math.huge
	local closestTown
	for id, townData in pairs(towns) do
		local distance = vector2.distance(position, townData.position)
		if distance < minDistance then
			minDistance = distance
			closestTown = townData
		end
	end
	return closestTown
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

local function findAllConstructionIds()
	return game.interface.getEntities({radius = 1e10}, {type = "CONSTRUCTION"})
end

local function findAllIndustriesAndClustersOnMap()
	local timer = os.clock()
	local ents = findAllConstructionIds()
	local idsByFileName = {_total = 0}
	local clustersByCategory = {_total = 0}
	for _, id in pairs(ents) do
		local constr = api.engine.getComponent(id, api.type.ComponentType.CONSTRUCTION)
		if constr then
			if constr.fileName == INDUSTRY_CLUSTER_FILENAME then
				local clusterData = getClusterDataFromConstruction(constr, id)
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

---@return ClusterData[]
local function findAllClustersOnMap()
	local timer = os.clock()
	local ents = findAllConstructionIds()
	local clusters = {}
	for _, id in pairs(ents) do
		local constr = api.engine.getComponent(id, api.type.ComponentType.CONSTRUCTION)
		if constr and constr.fileName == INDUSTRY_CLUSTER_FILENAME then
			local clusterData = getClusterDataFromConstruction(constr, id)
			if clusterData then
				clusters[#clusters+1] = clusterData
			end
		end
	end

	local elapsed = os.clock() - timer
	print(string.format("Found %d clusters on map in %.0f ms.", #clusters, elapsed * 1000))
	return clusters
end

local function selectIndustryToPlace(indsByFileName, targetTotalNum)
	local maxDiff = 0
	local minOrder = 9999999
	local selectedFileName
	local targetNumByFileName = {}
	for fileName, data in pairs(INDUSTRY_DATA) do
		local placementParams, ruleOutput = table.unpack(data)
		local targetNum = math.ceil(targetTotalNum * placementParams.initWeight / INDUSTY_INIT_WEIGHT_TOTAL)
		targetNumByFileName[fileName] = targetNum
		local actualNum = indsByFileName[fileName] and #indsByFileName[fileName] or 0
		local diff = targetNum - actualNum
		if diff > maxDiff or (diff == maxDiff and placementParams.buildOrder < minOrder) then
			maxDiff = diff
			minOrder = placementParams.buildOrder
			selectedFileName = fileName
		end
	end
	return selectedFileName
end

local function getIndustryCategoryByFileName(fileName)
	local industryOutput = INDUSTRY_DATA[fileName][2]
	local firstOutput = next(industryOutput)
	return CATEGORY_BY_OUTPUT[firstOutput] or IndustryCategory.Other
end

local function tryPlaceIndustry(fileName, clustersByCategory, idsByFileName)
	local category = getIndustryCategoryByFileName(fileName)
	local clusterList = clustersByCategory[category]
	local otherIndustryIds = idsByFileName[fileName]
	if not clusterList then
		print("No clusters for category "..category.." to spawn "..fileName.."!")
		return false
	end
	local totalArea = table_util.sum(clusterList, function(cluster) return cluster.area end)
	local validPosition
	local lastPos
	for i = 1, MAX_PLACEMENT_ATTEMPTS, 1 do
		local target = math.random() * totalArea
		local targetCluster
		local sum = 0
		for _, cluster in ipairs(clusterList) do
			sum = sum + cluster.area
			if sum > target then
				targetCluster = cluster
				break
			end
		end
	
		local pos = randomPointInCircle(targetCluster.pos, targetCluster.radius - INDUSTRY_RADIUS)
		lastPos = api.type.Vec3f.new(pos[1], pos[2], api.engine.terrain.getBaseHeightAt(api.type.Vec2f.new(pos[1], pos[2])))
		if validateIndustryPlacement(fileName, lastPos) then
			validPosition = lastPos
			break
		end
	end
	if not validPosition then
		print("Failed to find valid position for "..fileName.." after "..MAX_PLACEMENT_ATTEMPTS.." attempts!")
		debugPrint(lastPos)
		return false
	end

	local resData = getIndustryRes(fileName)
	local closestTown = getClosestTown(validPosition)
	local baseName = closestTown and string.format("%s %s", closestTown.name, resData.description.name) or resData.description.name
	local industryName = baseName

	-- Find unique name
	local otherIndustryNames = otherIndustryIds and table_util.mapDict(otherIndustryIds, function (id)
		return api.engine.getComponent(id, api.type.ComponentType.NAME).name, true
	end) or {}
	local i = 1
	while otherIndustryNames[industryName] and i < 99 do
		i = i + 1
		industryName = string.format("%s #%d", baseName, i)
	end
	createIndustry(fileName, industryName, validPosition, function()
		print("Created "..fileName.." Successfully!")
		if closestTown then
			api.cmd.sendCommand(api.cmd.make.connectTownsAndIndustries({closestTown.id}, {}, true), function(cmd, res)
				print("Connect town "..closestTown.name.." : "..tostring(res))
			end)
		end
	end)
	return true
end


local function processIndustries()
	local clustersByCategory, industriesByFileName = findAllIndustriesAndClustersOnMap()

	local totalIndustryNum = industriesByFileName._total
	local worldSize = getWorldSize()
	local worldSizeSqKm = worldSize[1] * worldSize[2]
	local targetDensity = game.config.locations.industry.targetMaxNumberPerArea
	local targetTotalNum = math.floor(worldSizeSqKm * targetDensity)

	local immediateSpawnTargetNum = math.floor(targetTotalNum / 2)

	debugPrint({"target data", worldSizeSqKm, targetDensity, targetTotalNum, totalIndustryNum, immediateSpawnTargetNum})

	local needToSpawn = (totalIndustryNum < immediateSpawnTargetNum) or (totalIndustryNum < targetTotalNum and math.random() < SPAWN_PROB)
	if not needToSpawn then
		return
	end

	local selectedFileName = selectIndustryToPlace(industriesByFileName, targetTotalNum)
	if not selectedFileName then
		debugPrint({"Failed to select industry type!", industriesByFileName, targetTotalNum})
		return
	end
	
	-- If selected, spawn industry in random position.
	local timer = os.clock()
	local placed = tryPlaceIndustry(selectedFileName, clustersByCategory, industriesByFileName)
	print(string.format("Requested place industry in %.0f ms : %s", os.clock() - timer, tostring(placed)))
end


-- GUI VARIABLES
local guiQueue = {}
local tmpZoneAt
local clusterZones = {}


-- GUI FUNCTIONS

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

local knownClustersByCategory = {}
local ENTITY_VIEW_EVENT_EXP = "^temp%.view%.entity_(%d+)"

function data()
	return {
		save = function()
			return state
		end,
		load = function(loadedState)
			state = loadedState or state
		end,
		update = function()
			-- api.res.getBaseConfig().costs.terrainRaise = math.random(4,40)
			local curTime = game.interface.getGameTime().time
			if not nextProcessing or curTime >= nextProcessing then
				if nextProcessing then
					math.randomseed(math.floor(curTime))
					processIndustries()
				end
				nextProcessing = curTime + PROCESS_INTERVAL
			end
		end,
		guiUpdate = function ()
			--[[if tmpZoneAt ~= nil and os.clock() - tmpZoneAt > 2 then
				setClusterZone("tmp", nil)
				tmpZoneAt = nil
			end]]

			if #guiQueue > 0 then
				for i, f in ipairs(guiQueue) do
					f()
				end
				guiQueue = {}
			end
		end,


		-- "temp.view.entity_55924", "idAdded",
		-- "temp.view.entity_55924", "window.close"

		guiHandleEvent = function(id, name, param)
			if name ~= "builder.apply" and name ~= "builder.proposalCreate" then
				debugPrint({"guiHandleEvent", id, name, param})
			end
			if id == "constructionBuilder" then
				local con = param.proposal and param.proposal.toAdd and param.proposal.toAdd[1]
				if con then
					if con.fileName == INDUSTRY_CLUSTER_FILENAME then
						if name == "builder.proposalCreate" then
							local clusterData = getClusterDataFromConstruction(con)
							setClusterZone("tmp", clusterData)
	
							if knownClustersByCategory[clusterData.cat] then
								for k, otherClusterData in pairs(knownClustersByCategory[clusterData.cat]) do
									if vector2.distance(clusterData.pos, otherClusterData.pos) < clusterData.radius + otherClusterData.radius then
										param.data.errorState.critical = true
										param.data.errorState.messages = {_("Cluster Collision")}
									end
								end
							end
						elseif name == "builder.apply" then
							setClusterZone(param.result[1], getClusterDataFromConstruction(con))
						end
					elseif con.fileName:find("^industry/") then
						local category = getIndustryCategoryByFileName(con.fileName)
						if category ~= IndustryCategory.Other and knownClustersByCategory[category] then
							for k, clusterData in pairs(knownClustersByCategory[category]) do
								if vector2.distance(con.transf:cols(3), clusterData.pos) > clusterData.radius - INDUSTRY_RADIUS then
									param.data.errorState.critical = true
									param.data.errorState.messages = {_("Outside of cluster")}
								end
							end
						end
					end
				end
			elseif id == "bulldozer" and name == "builder.apply" and #param.proposal.toRemove > 0 and clusterZones[param.proposal.toRemove[1]] then
				setClusterZone(param.proposal.toRemove[1], nil)
			elseif id == "menu.construction.industrymenu" and name == "visibilityChange" then
				if param then
					local clusterList = findAllClustersOnMap()
					knownClustersByCategory = table_util.groupBy(clusterList, function(cd) return cd.cat end)
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
					if con.fileName == INDUSTRY_CLUSTER_FILENAME then
						setClusterZone(entity, getClusterDataFromConstruction(con, entity))
					end
				elseif name == "window.close" then
					setClusterZone(entity, nil)
				end
			end
		end,
		handleEvent = function(src, id, name, param)
			-- if src ~= "guidesystem.lua" then
			-- 	debugPrint({"handleEvent", src, id, name, param})
			-- end
		end
	}
end