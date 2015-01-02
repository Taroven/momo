if _LOG then return _LOG end

local util = util or require"util"

local errorlevel,lastlevel
local errorlevels = {
	"DEBUG",
	"INFO",
	"WARN",
	"ERROR",
}

local logstack = {}
local pop = function ()
	if not errorlevel then return end
	while stack[1] do
		local entry = table.remove(stack,1)
		if entry.obj and (entry.level >= errorlevel) then
			if type(entry.msg) ~= "table" then entry.msg = {entry.msg} end
			local r = entry.obj
			local msg = errorlevels[entry.level] .. ": " .. r.__name .. (entry.method and ("." .. entry.method) or "") .. ": " .. table.concat(entry.msg, r.__sep or " | ")
			MOAILogMgr.log(msg)
		end
	end
end

local push = function (obj, level, method, ...)
	argcheck(self,1,"table")
	local t = {...}
	local entry = {}
	for i,v in ipairs(t) do
		t[i] = tostring(v)
	end
	entry.msg = t
	entry.level = type(level) == "number" and level or 2
	entry.method = method
	entry.obj = obj

	stack[#stack + 1] = entry
	return pop()
end

local log = {}

log.SetLevel = function (level)
	argcheck(level,1,"number","nil")
	errorlevel = level or lastlevel
	pop()
end

log.Disable = function ()
	lastlevel = errorlevel
	errorlevel = 99
end

log.Enable = function (level)
	return log.SetLevel(level or lastlevel or 1)
end

log.File = function (path)
	return MOAILogMgr.openFile(path)
end

local mt = {
	__call = function (_, obj, level, method, ...) return push(obj, level, method, ...) end
}
setmetatable(log, mt)

_LOG = log
return log