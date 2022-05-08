function data()
	return {
		en = {
			["mod name"] = "Auto-Rename: Vehicles",
			["mod desc"] =
[[
Automatically renames all of your vehicles based on the name of lines they are assigned.
Renaming happens on game load and then about 4 times a month.
]],

			["param vehicle_pattern"] = "Vehicle Naming",
			["param vehicle_pattern tip"] = "Which pattern to use for auto-naming the vehicles.",

			["pattern LineTypeNumber"] = "<Line> <Type> <Number>",
			["pattern LineNumber"] = "<Line> <Number>",
		},
		de = {
			["mod name"] = "Automatische Umbenennung von Fahrzeugen",
			["mod desc"] =
[[
Benennt automatisch alle Ihre Fahrzeuge um, basierend auf den Namen der ihnen zugewiesenen Linien.
Die Umbenennung erfolgt beim Laden des Spiels und dann etwa 4 Mal im Monat.
]],

			["param vehicle_pattern"] = "Benennung von Fahrzeugen",
			["param vehicle_pattern tip"] = "",

			["pattern LineTypeNumber"] = "<Linie> <Typ> <Anzahl>",
			["pattern LineNumber"] = "<Linie> <Anzahl>",

			["Truck"] = "Lastwagen",
			["Bus"] = "Bus",
			["Road vehicle"] = "Strassenfahrzeug",
			["Train"] = "Zug",
			["Tram"] = "Straßenbahn",
			["Plane"] = "Flugzeug",
			["Ship"] = "Schiff",
			["Line"] = "Linie",
		},
		ru = {
			["mod name"] = "Авто-переименование: транспорт",
			["mod desc"] =
[[
Автоматически переименовывает транспортные средства в соответствии с названием линии.
Переименование срабатывает при загрузке игры, а также 4 раза в игровой месяц.
]],

			["param vehicle_pattern"] = "Шаблон названия техники",
			["param vehicle_pattern tip"] = "",

			["pattern LineTypeNumber"] = "<Линия> <Тип> <Номер>",
			["pattern LineNumber"] = "<Линия> <Номер>",

			["Truck"] = "Грузовик",
			["Bus"] = "Автобус",
			["Road vehicle"] = "Дорожный транспорт",
			["Train"] = "Поезд",
			["Tram"] = "Трамвай",
			["Plane"] = "Самолёт",
			["Ship"] = "Корабль",
			["Line"] = "Линия",
		},
	}
end
