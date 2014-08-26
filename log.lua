local util = util or require"util"
local class = class or require"class"

local errorlevel,lastlevel
local errorlevels = {
	"DEBUG",
	"INFO",
	"WARN",
	"ERROR",
}

logstack = logstack or {}
local pop = function ()
	if not errorlevel then return end
	while stack[1] do
		local entry = table.remove(log,1)
		if entry.ref and (entry.level >= errorlevel) then
			if type(entry.msg) ~= "table" then entry.msg = {entry.msg} end
			local r = entry.ref
			local msg = errorlevels[entry.level] .. ": " .. r.caller .. (entry.method and ("." .. entry.method) or "") .. ": " .. table.concat(entry.msg, r.sep or " | ")
			MOAILogMgr.log(msg)
		end
	end
end

local push = function (self, method, level, ...)
	util.argcheck(self,1,"table")
	local t = {...}
	local entry = {}
	for i,v in ipairs(t) do
		t[i] = tostring(v)
	end
	entry.msg = t
	entry.level = type(level) == "number" and level or 2
	entry.method = method
	entry.ref = self
	
	stack[#stack + 1] = entry
	return pop()
end

local log = class("log")
log.init = function (self,caller)
	util.argcheck(caller,2,"string")
	self.caller = caller
	self.sep = " | "
	local mt = getmetatable(self) or {}
	mt.__call = function (self, method, level, ...) return self:log(method, level, ...) end
	setmetatable(self,mt)
	return self
end

log.log = function (self, method, level, ...)
	return push(self, method, level, ...)
end

log.method = function (self,method)
	local m = method
	self._methods[m] = self._methods[m] or function (level, ...) return self:log(m, level, ...) end
	return self._methods[m]
end

log.SetLevel = function (level)
	util.argcheck(level,1,"number","nil")
	errorlevel = level or lastlevel
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

return log