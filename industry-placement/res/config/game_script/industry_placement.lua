local table_util = require "industry_placement/lib/table_util"
local vector2 = require "industry_placement/lib/vector2"
local log_util = require "industry_placement/lib/log_util"
local world_util = require "industry_placement/world_util"
local industry = require "industry_placement/industry"
local cluster_gui = require "industry_placement/cluster_gui"
local cluster_config = require "industry_placement/cluster_config"

-- CONSTANTS
local PROCESS_INTERVAL = 10 -- in game time
local MAX_PLACEMENTS_AT_ONCE = 20
local MAX_POSITION_ATTEMPTS = 10
local MAX_HEIGHT_DIFF = 30
local MIN_INDUSTRY_SPACING = 300
local SPAWN_PROB = 0.1
local LOG_TAG = "Industry Placement"

local IndustryCategory = cluster_config.IndustryCategory

-- VARIABLES

local nextProcessing
local state = {
	-- showZones = false,
	-- clusterZones = {}
}

local pendingProcess = false

-- FUNCTIONS

local function placeIndustryProposalConstruction(fileName, name, pos)
	local newCon = api.type.SimpleProposal.ConstructionEntity.new()
	newCon.fileName = fileName

	-- TODO: pass default param values?
	newCon.params = {seed = 0}
	newCon.name = name
	newCon.transf = api.type.Mat4f.new(
		api.type.Vec4f.new(1, 0, 0, 0),
		api.type.Vec4f.new(0, 1, 0, 0),
		api.type.Vec4f.new(0, 0, 1, 0),
		api.type.Vec4f.new(pos[1], pos[2], pos[3], 1))

	-- newCon.playerEntity = api.engine.util.getPlayer()

	return newCon
end

local function placeIndustryProposal(fileName, name, pos)
	local proposal = api.type.SimpleProposal.new()
	proposal.constructionsToAdd[1] = placeIndustryProposalConstruction(fileName, name, pos)

	local context = api.type.Context:new()
	-- context.checkTerrainAlignment = true
	-- context.cleanupStreetGraph = true
	-- context.gatherBuildings = false -- default is false
	-- context.gatherFields = true -- default is true
	-- context.player = api.engine.util.getPlayer()
	return proposal, context
end

