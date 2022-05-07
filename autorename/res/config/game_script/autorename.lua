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
				if configData.renameVehicles then
					rename.renameVehicles(configData.vehiclePattern)
				end
				nextRenameAttempt = currentTime + RENAME_INTERVAL
			end
		end,
		guiHandleEvent = function(id, name, param)
			-- if id ~= "constructionBuilder" then
			-- 	debugPrint({"guiHandleEvent", id, name, param})
			-- end
		end,
		handleEvent = function(src, id, name, param)
			-- if src ~= "guidesystem.lua" then
			-- 	debugPrint({"handleEvent", src, id, name, param})
			-- end
		end
	}
end
