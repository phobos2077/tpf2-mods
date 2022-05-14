local log_util = {}

function log_util.log(message, tag)
	print((tag and ("["..tag.."] ") or "").. message)
end

function log_util.logError(message)
	print("\n"..debug.traceback("! ERROR ! " .. message).."\n")
end

function log_util.logIfCommandFailed(cmd, success)
	if not success then
		debugPrint({commandFailed = cmd})
	end
end

return log_util