local log_util = {}

function log_util.log(tag, message)
	print("["..tag.."] " .. message)
end

function log_util.logFormat(tag, message, ...)
	log_util.log(tag, string.format(message, ...))
end

function log_util.logFormatTimer(tag, message, ...)
	local params = table.pack(...)
	params[#params] = log_util.elapsedMs(params[#params])
	message = message.." (in %.0f ms)"
	log_util.log(tag, string.format(message, table.unpack(params)))
end

function log_util.logError(tag, message)
	print("\n"..debug.traceback("! ERROR ! [" .. tag .. "] " .. message).."\n")
end

function log_util.logErrorFormat(tag, message, ...)
	log_util.logError(tag, string.format(message, ...))
end

function log_util.timer()
	return os.clock()
end

function log_util.elapsedMs(timer)
	return (os.clock() - timer) * 1000
end

return log_util