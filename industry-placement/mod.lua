local debugger = require "debugger"
local table_util = require "industry_placement/lib/table_util"
local serialize_util = require "industry_placement/lib/serialize_util"

function constructionMod(fileName, data)
	local originalUpdateFn = data.updateFn
	
	if(data.updateFn == nil) then
		print("Warning: updateFn() is null, skipping callback!")
		return data
	end

	if data.type=="INDUSTRY" and type(data.updateFn) == "function" then
		-- print("Load industry" .. fileName)

		-- Fake call to updateFn to get output
		--[[
		local params = table_util.mapDict(data.params or {}, function(param) return param.key, param.defaultIndex or 0 end)
		params.seed = 0
		params.state = {groups = {}}
		local updateResult = data.updateFn(params)
		local output = updateResult.rule.output
		print("[" .. serialize_util.serialize(fileName) .. "] = " .. serialize_util.serialize({data.placementParams,output}) .. ",")
		]]
	end

	return data

end

function data()
	return {
		info = {
			minorVersion = 0,
			severityAdd = "NONE",
			severityRemove = "NONE",
			name = "Industry Clusters",
			description = "SUPER DUPER MOD",
			tags = { "Script Mod" },
			authors = {
				{
					name = "phobos2077",
					role = "CREATOR",
					text = "",
					steamProfile = "76561198025571704",
				},
			},
			params = {
			},
		},
		runFn = function (settings, modParams)
			--local params = modParams[getCurrentModId()]
			-- game.config.sandboxButton = true
			
			-- addModifier("loadConstruction", constructionMod)
		end,
		postRunFn = function()
		end
	}
end