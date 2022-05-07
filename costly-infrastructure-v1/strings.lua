function data()
	local inflationTip = {
		en = function (type, limitationType)
			local limitation = limitationType and "(except for "..limitationType..", due to modding API limitation)" or ""
			return "Maximum inflation level (cost multiplier) at End Year for "..type.." Infrastructure.\nThis affects both maintenance AND build costs"..limitation..".\nActual inflation curve is non linear and will rise slightly faster towards end year."
		end
	}
	local multTip = {
		en = function(type)	return "Construction and maintenance costs for all pieces of "..type.." Infrastructure will be multiplied by this value,\nin addition to the inflation multiplier." end
	}
	local upgradeTip = {
		en = function(type) return "This is relative to the cost of "..type.." itself.\nE.g. setting Cost to 200% and Upgrades to 200% will result in 400% increase of final upgrade cost." end
	}
	return {
		en = {
			["mod name"] = "Dynamic Infrastructure Costs v1 (Inflation)",
			["mod desc"] =
[[
!! IMPORTANT:
- Requires Spring 2022 Update (beta), see note below

Incentivizes building optimal infrastructure by increasing maintenance and build costs of various pieces of infrastructure, such as tracks, stations, depots, etc.
Costs change dynamically and non-linearly as you progress through the years. So at 1850 you will mostly see the default low costs but they will gradually increase.
Maintenance costs will keep increasing even for previously constructed pieces of infrastructure, so make sure to get rid of unused stuff to prevent extra costs piling up!

See tooltips for every slider for additional information.


>> Compatibility with new Advanced Settings (Spring 2022 Update):

- Infrastructure Build Costs should work as you expect and act as additional multiplier on top of Cost setting. But it's recommended to set it to 100% to simplify the math.
- Infrastructure Maintenance Costs MUST be set at 100% in Advanced Settings, otherwise calculations for extra maintenance costs will be slightly off the expected value.


>> Known issues/limitations:

- Build costs of tracks and roads will not be affected by inflation, due to modding API limitations. But maintenance costs will!
- Red floating numbers will keep showing the original unmodified maintenance costs. Rest assured, additional fees will be deducted from your account behind the scenes. You can monitor this in Finances window.
- Refund amounts for individual station modules will still be based on original (lower) module price, so you might get much less money back than you expect. This is also modding API limitation.
- If you add this mod to existing game where you set Maintenance Cost to something other than 100% and built a bunch of infrastructure, the calculations will be slightly off (in higher or lower direction) because of how the mod works.
]],
			["param inflation_year_start"] = "Inflation Start Year",
			["param inflation_year_start tip"] = "Infrastructure costs will start to increase at this year.",
			["param inflation_year_end"] = "Inflation End Year",
			["param inflation_year_end tip"] = "At this year, infrastructure costs will reach their maximum value and won't increase any further.",
			["param inflation_exponent"] = "Inflation Curvature",
			["param inflation_exponent tip"] = "Controls how much curvature the cost/year graph has. Basically changes the exponent of underlying formula, while keeping the max inflation the same.",

			["param inflation_street"] = "Max Inflation: Road",
			["param inflation_street tip"] = inflationTip.en("Road", "roads"),
			["param inflation_rail"] = "Max Inflation: Railroad",
			["param inflation_rail tip"] = inflationTip.en("Railroad", "tracks"),
			["param inflation_water"] = "Max Inflation: Water",
			["param inflation_water tip"] = inflationTip.en("Water"),
			["param inflation_air"] = "Max Inflation: Air",
			["param inflation_air tip"] = inflationTip.en("Air"),

			["param mult_street"] = "Cost: Road",
			["param mult_street tip"] = multTip.en("Road"),
			["param mult_rail"] = "Cost: Railroad",
			["param mult_rail tip"] = multTip.en("Railroad"),
			["param mult_water"] = "Cost: Water",
			["param mult_water tip"] = multTip.en("Water"),
			["param mult_air"] = "Cost: Air",
			["param mult_air tip"] = multTip.en("Air"),

			["param mult_bridges_tunnels"] = "Cost: Bridges and tunnels",
			["param mult_bridges_tunnels tip"] = "Flat modifier for cost of tunnel and bridge construction.\nNote that maintenance for bridges and tunnels after they are built will count towards either Road or Rail infrastructure.",
			["param mult_terrain"] = "Cost: Terrain",
			["param mult_terrain tip"] = "Flat modifier for terrain modification costs. Not affected by inflation.",
			["param mult_upgrade_track"] = "Upgrades: Tracks",
			["param mult_upgrade_track tip"] = upgradeTip.en("track"),
			["param mult_upgrade_street"] = "Upgrades: Roads",
			["param mult_upgrade_street tip"] = upgradeTip.en("road"),
		}
	}
end
