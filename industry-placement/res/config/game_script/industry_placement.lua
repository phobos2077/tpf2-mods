local zoneutil = require "mission/zone"
local table_util = require "industry_placement/lib/table_util"

local nextUpdate

local knownConstructions = {}

local industryData = {
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

local IndustryCategory = {
	Other = 1,
	Coal = 2,
	Iron = 3,
	Stone = 4,
	Crude = 5,
	Forest = 6,
	Distribution = 7
}

local categoryByOutput = {
	COAL = IndustryCategory.Coal,
	IRON_ORE = IndustryCategory.Iron,
	STONE = IndustryCategory.Stone,
	CRUDE = IndustryCategory.Crude,
	LOGS = IndustryCategory.Forest,
}

local industryPlacementTotalWeight = table_util.sum(industryData, function(d) return d[1].initWeight end)

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

local clusterZoneColors = {
	[IndustryCategory.Other] = {1,1,1,1},
	[IndustryCategory.Coal] = {0.2,0.2,0.2,1},
	[IndustryCategory.Iron] = {0.5,0.25,0,1},
	[IndustryCategory.Stone] = {0.65,0.65,0.65,1},
	[IndustryCategory.Crude] = {0.7,0.21,0.47,1},
	[IndustryCategory.Forest] = {0.68,0.49,0.36,1},
	[IndustryCategory.Distribution] = {0.13,0.58,0.62,1},
}

local clusterRadiuses = { 200, 400, 800, 1600, 3200 }

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
	local proposal, context = placeIndustryProposal(fileName, "test", pos)
	local proposalData = api.engine.util.proposal.makeProposalData(proposal, context)
	debugPrint({"validateIndustryPlacement", fileName, pos, proposalData.errorState})
	return not (proposalData.errorState.critical or false)
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
	local townIds = game.interface.getEntities({pos = {position[1], position[2]}, radius = 1e10}, {type = "TOWN", includeData = true})
end

local function processIndustries()
	local ents = game.interface.getEntities({radius = 1e10}, {type = "CONSTRUCTION"})
	local numByType = {}
	local clustersByCategory = {}
	for _, id in pairs(ents) do
		local constr = api.engine.getComponent(id, api.type.ComponentType.CONSTRUCTION)
		if constr and constr.fileName:find("^industry") then
			if constr.fileName == "industry/industry_cluster.con" then
				knownConstructions[id] = true
				-- debugPrint({id, constr.params, game.interface.setZone, constr.transf:cols(0)})
				-- api.cmd.sendCommand(api.cmd.make.sendScriptEvent("test_script","__cluster__","set_zone",id))

				--game.interface.setZone("industry_cluster_"..id, {polygon = zoneutil.makeCircleZone()})
				if constr.params and constr.params.clusterCategory then
					local category = constr.params.clusterCategory + 1
					local radius = constr.params.clusterRadius and clusterRadiuses[constr.params.clusterRadius+1] or 400
					local vec4 = constr.transf:cols(3)
					local position = api.type.Vec3f.new(vec4[1], vec4[2], vec4[3])
					local clusterList = clustersByCategory[category] or {}
					clustersByCategory[category] = clusterList
					clusterList[#clusterList+1] = {pos = position, cat = category, radius = radius, area = 2*math.pi*radius}
					game.interface.setZone("industry_cluster_"..id, {
						polygon = zoneutil.makeCircleZone(position, radius),
						draw = true,
						drawColor = clusterZoneColors[category] or {1,0,1,1}
					})
				end
			elseif industryData[constr.fileName] then
				numByType[constr.fileName] = (numByType[constr.fileName] or 0) + 1
			end
		end
	end

	local worldSize = getWorldSize()
	local worldSizeSqKm = worldSize[1] * worldSize[2]
	local targetDensity = game.config.locations.industry.targetMaxNumberPerArea
	local targetTotalNum = math.floor(worldSizeSqKm * targetDensity)

	--[[local targetNumByType = {}
	for fileName, placementParams in pairs(industryPlacementParams) do
		table.insert(targetNumByType, {fileName, placementParams})
	end
	table.sort(targetNumByType)]]
	-- local targetNumByType = table_util.map(industryPlacementParams, function(p) return targetTotalNum * p.initWeight / totalWeight end)
	local maxDiff = 0
	local minOrder = 9999999
	local selectedFileName
	for fileName, data in pairs(industryData) do
		local placementParams, ruleOutput = table.unpack(data)
		local targetNum = targetTotalNum * placementParams.initWeight / industryPlacementTotalWeight
		local actualNum = numByType[fileName] or 0
		local diff = targetNum - actualNum
		if diff > maxDiff or (diff == maxDiff and placementParams.buildOrder < minOrder) then
			maxDiff = diff
			minOrder = placementParams.buildOrder
			selectedFileName = fileName
		end
	end

	if selectedFileName then
		local resData = getIndustryRes(selectedFileName)
		local industryOutput = industryData[selectedFileName][2]
		local firstOutput = next(industryOutput)
		local category = categoryByOutput[firstOutput] or IndustryCategory.Other
		local clusterList = clustersByCategory[category]
		if clusterList then
			local totalArea = table_util.sum(clusterList, function(cluster) return cluster.area end)
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
			local validPosition
			local lastPos
			for i = 1, 5, 1 do
				local pos = randomPointInCircle(targetCluster.pos, targetCluster.radius)
				lastPos = api.type.Vec3f.new(pos[1], pos[2], api.engine.terrain.getBaseHeightAt(api.type.Vec2f.new(pos[1], pos[2])))
				if validateIndustryPlacement(selectedFileName, lastPos) then
					validPosition = lastPos
					break
				end
			end
			if validPosition then
				createIndustry(selectedFileName, resData.description.name, validPosition, function()
					print("Created "..selectedFileName.." Successfully!")	
				end)
			else
				print("Failed to find valid position for "..selectedFileName.." after 5 attempts!")
				debugPrint(lastPos)
			end
		else
			print("No clusters for category "..category.." to spawn "..selectedFileName.."!")
		end
	end
end


function data()
	return {
		save = function()
		end,
		load = function(loadedState)
		end,
		update = function()
			-- api.res.getBaseConfig().costs.terrainRaise = math.random(4,40)
			local curTime = game.interface.getGameTime().time
			if not nextUpdate or curTime >= nextUpdate then
				processIndustries()
				nextUpdate = curTime + 10
			end
		end,
		guiHandleEvent = function(id, name, param)
			-- if id ~= "constructionBuilder" then
			-- 	debugPrint({"guiHandleEvent", id, name, param})
			-- end
		end,
		handleEvent = function(src, id, name, param)
			-- if src ~= "guidesystem.lua" then
			-- 	debugPrint({"handleEvent", src, id, name, param})
			-- end
		end
	}
end