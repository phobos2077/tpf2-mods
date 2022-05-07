local log_util = {}

function log_util.logError(message)
    print("\n"..debug.traceback("! ERROR ! " .. message).."\n")
end

return log_util