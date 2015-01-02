local fs = {paths = {}}

local util = require "util"

local assert, loadstring = assert, loadstring

-- TODO: Merge into class?

function fs:AddPath (tag, path)
	argcheck(path,3,"string")
	argcheck(tag,2,"string")
	local tag = string.match(tag,"(%b[])") or ("[" .. tag .. "]")
	self.paths[tag] = path
	return tag, path
end

function fs:Path (...)
	local t = {...}
	local sep
	for i,v in ipairs(t) do
		local s = string.match(v,"([/\\])")
		sep = sep or s
		t[i] = string.gsub(v,"%b[]",self.paths)
	end
	sep = sep or self.pathsep or "/"
	local path = string.gsub(table.concat(t, sep), "[/\\]+", sep)
	return path
end

function fs:GetLeadingPath (...)
	return string.match(self:Path(...),"(.+)[/\\].+$")
end

function fs:AffirmPath (...)
	local path = self:Path(...)
	local partial = self:GetLeadingPath(path)
	MOAIFileSystem.affirmPath(partial)
end

function fs:AffirmFile (...)
	local path = self:Path(...)
	self:AffirmPath(path)
	return MOAIFileSystem.checkFileExists(path)
	--[[
	local exists = MOAIFileSystem.checkFileExists(path)
	if exists then
		return path
	else
		local stream = self:GetFileStream(path)
		self:WriteStream(stream,'')
		print(1, 'AffirmFile copied empty')
		return path
	end
	--]]
end

function fs:GetFileHandle (path, mode)
	argcheck(path,2,"string")
	argcheck(mode,3,"string","nil")
	self:AffirmFile(path)
	return assert(io.open(path,mode))
end

function fs:Read (path, lines)
	argcheck(path,2,"string")
	local exists = self:AffirmFile(path)
	if exists then
		local file = self:GetFileHandle(path)
		if file then
			if lines then
				local t = {}
				for line in file:lines() do t[#t + 1] = line end
				file:close()
				return t
			else
				local s = file:read("*a")
				file:close()
				return s
			end
		end
	end
end

function fs:Write (s, path, append)
	argcheck(s,2,"string","table")
	argcheck(path,3,"string")
	local file = self:GetFileHandle(path, append and 'a+' or 'w+')
	local src = type(s) == "table" and table.concat(s,"\n") or s
	if file and src then
		file:write(s)
		file:flush()
		file:close()
		return self:AffirmFile(path)
	end
end

function fs:Load (path)
	local s = self:ReadFile(path)
	if s then
		return assert(loadstring(s))
	end
end

return fs