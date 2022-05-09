--[[
Automatically renames vehicles based on their lines.

Copyright (c)  2022  phobos2077  (https://steamcommunity.com/id/phobos2077)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including the right to distribute and without limitation the rights to use, copy and/or modify
the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.
--]]

local table_util = require "autorename/lib/table_util"

local config = require "autorename/config"
local rename = require "autorename/rename"

--- CONSTANTS
local RENAME_INTERVAL = 15


--- VARIABLES
local nextRenameAttempt

function data()
	return {
		save = function() end,
		load = function() end,
		update = function()
			local currentTime = game.interface.getGameTime().time
			local configData = config.get()

			if nextRenameAttempt == nil or currentTime > nextRenameAttempt then
				-- if configData.renameStations then
				-- 	rename.renameStations()
				-- end
				if configData.renameVehicles then
					rename.renameAllVehicles(configData)
				end
				nextRenameAttempt = currentTime + RENAME_INTERVAL
			end
		end,
		guiHandleEvent = function(id, name, param)
			-- if id == "constructionBuilder" and name == "builder.apply" then
			-- 	local result = param.result
			-- 	if type(result) == "table" or type(result) == "userdata" then
			-- 		for _, constrId in ipairs(result) do
			-- 			rename.renameStation(constrId)
			-- 		end
			-- 	end
			-- end
		end,
		handleEvent = function(src, id, name, param)
			-- if src ~= "guidesystem.lua" then
			-- 	debugPrint({"handleEvent", src, id, name, param, type(param)})
			-- end
		end
	}
end
