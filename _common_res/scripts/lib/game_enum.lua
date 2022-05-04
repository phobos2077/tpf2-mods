--[[
Enums from game API but always available.

Copyright (c)  2022  phobos2077  (https://steamcommunity.com/id/phobos2077)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including the right to distribute and without limitation the rights to use, copy and/or modify
the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.
--]]


local game_enum = {}

game_enum.Carrier = {
	ROAD = 0,
	RAIL = 1,
	TRAM = 2,
	AIR = 3,
	WATER = 4,
}

game_enum.TransportMode = {
	PERSON = 0,
	CARGO = 1,
	CAR = 2,
	BUS = 3,
	TRUCK = 4,
	TRAM = 5,
	ELECTRIC_TRAM = 6,
	TRAIN = 7,
	ELECTRIC_TRAIN = 8,
	AIRCRAFT = 9,
	SHIP = 10,
	SMALL_AIRCRAFT = 11,
	SMALL_SHIP = 12,
}

return game_enum