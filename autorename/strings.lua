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

			["param vehicle_add_type"] = "Add Vehicle Type",
			["param vehicle_add_type tip"] = "Adds vehicle type to it's name.",

			["param vehicle_num_separator"] = "Number Separator",
			["param vehicle_num_separator tip"] = "",

			["param vehicle_num_digits"] = "Number format",
			["param vehicle_num_digits tip"] = "Allows to set minimum number of digits for vehicle numbers.",

			["param vehicle_move_line_num"] = "Move line number",
			["param vehicle_move_line_num tip"] = "If enabled, will detect lines with number in their name and move it before vehicle number.",

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

			["param vehicle_add_type"] = "Fahrzeugtyp hinzufügen",
			["param vehicle_add_type tip"] = "Fügt seinem Namen einen Fahrzeugtyp hinzu.",

			["param vehicle_num_separator"] = "Zahlentrennzeichen",
			["param vehicle_num_separator tip"] = "",

			["param vehicle_num_digits"] = "Zahlenformat",
			["param vehicle_num_digits tip"] = "Ermöglicht die Festlegung einer Mindestanzahl von Ziffern für Fahrzeugnummern.",

			["param vehicle_move_line_num"] = "Zeilennummer verschieben",
			["param vehicle_move_line_num tip"] = "Wenn aktiviert, werden Linien mit Nummern im Namen erkannt und vor die Fahrzeugnummer verschoben.",

			["param skip_brackets_square"] = "Text in [] überspringen",
			["param skip_brackets_square tip"] = "",

			["param skip_brackets_curly"] = "Text in {} überspringen",
			["param skip_brackets_curly tip"] = "",

			["param skip_brackets_angled"] = "Text in <> überspringen",
			["param skip_brackets_angled tip"] = "",

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

			["param vehicle_add_type"] = "Добавлять тип транспорта",
			["param vehicle_add_type tip"] = "Добавлять тип транспорта к его названию.",

			["param vehicle_num_separator"] = "Разделитель номера",
			["param vehicle_num_separator tip"] = "",

			["param vehicle_num_digits"] = "Формат номера",
			["param vehicle_num_digits tip"] = "Позволяет задать минимальное количество цифр в номере транспорта.",

			["param vehicle_move_line_num"] = "Перемещать номер линии",
			["param vehicle_move_line_num tip"] = "Если включить, будет находить номер линии в её названии и переносить перед номером ТС.",

			["param skip_brackets_square"] = "Пропускать текст в []",
			["param skip_brackets_square tip"] = "",
			
			["param skip_brackets_curly"] = "Пропускать текст в {}",
			["param skip_brackets_curly tip"] = "",

			["param skip_brackets_angled"] = "Пропускать текст в <>",
			["param skip_brackets_angled tip"] = "",

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
