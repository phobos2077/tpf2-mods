local table_util = require "industry_placement/lib/table_util"
local vector2 = require "industry_placement/lib/vector2"
local world_util = require "industry_placement/world_util"
local industry = require "industry_placement/industry"
local cluster_gui = require "industry_placement/cluster_gui"
local cluster_config = require "industry_placement/cluster_config"

-- CONSTANTS
local PROCESS_INTERVAL = 10 -- in game time
local MAX_PLACEMENT_ATTEMPTS = 10
local MAX_HEIGHT_DIFF = 30
local SPAWN_PROB = 0.1

-- VARIABLES

local nextProcessing
local state = {
	-- showZones = false,
	-- clusterZones = {}
}


-- FUNCTIONS

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

local function getUniqueIndustryName(fileName, idsByFileName, closestTown)
	local otherIndustryIds = idsByFileName[fileName]
	local resData = getIndustryRes(fileName)
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
	return industryName
end

---@param clusterData ClusterData
---@return number[] pos
local function getRandomPointInCluster(clusterData)
	local industrySize = {industry.INDUSTRY_RADIUS, industry.INDUSTRY_RADIUS}
	local paddedSize = vector2.sub(clusterData.size, industrySize)
	if clusterData.shape == cluster_config.ClusterShape.Ellipse then
		return vector2.randomPointInEllipse(clusterData.pos, paddedSize)
	else
		return vector2.add(clusterData.pos, vector2.mul(paddedSize, {math.random(), math.random()}))
	end
end

local function tryPlaceIndustry(fileName, clustersByCategory, idsByFileName)
	local category = industry.getIndustryCategoryByFileName(fileName)
	local clusterList = clustersByCategory[category]
	if not clusterList then
		print("No clusters for category "..category.." to spawn "..fileName.."!")
		return false
	end
	-- TODO: use FREE area of clusters
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
	
		local pos = getRandomPointInCluster(targetCluster)
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

	local closestTown = world_util.getClosestTown(validPosition)
	local industryName = getUniqueIndustryName(fileName, idsByFileName, closestTown)
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
	local clustersByCategory, industriesByFileName = industry.findAllIndustriesAndClustersOnMap()

	local totalIndustryNum = industriesByFileName._total
	local worldSize = world_util.getWorldSize()
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
					math.randomseed(math.floor(curTime))
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