function data()
	return {
		en = {
			["mod name"] = "Advanced Advanced Settings",
			["mod desc"] =
[[
Allows to change some game settings beyond their allowed values:
- Town and industry density
- Industry spawning and closure parameters

These settings will override any normal settings you set.
]],

			["param locs_makeInitialStreets"] = "Make initial streets",
			["param locs_town_maxNumberPerArea"] = "Towns: Max number per km²",
			--["param locs_town_maxNumberPerArea tip"] = "",
			["param locs_town_allowInRoughTerrain"] = "Towns: Allow in rough terrain",
			--["param locs_town_allowInRoughTerrain tip"] = "",
			["param locs_industry_maxNumberPerArea"] = "Industries: Max number per km²",
			--["param locs_industry_maxNumberPerArea tip"] = "",
			["param locs_industry_absoluteMinimum"] = "Industries: Absolute minimum",
			--["param locs_industry_absoluteMinimum tip"] = "",
			["param locs_industry_targetMaxNumberPerArea"] = "Industries: Max number per km² (target)",
			--["param locs_industry_targetMaxNumberPerArea tip"] = "",
			
			["param econ_industryDevelopment_spawnIndustries"] = "Industries: Enable Spawn",
			["param econ_industryDevelopment_spawnTargetTimeSpan"] = "Industries: Spawn Target Timespan",
			["param econ_industryDevelopment_spawnTargetTimeSpan tip"] = "Industries will reach their target number in approximately this amount of game time.",
			["param econ_industryDevelopment_spawnProbabilityExponent"] = "Industries: Spawn probability exponent",
			["param econ_industryDevelopment_spawnProbabilityExponent tip"] = "Determines how frequently new industries will spawn when below target number.",
			["param econ_industryDevelopment_closureCountdownTimeSpan"] = "Industries: Closure Countdown Timespan",
			["param econ_industryDevelopment_closureProbability"] = "Industries: Closure Probability exponent",
			["param econ_industryDevelopment_closureProbability tip"] = "Determines how likely an unused indistry will close.\nThe more industries there are on the map, the more frequent are the closures.",
		},
	}
end
