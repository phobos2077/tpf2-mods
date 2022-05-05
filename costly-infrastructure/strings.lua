function data()
	local multTip = {
		en = function(type)	return "Construction and maintenance costs for all pieces of "..type.." Infrastructure will be multiplied by this value\nin addition to dynamic scaling." end
	}
	local upgradeTip = {
		en = function(type) return "This is relative to the cost of "..type.." itself.\nE.g. setting Cost to 200% and Upgrades to 200% will result in 400% increase of final upgrade cost." end
	}
	local vehicleMultTip = {
		en = function(type)	return "This sets the upper limit for "..type.." Infrastructure Dynamic Build cost based on vehicle ratings." end
	}
	local maintMultTip = {
		en = function(type)	return "Additional multiplier for "..type.." Infrastructure Maintenance cost." end
	}
	return {
		en = {
			["mod name"] = "Dynamic Infrastructure Cost Scaling",
			["mod desc"] =
[[
Dynamically increases maintenance and build costs of various pieces of infrastructure, such as tracks, stations, depots, etc.
[list]
[*]Build costs increase based on effectiveness of currently available vehicles.
[*]Maintenance costs change based on intensity of use of stations.
[*]Additionally, static base cost multipliers are available for every piece of infrastructure.
[/list]

The mod is structured into 3 distinct parts.


[h3]Part 1 - Base Cost Multipliers[/h3]
These directly scale build and maintenance costs of all categories of infrastructure.
These multipliers are static, once configured, they don't change during the game. But they multiply the effects of dynamic multipliers.


[h3]Part 2 - Dynamic Build Costs[/h3]
Build costs of all stations and depos are scaled based on current vehicle power rating. This rating is calculated as follows:
[list]
[*]All vehicles available for purchase based on current year are taken and separated by categories (road, rail, water and air).
[*]For every vehicle a power rating is calculated. For locomotives, this is engine power. For all other types it's max speed times capacity.
[*]Highest score value is used in formula where 1 corresponds to some of the weakest vehicles and Build Cost Max - to some of the strongest.
This formula is non-linear, making the cost curve itself a bit more linear.
[/list]

If you set Base Cost Multiplier for category of infrastructure, it will multiply the result of dynamic scaling even more.
For example, if you set Road Base Cost to 200% and Road Build Cost Max to 5x, final price upper limit will be 10x.


[h3]Part 3 - Usage-based Infrastructure Costs[/h3]
Infrastructure costs are scaled independently from build costs and instead use a different formula:
[list]
[*]Total Capacity of all your stations for given category is calculated.
[*]Total Line Rates is calculated as sum of Rate value (as seen in UI) multiplied by number of stops over all stations.
[*]Final multiplier = (Total Rates / Total Capacity) * mult, where mult is configurable value per category.
[/list]
Base value for maintenance costs is 10% of purchase cost, just like in vanilla game.
But it is affected by Base Cost Multipliers and is scaled independently from build cost.


[h3]Known issues/limitations[/h3]
[list]
[*]Build costs of tracks and roads will not change dynamically (only affected by base multiplier). But maintenance costs will!
[*]Red floating numbers will keep showing the original unmodified maintenance costs. Rest assured, additional fees will be deducted from your account behind the scenes. You can monitor this in Finances window.
[*]Refund amounts for individual station modules will still be based on original (lower) module price, so you might get much less money back than you expect. This is also modding API limitation.
[*]If you add this mod to existing game where you set Maintenance Cost to something other than 100% and built a bunch of infrastructure, the calculations will be slightly off (in higher or lower direction) because of how the mod works.
[/list]
]],

			["param mult_street"] = "Base Cost: Road",
			["param mult_street tip"] = multTip.en("Road"),
			["param mult_rail"] = "Base Cost: Railroad",
			["param mult_rail tip"] = multTip.en("Railroad"),
			["param mult_water"] = "Base Cost: Water",
			["param mult_water tip"] = multTip.en("Water"),
			["param mult_air"] = "Base Cost: Air",
			["param mult_air tip"] = multTip.en("Air"),

			["param mult_bridges_tunnels"] = "Cost: Bridges and tunnels",
			["param mult_bridges_tunnels tip"] = "Flat modifier for cost of tunnel and bridge construction.\nNote that maintenance for bridges and tunnels after they are built will count towards either Road or Rail infrastructure.",
			["param mult_terrain"] = "Cost: Terrain",
			["param mult_terrain tip"] = "Flat modifier for terrain modification costs. Not affected by inflation.",
			["param mult_upgrade_track"] = "Upgrades: Tracks",
			["param mult_upgrade_track tip"] = upgradeTip.en("track"),
			["param mult_upgrade_street"] = "Upgrades: Roads",
			["param mult_upgrade_street tip"] = upgradeTip.en("road"),

			["param veh_mult_street"] = "Build Cost Max: Road",
			["param veh_mult_street tip"] = vehicleMultTip.en("Road"),
			["param veh_mult_rail"] = "Build Cost Max: Railroad",
			["param veh_mult_rail tip"] = vehicleMultTip.en("Railroad"),
			["param veh_mult_water"] = "Build Cost Max: Water",
			["param veh_mult_water tip"] = vehicleMultTip.en("Water"),
			["param veh_mult_air"] = "Build Cost Max: Air",
			["param veh_mult_air tip"] = vehicleMultTip.en("Air"),

			["param maint_mult_street"] = "Maintenance: Road",
			["param maint_mult_street tip"] = maintMultTip.en("Road"),
			["param maint_mult_rail"] = "Maintenance: Railroad",
			["param maint_mult_rail tip"] = maintMultTip.en("Railroad"),
			["param maint_mult_water"] = "Maintenance: Water",
			["param maint_mult_water tip"] = maintMultTip.en("Water"),
			["param maint_mult_air"] = "Maintenance: Air",
			["param maint_mult_air tip"] = maintMultTip.en("Air"),
		}
	}
end
