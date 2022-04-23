function data()
	return {
		en = {
			["mod name"] = "Rising Infrastructure Costs",
			["mod desc"] = "Incentifies building optimal infrastructure by increasing maintenance and build costs of tracks, roads, bridges, tunnels and stations.\n"..
				"Costs change dynamically as you progress through the years. So at 1850 you will mostly see the default low costs but they will gradually increase.",
			["param inflation_year_start"] = "Inflation start year",
			["param inflation_year_start tip"] = "Infrastructure costs will start to increase at this year.",
			["param inflation_year_end"] = "Inflation end year",
			["param inflation_year_end tip"] = "At this year, infrastructure costs will reach their maximum value and won't increase any further.",
			["param inflation_min"] = "Minium inflation",
			["param inflation_min tip"] = "Level of inflation at Start Year.",
			["param inflation_max"] = "Maximum inflation",
			["param inflation_max tip"] = "Maximum inflation level at End Year. Actual inflation curve is non linear and will rise slightrly faster towards end year.",
			["param mult_track_cost"] = "Tracks costs",
			["param mult_track_cost tip"] = "Construction and maintenance costs of tracks will be multiplied by this value, in addition to the inflation multiplier\n(only maintenance costs will inflate due to modding API limitation!)",
			["param mult_street_cost"] = "Roads costs",
			["param mult_street_cost tip"] = "Construction and maintenance costs of roads will be multiplied by this value, in addition to the inflation multiplier\n(only maintenance costs will inflate due to modding API limitation!)",
			["param mult_terrain"] = "Terrain modification costs",
			["param mult_terrain tip"] = "Flat modifier for terrain modification costs. Not affected by inflation.",
			["param mult_bridges_tunnels"] = "Bridges and tunnels costs",
			["param mult_bridges_tunnels tip"] = "Flat modifier for cost of tunnel and bridge construction.",
			["param mult_upgrade_track"] = "Track upgrades (catanery) relative cost",
			["param mult_upgrade_track tip"] = "This is relative to the cost of track itself. So setting track cost to 200% and upgrade cost to 200% will result in 400% increase of final upgrade cost.",
			["param mult_upgrade_street"] = "Street upgrades relative cost",
			["param mult_upgrade_street tip"] = "This is relative to the cost of street itself. So setting street cost to 200% and upgrade cost to 200% will result in 400% increase of final upgrade cost.",
			--["param constr cost"] = "Stations/Depos base costs",
			--["param constr cost"] = "Stations/Depos base costs",
			
		}
	}
end