local function validateIndustryPlacement(fileName, pos, pendingPositions)
	local LOG_TAG = "validateIndustryPlacement"

	-- Validate distance to other industries in proposal
	for i, otherPos in ipairs(pendingPositions) do
		if vector2.distance(pos, otherPos) < MIN_INDUSTRY_SPACING then
			log_util.logFormat(LOG_TAG, "FAIL: Found another industry in proposal at position (%.0f, %.0f)", pos[1], pos[2])
			return false	
		end
	end

	-- Validate distance to other industries in world
	if world_util.anyConstructionInRadius(pos, MIN_INDUSTRY_SPACING) then
		log_util.logFormat(LOG_TAG, "FAIL: Found another industry in world at position (%.0f, %.0f)", pos[1], pos[2])
		return false
	end

	-- Validate terrain
	local vec2c = api.type.Vec2f.new
	local center = vec2c(pos[1], pos[2])
	local dist = industry.INDUSTRY_RADIUS
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
		log_util.logFormat(LOG_TAG, "FAIL: Height diff is %.0f", heightDiff)
		return false
	end

	-- Validate actual proposal
	local proposal, context = placeIndustryProposal(fileName, "test", pos)
	local proposalData = api.engine.util.proposal.makeProposalData(proposal, context)
	local errState = proposalData.errorState
	local result = not (errState.critical or false) and not (errState.messages and #errState.messages > 0 or false)
	if not result then
		log_util.logFormat(LOG_TAG, "FAIL: proposal error: %s, critical: %s", errState.messages and errState.messages[1], errState.critical)
	end
	return result
end

local function getIndustryRes(fileName)
	return api.res.constructionRep.get(api.res.constructionRep.find(fileName))
end


local function selectIndustryToPlace(indsByFileName, targetTotalNum)
	local maxDiff = 0
	local minOrder = 9999999
	local selectedFileName
	local targetNumByFileName = {}
	for fileName, data in pairs(industry.INDUSTRY_DATA) do
		local placementParams, ruleOutput = table.unpack(data)
		local targetNum = math.ceil(targetTotalNum * data.relativeWeight)
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

local function getUniqueIndustryName(fileName, indsByFileName, closestTown)
	local otherIndustries = indsByFileName[fileName]
	local resData = getIndustryRes(fileName)
	local baseName = closestTown and string.format("%s %s", closestTown.name, resData.description.name) or resData.description.name
	local industryName = baseName

	-- Find unique name
	local otherIndustryNames = otherIndustries and table_util.mapDict(otherIndustries, function (data)
		local name = data.name and data.name or api.engine.getComponent(data.id, api.type.ComponentType.NAME).name
		return name, true
	end) or {}
	local i = 1
	while otherIndustryNames[industryName] and i < 99 do
		i = i + 1
		industryName = string.format("%s #%d", baseName, i)
	end
	return industryName
end

---@param clusterData ClusterData
---@return number[] pos
local function getRandomPointInCluster(clusterData)
	local paddedSize = vector2.sub(clusterData.size, industry.INDUSTRY_SIZE)
	if clusterData.shape == cluster_config.ClusterShape.Ellipse then
		return vector2.randomPointInEllipse(clusterData.pos, paddedSize)
	else
		return vector2.randomPointInBox(clusterData.pos, paddedSize)
	end
end

local function randomPointInClusterGenerator(clusterList)
	-- TODO: use FREE area of clusters
	local totalArea = table_util.sum(clusterList, function(cluster) return cluster.area end)
	return function()
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
	
		return getRandomPointInCluster(targetCluster)
	end
end

local function randomPointInWorldGenerator()
	local worldSize = vector2.mul(world_util.getWorldSizeCached(), 500)
	local paddedSize = vector2.sub(worldSize, industry.INDUSTRY_SIZE)
	return function(s, v)
		return vector2.randomPointInBox({0, 0}, paddedSize)
	end
end

local function findValidPositionForIndustry(fileName, clustersByCategory, pendingPositions)
	local category = industry.getIndustryCategoryByFileName(fileName)
	local clusterList = clustersByCategory[category]
	local randomPointGenerator
	if clusterList then
		randomPointGenerator = randomPointInClusterGenerator(clusterList)
	else
		if category == IndustryCategory.Other then
			randomPointGenerator = randomPointInWorldGenerator()
		else
			log_util.logErrorFormat(LOG_TAG, "No clusters for category %s to spawn %s !", category, fileName)
			return false
		end
	end
	local validPosition
	local lastPos
	for i = 1, MAX_POSITION_ATTEMPTS, 1 do
		local pos = randomPointGenerator()
		lastPos = api.type.Vec3f.new(pos[1], pos[2], api.engine.terrain.getBaseHeightAt(api.type.Vec2f.new(pos[1], pos[2])))
		if validateIndustryPlacement(fileName, lastPos, pendingPositions) then
			validPosition = lastPos
			break
		end
	end
	if not validPosition then
		log_util.logErrorFormat(LOG_TAG, "Failed to find valid position for %s after %d attempts!", fileName, MAX_POSITION_ATTEMPTS)
		debugPrint(lastPos)
		return false
	end
	return validPosition
end


local function processIndustries()
	if pendingProcess then
		log_util.log(LOG_TAG, "Trying to process industries before previous commands completed, failing...")
		return false
	end

	local allIndustries = industry.findAllPlaceableIndustriesOnMap()

	local totalIndustryNum = #allIndustries
	local worldSize = world_util.getWorldSizeCached()
	local worldSizeSqKm = worldSize[1] * worldSize[2]
	local targetDensity = game.config.locations.industry.targetMaxNumberPerArea
	local targetTotalNum = math.floor(worldSizeSqKm * targetDensity)

	local immediateSpawnTargetNum = math.floor(targetTotalNum / 2)

	local toCreateNum = (totalIndustryNum < immediateSpawnTargetNum and math.min(immediateSpawnTargetNum - totalIndustryNum, MAX_PLACEMENTS_AT_ONCE))
		or (totalIndustryNum < targetTotalNum and math.random() < SPAWN_PROB and 1)
		or 0

	debugPrint({"target data", worldSizeSqKm, targetDensity, targetTotalNum, totalIndustryNum, immediateSpawnTargetNum, toCreateNum})

	if toCreateNum <= 0 then
		return
	end

	local clustersByCategory = table_util.igroupBy(industry.findAllClustersOnMap(), function(cd) return cd.cat end)
	local industriesByFileName = table_util.igroupBy(allIndustries, function(data) return data.fileName end)
	local townIdsSet = {}

	local prepareTimer = log_util.timer()
	local proposal = api.type.SimpleProposal.new()
	local pendingPositions = {}
	for i = 1, toCreateNum, 1 do
		local fileName = selectIndustryToPlace(industriesByFileName, targetTotalNum)
		if not fileName then
			log_util.logError(LOG_TAG, "Failed to select industry type!")
			break
		end
		
		-- If selected, spawn industry in random position.
		local industryPosition = findValidPositionForIndustry(fileName, clustersByCategory, pendingPositions)
		if not industryPosition then break end
	
		local closestTown = world_util.getClosestTown(industryPosition)
		local industryName = getUniqueIndustryName(fileName, industriesByFileName, closestTown)

		local proposalCon = placeIndustryProposalConstruction(fileName, industryName, industryPosition)
		proposal.constructionsToAdd[#proposal.constructionsToAdd+1] = proposalCon
		if closestTown then
			townIdsSet[closestTown.id] = true
		end
		industriesByFileName[fileName] = industriesByFileName[fileName] or {}
		table.insert(industriesByFileName[fileName], proposalCon)
		pendingPositions[#pendingPositions+1] = industryPosition
	end
	log_util.logFormatTimer(LOG_TAG, "Prepared %d industries for proposal", #proposal.constructionsToAdd, prepareTimer)

	if #proposal.constructionsToAdd > 0 then
		pendingProcess = true
		local buildCmdTimer = log_util.timer()
		api.cmd.sendCommand(api.cmd.make.buildProposal(proposal, nil, true), function(cmd, success)
			if success then
				log_util.logFormatTimer(LOG_TAG, "Build proposal succeeded!", buildCmdTimer)
				local townIdsList = table_util.tableKeys(townIdsSet)
				if #townIdsList > 0 then
					local connectCmdTimer = log_util.timer()
					api.cmd.sendCommand(api.cmd.make.connectTownsAndIndustries(townIdsList, {}, true), function(cmd2, success2)
						log_util.logFormatTimer(LOG_TAG, "Connected %d towns to industries: %s", #townIdsList, success2, buildCmdTimer)
						pendingProcess = false
					end)
				else
					pendingProcess = false
				end
			else
				log_util.logErrorFormat(LOG_TAG, "Creating industries: %s", cmd.resultProposalData.errorState.message)
			end
		end)
	end
end


function data()
	return {
		save = function()
			return state
		end,
		load = function(loadedState)
			state = loadedState or state
			if game.interface and game.interface.sendScriptEvent then
				cluster_gui.load(loadedState)
			end
		end,
		update = function()
			-- api.res.getBaseConfig().costs.terrainRaise = math.random(4,40)
			local curTime = game.interface.getGameTime().time
			if not nextProcessing or curTime >= nextProcessing then
				if nextProcessing then
					math.randomseed(math.floor(os.clock() * 1000))
					processIndustries()
				end
				nextProcessing = curTime + PROCESS_INTERVAL
			end
		end,
		handleEvent = function(src, id, name, param)
			-- if src ~= "guidesystem.lua" then
			-- 	debugPrint({"handleEvent", src, id, name, param})
			-- end
		end,
		guiUpdate = function ()
			cluster_gui.guiUpdate()
		end,
		guiHandleEvent = function(id, name, param)
			-- if name ~= "builder.apply" and name ~= "builder.proposalCreate" then
			-- 	debugPrint({"guiHandleEvent", id, name, param})
			-- end
			cluster_gui.guiHandleEvent(id, name, param)
		end,
	}
end