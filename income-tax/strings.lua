function data()
	return {
		en = {
			["mod name"] = "Progressive Income Tax",
			["mod desc"] = "Adds tax on your Operating Income (income minus investments) with dynamic Tax Rate that changes in a non-linear fashion, approximating real-life progressive tax systems. "..
				"Tax is deducted at the beginning of every finance period and uses your total income (minus investments) over the last period as a tax base.\n\n"..
				"This allows you to set up a money sink, that will slow down money generation in late game, without making your early game start harder.\n\n"..
				"You can configure tax parameters as you like. For example, setting Minimum Tax Rate to 0% and increasing Minimum Taxable Income Factor ensures there is no tax whatsoever in early game "..
				"until you reach a certain level of income.",

			["param rate_min"] = "Tax Rate: Minimum",
			["param rate_min tip"] = "The minimum tax rate (amount of tax as percentage of your operating income) at the lowest income level.",

			["param rate_max"] = "Tax Rate: Maximum",
			["param rate_max tip"] = "The maximum tax rate.\nActual rate will never actually reach this value but will infinitely tend to it.",

			["param half_rate_base"] = "Half Rate Income",
			["param half_rate_base tip"] = "At this level of operating income, your Tax Rate will be exactly half-way between minimum and maximum.\n"..
				"Note that because tax rate is non-linear function, it raises much slower after this point towards the maximum.",

			["param taxable_min_factor"] = "Minimum Taxable Income Factor",
			["param taxable_min_factor tip"] = "The minimum amount of income, below which you always pay the minimum rate.\n"..
				"This is set as a percentage of Half Rate Income.\nValues over 10% are not recommended and will result in big tax spikes when Minimum Taxable Income is reached.",
		}
	}
end
