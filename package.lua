local c = {}
local concat = concat or table.concat

c.path = {
	"?", "?.lua", "?/init.lua", "?/?.lua"
}

c.BuildPath = function (self)
	package.path = concat(self.path,";")
	return package.path
end

c.AddPath = function (self, path)
	argcheck(path,2,"string")
	for i,v in ipairs(self.path) do
		if v == path then return v end
	end
	self.paths[#self.paths + 1] = path
	return self.paths[#self.paths]
end

c.RemovePath = function (self, path)
	argcheck(path,2,"string")
	for i,v in ipairs(self.path) do
		if v == path then return table.remove(self.paths,i) end
	end
end

return c