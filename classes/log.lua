local c = class("log")

local logf = function (self, level, ...)
	if not tonumber(level) then level = self.LogLevels[level] or 2 end
	
end

c.initialize = function (self, parent)
	self._class = parent
end

c.Log = logf

c.LogLevels = { "debug", "info", "warning", "error" }
for i,v in s.LogLevels do s.LogLevels[v] = i end

return c