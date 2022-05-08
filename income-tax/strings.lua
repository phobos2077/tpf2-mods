function data()
	return {
		en = {
			["mod name"] = "Progressive Income Tax",
			["mod desc"] =
[[
Adds tax on your Operating Profit (Tickets minus Maintenance) with dynamic Tax Rate that changes in a non-linear fashion, approximating real-life progressive tax systems.
Tax is deducted at the beginning of every finance period (year) and uses your total Operating Profits over the last period (year) as a tax base.
Tax is displayed as "Other" in the finances window.

This allows you to set up a money sink, that will slow down money generation in late game, without making your early game start harder.

You can configure tax parameters as you like. For example, setting Minimum Tax Rate to 0% and increasing Minimum Taxable Profit Factor ensures there is no tax whatsoever in early game
until you reach a certain level of sustainable profits.

If you want additional economic challenge, see my infrastructure mod:
https://steamcommunity.com/sharedfiles/filedetails/?id=2805165537
]],

			["param rate_min"] = "Tax Rate: Minimum",
			["param rate_min tip"] = "The minimum tax rate (amount of tax as percentage of your Operating Profit) at the lowest profit level.\nIf set above Maximum, a Maximum will be used as a constant rate.",

			["param rate_max"] = "Tax Rate: Maximum",
			["param rate_max tip"] = "The maximum tax rate.\nActual rate will never actually reach this value but will infinitely tend to it.",

			["param half_rate_base"] = "Half Rate Profit",
			["param half_rate_base tip"] = "At this level of Operating Profit, your Tax Rate will be exactly half-way between minimum and maximum.\n"..
				"Note that because tax rate is non-linear function, it raises much slower after this point towards the maximum.",

			["param taxable_min_factor"] = "Minimum Taxable Profit Factor",
			["param taxable_min_factor tip"] = "The amount of profits, below which you always pay the minimum rate.\n"..
				"This is set as a percentage of Half Rate Profit.\nValues over 10% are not recommended and will result in big tax spikes when Minimum Taxable Profit is reached.",
		},
		de = {
			["mod name"] = "Progressive Einkommensteuer",
			["mod desc"] =
[[
Fügt Steuern auf Ihren Betriebsgewinn (Tickets minus Wartung) mit dynamischem Steuersatz hinzu, der sich auf nichtlineare Weise ändert und sich realen progressiven Steuersystemen annähert.
Die Steuer wird zu Beginn jedes Finanzzeitraums (Jahres) abgezogen und verwendet Ihre gesamten Betriebsgewinne des letzten Zeitraums (Jahres) als Steuerbemessungsgrundlage.
Die Steuer wird im Finanzfenster als "Sonstiges" angezeigt.

Auf diese Weise können Sie eine Geldsenke einrichten, die die Geldgenerierung im späten Spiel verlangsamt, ohne dass Ihr früher Spielstart schwieriger wird.

Sie können die Steuerparameter nach Belieben konfigurieren. Wenn Sie beispielsweise den Mindeststeuersatz auf 0 % setzen und den steuerpflichtigen Mindestgewinnfaktor erhöhen, wird sichergestellt, dass im frühen Spiel überhaupt keine Steuern erhoben werden
bis Sie ein bestimmtes Niveau nachhaltiger Gewinne erreichen.

Wenn Sie eine zusätzliche wirtschaftliche Herausforderung wünschen, sehen Sie sich meinen Infrastruktur-Mod an:
https://steamcommunity.com/sharedfiles/filedetails/?id=2805165537
]],
			["param rate_min"] = "Steuersatz: Minimum",
			["param rate_min tip"] = "Der minimale Steuersatz (Steuerbetrag als Prozentsatz Ihres Betriebsgewinns) auf der niedrigsten Gewinnebene.\nFalls über dem Maximum festgelegt, wird ein Maximum als konstanter Satz verwendet.",

			["param rate_max"] = "Steuersatz: Maximum",
			["param rate_max tip"] = "Der maximale Steuersatz.\nDer tatsächliche Steuersatz wird diesen Wert nie wirklich erreichen, sondern sich unendlich darauf zubewegen.",

			["param half_rate_base"] = "Gewinn zum halben Steuersatz",
			["param half_rate_base tip"] = "Bei diesem Betriebsgewinn liegt Ihr Steuersatz genau in der Mitte zwischen Minimum und Maximum.\n"..
				"Beachten Sie, dass der Steuersatz, da er eine nichtlineare Funktion ist, nach diesem Punkt viel langsamer in Richtung des Maximums ansteigt.",

			["param taxable_min_factor"] = "Minimaler steuerpflichtiger Gewinnfaktor",
			["param taxable_min_factor tip"] = "Der Mindestgewinn Betrag, unterhalb dessen Sie immer den Mindestsatz zahlen.\n"..
				"Dies wird als Prozentsatz des Gewinn zum halben Steuersatz.\nWerte über 10 % werden nicht empfohlen und führen zu großen Steuerspitzen, wenn der steuerpflichtige Mindestgewinn erreicht ist.",
		},
		ru = {
			["mod name"] = "Прогрессивный налог на прибыль",
			["mod desc"] =
[[
Облагает налогом вашу Операционную Прибыль (доход от доставок минус издержки на содержание) по динамической ставке, которая меняется нелинейно, аппроксимируя налоговые системы реального мира.
Налог удерживается в начале каждого финансового периода (год) и использует вашу общую Операционную Прибыль за предыдущий период (год) в качестве налоговой базы.
Величина налога отображается как "Другое" в окне финансов.

Эта позволяет вам настроить отток денег, замедлив таким образом чрезмерное обогащение на поздних этапах игры, не усложняя при этом ранние этапы.

Вы можете настроить параметры налога по желанию. Например, выставив минимальную ставку в 0% и увеличив Долю минимальной облагаемой прибыли можно гарантировать полное отсутствие налога в начале игры
пока вы не достигните устойчивых уровней дохода.

Если хотите дополнительно разнообразий экономическую составляющую игры, рекомендую мой мод стоимости инфраструктуры:
https://steamcommunity.com/sharedfiles/filedetails/?id=2805165537
]],

			["param rate_min"] = "Ставка налога: Минимальная",
			["param rate_min tip"] = "Минимальная ставка налога (процентная доля Операционной Прибыли) на самом низком уровне прибыли.\nЕсли значение превышает Максимальную, будет использоваться фиксированная ставка размером с Максимальную.",

			["param rate_max"] = "Ставка налога: Максимальная",
			["param rate_max tip"] = "Максимальная ставка налога.\nРеальная ставка никогда не достигнет этого значение, но будет бесконечно стремиться к нему.",

			["param half_rate_base"] = "Уровень прибыли половинной ставки",
			["param half_rate_base tip"] = "На данном уровне Операционного дохода, ваша ставка налога будет ровно посередине между Минимумом и Максимумом.\n"..
				"Замечу что т.к. ставка меняется по нелинейной функции, после данного уровня прибыли рост ставки существенно замедляется.",

			["param taxable_min_factor"] = "Доля минимальной облагаемой прибыли",
			["param taxable_min_factor tip"] = "Объём прибыли, ниже которого вы всегда будете платить минимальную ставку.\n"..
				"Является процентной долей от Уровня прибыли половинной ставки.\nЗначения выше 10% не рекомендованы и приведут к большому скачку ставки налога при достижении минимальной облагаемой прибыли.",
		},
	}
end
