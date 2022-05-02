function data()
	return {
		en = {
			["mod name"] = "Progressive Income Tax",
			["mod desc"] = "Adds tax on your Operating Profit (Tickets minus Maintenance) with dynamic Tax Rate that changes in a non-linear fashion, approximating real-life progressive tax systems. "..
				"Tax is deducted at the beginning of every finance period (year) and uses your total Operating Profits over the last period (year) as a tax base. "..
				"Tax is displayed as \"Other\" in the finances window.\n\n"..
				"This allows you to set up a money sink, that will slow down money generation in late game, without making your early game start harder.\n\n"..
				"You can configure tax parameters as you like. For example, setting Minimum Tax Rate to 0% and increasing Minimum Taxable Profit Factor ensures there is no tax whatsoever in early game "..
				"until you reach a certain level of sustainable profits.",

			["param rate_min"] = "Tax Rate: Minimum",
			["param rate_min tip"] = "The minimum tax rate (amount of tax as percentage of your Operating Profit) at the lowest profit level.\nIf set above Maximum, a Maximum will be used as a constant rate.",

			["param rate_max"] = "Tax Rate: Maximum",
			["param rate_max tip"] = "The maximum tax rate.\nActual rate will never actually reach this value but will infinitely tend to it.",

			["param half_rate_base"] = "Half Rate Profit",
			["param half_rate_base tip"] = "At this level of Operating Profit, your Tax Rate will be exactly half-way between minimum and maximum.\n"..
				"Note that because tax rate is non-linear function, it raises much slower after this point towards the maximum.",

			["param taxable_min_factor"] = "Minimum Taxable Profit Factor",
			["param taxable_min_factor tip"] = "The minimum amount of profits, below which you always pay the minimum rate.\n"..
				"This is set as a percentage of Half Rate Profit.\nValues over 10% are not recommended and will result in big tax spikes when Minimum Taxable Profit is reached.",
		}
	}
end
