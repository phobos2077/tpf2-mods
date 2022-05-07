function data()
	local multTip = {
		en = function(type)	return "Construction and maintenance costs for all pieces of "..type.." Infrastructure will be multiplied by this value\nin addition to dynamic scaling." end
	}
	local vehicleMultTip = {
		en = function(type)	return "This sets the upper limit for "..type.." Infrastructure Dynamic Build cost based on vehicle ratings." end
	}
	local maintMultTip = {
		en = function(type, note)	return "Additional multiplier for "..type.." Infrastructure Maintenance cost."..(note and ("\n"..note) or "") end
	}
	return {
		en = {
			["mod name"] = "Dynamic Infrastructure Costs v2",
			["mod desc"] =
[[
!! IMPORTANT:
- Requires Spring 2022 Update (beta), see note below


Dynamically increases maintenance and build costs of various pieces of infrastructure, such as tracks, stations, depots, etc.
[list]
[*]Build costs increase based on the vehicles available at current year.
[*]Maintenance costs change based on intensity of use of stations.
[*]Additionally, static cost multipliers are available for every type of infrastructure.
[/list]

The mod is structured into 3 parts.


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

If you increase Base Cost Multiplier for category of infrastructure, it will multiply the result of dynamic scaling.
For example, if you set Road Base Cost to 200% and Road Build Cost Max to 5x, final price upper limit will be 10x.


[h3]Part 3 - Usage-based Infrastructure Costs[/h3]
Maintenance costs are scaled independently from build costs and instead use a different formula:
[list]
[*]Total Capacity of all your stations for given category is calculated.
[*]Total Line Rates is calculated as sum of Rate value (as seen in UI) multiplied by number of stops.
[*]Final multiplier = (Total Rates / Total Capacity) * mult, where mult is configurable value per category.
[/list]
Base value for maintenance costs is 10% of purchase cost, just like in vanilla game.
But it is affected by Base Cost Multipliers and is scaled independently from build cost.


[h3]Compatibility with new Advanced Settings (Spring 2022 Update)[/h3]
[list]
[*]Infrastructure Build Costs should work as you expect and act as additional multiplier on top of Cost setting. But it's recommended to set it to 100% to simplify the math.
[*]Infrastructure Maintenance Costs MUST be set at 100% in Advanced Settings, otherwise calculations for extra maintenance costs will be slightly off the expected value.
[/list]


[h3]Known issues/limitations[/h3]
[list]
[*]Build costs of tracks and roads will not change dynamically (only affected by base multiplier). But maintenance costs will!
[*]Red floating numbers will keep showing the original unmodified maintenance costs. Rest assured, additional fees will be deducted from your account behind the scenes. You can monitor this in Finances window.
[*]Refund amounts for individual station modules will still be based on original (lower) module price, so you might get much less money back than you expect. This is also modding API limitation.
[*]If you add this mod to existing game where you set Maintenance Cost to something other than 100% and built a bunch of infrastructure, the calculations will be slightly off (in higher or lower direction) because of how the mod works.
[/list]


[h3]Other economy mods you might want to check out[/h3]
Original version of the mod, based on "Inflation" curve:
https://steamcommunity.com/sharedfiles/filedetails/?id=2798809680

Progressive Income/Profit Tax:
https://steamcommunity.com/sharedfiles/filedetails/?id=2802501762
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
			["param mult_bridges_tunnels tip"] = "Flat modifier for cost of tunnel and bridge construction.\nDoes not affect bridge maintenance costs. Instead, Road/Rail multipliers are used.",
			["param mult_terrain"] = "Cost: Terrain",
			["param mult_terrain tip"] = "Terrain modification cost multiplier.",
			["param mult_upgrade_edge"] = "Upgrades: Tracks & Roads",
			["param mult_upgrade_edge tip"] = "This is relative to the cost of track/road itself.\nE.g. setting Cost to 200% and Upgrades to 200% will result in 400% increase of final upgrade cost.",

			["param veh_mult_street"] = "Build Cost Max: Road",
			["param veh_mult_street tip"] = vehicleMultTip.en("Road"),
			["param veh_mult_rail"] = "Build Cost Max: Railroad",
			["param veh_mult_rail tip"] = vehicleMultTip.en("Railroad"),
			["param veh_mult_water"] = "Build Cost Max: Water",
			["param veh_mult_water tip"] = vehicleMultTip.en("Water"),
			["param veh_mult_air"] = "Build Cost Max: Air",
			["param veh_mult_air tip"] = vehicleMultTip.en("Air"),

			["param maint_mult_street"] = "Maintenance: Road",
			["param maint_mult_street tip"] = maintMultTip.en("Road", "Road usage tends to be much higher than Rail. Increase this if you tend to build a lot of big road stations."),
			["param maint_mult_rail"] = "Maintenance: Railroad",
			["param maint_mult_rail tip"] = maintMultTip.en("Railroad"),
			["param maint_mult_water"] = "Maintenance: Water",
			["param maint_mult_water tip"] = maintMultTip.en("Water"),
			["param maint_mult_air"] = "Maintenance: Air",
			["param maint_mult_air tip"] = maintMultTip.en("Air"),
		},

		ru ={
			["mod name"] = "Динамические затраты на инфраструктуру v2",
			["mod desc"] =
[[
!! ВАЖНО:
- Требует Spring 2022 Update (бета).


Динамически повышает стоимость строительство и содержания различной инфраструктуры, такой как пути, станции, депо и т.д.
[list]
[*]Стоимость строительства повышается на основе доступного для покупки транспорта.
[*]Стоимость содержания меняется в зависимости от интенсивности нагрузки на станции.
[*]Дополнительно, статические множители стоимости доступны для каждой категории инфраструктуры.
[/list]

Мод разделён на 3 части.


[h3]Часть 1 - Базовые множители стоимости[/h3]
Изменяют непосредственно стоимость строительства и содержания всех категорий инфраструктуры.
Эти множители статичны и не меняются в процессе игры. Однако они домножают эффект от динамических множителей.


[h3]Часть 2 - Динамические множители стоимости строительства[/h3]
Стоимость постройки всех станций и депо масштабируется на основе текущего рейтинга мощности транспорта. Этот рейтинг вычисляется следующим образом:
[list]
[*]Весь транспорт доступный для покупки в текущем году берётся и распределяется по категориям (дорожные, ЖД, водные и воздушные).
[*]Для каждого ТС, вычисляется рейтинг мощности. Для локомотивов он равен мощности двигателей. Для всех прочих категорий - произведению вместимости на максимальную скорость.
[*]Наибольшее значение рейтинга используется в специальной формуле, где 1 соответствует одному из наиболее слабых ТС данной категории, а Макс. множитель постройки - одной из наиболее "сильных".
Формула нелинейна и в результате делает конечную кривую более линейной.
[/list]

Повышение множителя для категории инфраструктуры умножает результат динамического масштабирования.
Например, если поставить Базовый множитель Дорог на 200% а Макс. множитель постройки на 5х, верхний предел конечный цены будет 10-кратным.


[h3]Часть 3 - Стоимость содержания зависящая от использования[/h3]
Стоимость содержания масштабируется независимо от стоимости постройки и использует другую формулу:
[list]
[*]Высчитывается общая вместимость всех станций данной категории.
[*]Высчитывается общая пропускная способность всех линий как произведение "Нормы" (из окна линии) на число остановок - для всех линий.
[*]Конечный множитель = (Общая проп. способность / Общая вместимость) * Множ, где множитель настраивается для каждой категории.
[/list]
Базовая стоимость содержания составляет 10% от стоимости строительства, ровно как в оригинальной игре.
Однако, на неё оказывают влияние базовые множители стоимости и масштабирование происходит независимо от стоимости строительства.


[h3]Другие модификации экономики игры:[/h3]
Старая версия мода, на основе понятия "Инфляции":
https://steamcommunity.com/sharedfiles/filedetails/?id=2798809680

Прогрессивный налог на доходы:
https://steamcommunity.com/sharedfiles/filedetails/?id=2802501762
]],

			["param mult_street"] = "Базовый множитель: Дорога",
			["param mult_street tip"] = "",
			["param mult_rail"] = "Базовый множитель: ЖД",
			["param mult_rail tip"] = "",
			["param mult_water"] = "Базовый множитель: Вода",
			["param mult_water tip"] = "",
			["param mult_air"] = "Базовый множитель: Авиация",
			["param mult_air tip"] = "",

			["param mult_bridges_tunnels"] = "Стоимость: Мосты и тоннели",
			["param mult_bridges_tunnels tip"] = "Простой множитель стоимости постройки тоннелей и мостов.\nОтмечу, что расходы на содержание мостов и тоннелей масштабируются в соответствии с их категорией транспорта,\nа данный параметр влияет лишь на строительство.",
			["param mult_terrain"] = "Стоимость: Ландшафт",
			["param mult_terrain tip"] = "Множитель стоимость модификаций ландшафта.",
			["param mult_upgrade_edge"] = "Улучшения: Пути и дороги",
			["param mult_upgrade_edge tip"] = "Повышает множители стоимости улучшений Путей и Дорог, таких как трамвайные пути или контактная сеть.",

			["param veh_mult_street"] = "Макс. множитель постройки: Дорога",
			["param veh_mult_street tip"] = "",
			["param veh_mult_rail"] = "Макс. множитель постройки: ЖД",
			["param veh_mult_rail tip"] = "",
			["param veh_mult_water"] = "Макс. множитель постройки: Вода",
			["param veh_mult_water tip"] = "",
			["param veh_mult_air"] = "Макс. множитель постройки: Авиация",
			["param veh_mult_air tip"] = "",

			["param maint_mult_street"] = "Содержание: Дорога",
			["param maint_mult_street tip"] = "Интенсивность использования дорог обычно выше чем ЖД. Используйте более высокие значение если строите много больших автостанций.",
			["param maint_mult_rail"] = "Содержание: ЖД",
			["param maint_mult_rail tip"] = "",
			["param maint_mult_water"] = "Содержание: Вода",
			["param maint_mult_water tip"] = "",
			["param maint_mult_air"] = "Содержание: Авиация",
			["param maint_mult_air tip"] = "",
		}
	}
end
