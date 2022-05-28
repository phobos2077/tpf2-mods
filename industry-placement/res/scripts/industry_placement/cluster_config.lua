local config_util = require "industry_placement/lib/config_util"
local table_util = require "industry_placement/lib/table_util"

local cluster_config = {}

local IndustryCategory = {
	Other = 1,
	Coal = 2,
	Iron = 3,
	Stone = 4,
	Crude = 5,
	Forest = 6,
	Distribution = 7
}

local ClusterShape = {
	Rect = 1,
	Ellipse = 2,
}

local function valuesFromEnum(enum)
	local values = {}
	for k, v in pairs(enum) do
		values[#values+1] = {v, _(k)}
	end
	table.sort(values, function(v1, v2) return v1[2] < v2[2] end)
	return values
end

local categoryValues = valuesFromEnum(IndustryCategory)
local shapeValues = valuesFromEnum(ClusterShape)
local sizeParamType = config_util.genParamLinear(nil, "SLIDER", 800, 400, 3200, 400)

local allParams = {
	{"clusterCategory", config_util.comboBoxParam(categoryValues, 1)},
	{"clusterShape", config_util.paramType(shapeValues, 1, nil, "BUTTON")},
	{"clusterSizeX", sizeParamType},
	{"clusterSizeY", sizeParamType},
}

cluster_config.IndustryCategory = IndustryCategory
cluster_config.ClusterShape = ClusterShape

function cluster_config.makeParams()
	return config_util.makeModParams(allParams)
end

function cluster_config.getActualParams(rawParams)
	return config_util.getActualParams(rawParams, allParams)
end

return cluster_config