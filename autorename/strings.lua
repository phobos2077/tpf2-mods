function data()
	return {
		en = {
			["mod name"] = "Auto-Rename: Vehicles",
			["mod desc"] =
[[
Automatically renames all of your vehicles based on the name of lines they are assigned.
Renaming happens on game load and then about 4 times a month.
Add ! (exclamation mark) to the end of line name to exclude it from renaming.
]],

			["param vehicle_pattern"] = "Vehicle Naming",
			["param vehicle_pattern tip"] = "Which pattern to use for auto-naming the vehicles.",

			["param vehicle_num_digits"] = "Number format (vehicles)",
			["param vehicle_num_digits tip"] = "Allows to set minimum number of digits for vehicle numbers.",

			["param number_merge_mode"] = "Line number merge mode",
			["param number_merge_mode tip"] = "If enabled, will detect lines with numbers in their name and merge it with vehicle number according to selected format.",

			["param skip_brackets_square"] = "Skip text in []",
			["param skip_brackets_square tip"] = "",
			
			["param skip_brackets_curly"] = "Skip text in {}",
			["param skip_brackets_curly tip"] = "",

			["param skip_brackets_angled"] = "Skip text in <>",
			["param skip_brackets_angled tip"] = "",

			["pattern LineTypeNumber"] = "<Line> <Type> <Number>",
			["pattern LineNumber"] = "<Line> <Number>",

			["value disable"] = "(disable)",
			["value space"] = "(space)",
			["value together"] = "(together)",
			["value auto"] = "(auto)",
		},
		de = {
			["mod name"] = "Automatische Umbenennung von Fahrzeugen",
			["mod desc"] =
[[
Benennt automatisch alle Ihre Fahrzeuge um, basierend auf den Namen der ihnen zugewiesenen Linien.
Die Umbenennung erfolgt beim Laden des Spiels und dann etwa 4 Mal im Monat.
Hinzufügen ! (Ausrufezeichen) an das Ende des Zeilennamens, um ihn von der Umbenennung auszuschließen.
]],

			["param vehicle_pattern"] = "Benennung von Fahrzeugen",
			["param vehicle_pattern tip"] = "",

			["param vehicle_num_digits"] = "Zahlenformat (Fahrzeuge)",
			["param vehicle_num_digits tip"] = "Ermöglicht die Festlegung einer Mindestanzahl von Ziffern für Fahrzeugnummern.",

			["param number_merge_mode"] = "Zeilennummern-Zusammenführungsmodus",
			["param number_merge_mode tip"] = "Wenn aktiviert, werden Linien mit Nummern im Namen erkannt und diese Nummer zusammen mit der Fahrzeugnummer verschoben.",

			["param skip_brackets_square"] = "Text in [] überspringen",
			["param skip_brackets_square tip"] = "",

			["param skip_brackets_curly"] = "Text in {} überspringen",
			["param skip_brackets_curly tip"] = "",

			["param skip_brackets_angled"] = "Text in <> überspringen",
			["param skip_brackets_angled tip"] = "",

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

			["value disable"] = "(deaktivieren)",
			["value together"] = "(zusammen)",
			["value auto"] = "(automatisch)",
		},
		ru = {
			["mod name"] = "Авто-переименование: транспорт",
			["mod desc"] =
[[
Автоматически переименовывает транспортные средства в соответствии с названием линии.
Переименование срабатывает при загрузке игры, а также 4 раза в игровой месяц.
Добавьте ! (восклицательный знак) в конце имени линии, чтобы исключить её из переименования.
]],

			["param vehicle_pattern"] = "Шаблон названия для транспорта",
			["param vehicle_pattern tip"] = "",

			["param vehicle_num_digits"] = "Формат номера (транспорт)",
			["param vehicle_num_digits tip"] = "Позволяет задать минимальное количество цифр в номере транспорта.",

			["param number_merge_mode"] = "Режим слияния номера линии",
			["param number_merge_mode tip"] = "Если включено, найдет номер линии в названии и переместит вместе с номером транспорта по заданному формату.",

			["param skip_brackets_square"] = "Пропускать текст в []",
			["param skip_brackets_square tip"] = "",
			
			["param skip_brackets_curly"] = "Пропускать текст в {}",
			["param skip_brackets_curly tip"] = "",

			["param skip_brackets_angled"] = "Пропускать текст в <>",
			["param skip_brackets_angled tip"] = "",

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

			["value disable"] = "(выкл.)",
			["value together"] = "(слитно)",
			["value auto"] = "(автом.)",
		},
	}
end
