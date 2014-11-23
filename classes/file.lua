local fs = require 'filesystem'
local util = util or require('util')
local concat = table.concat or concat
local type = type

local c = class('file')

-- Make sure we always have a valid string (non-string/table values return tostring(v), nil returns empty string)
local ts = function (s)
	local t = type(s)
	if t == 'string' then return s
	elseif t == 'table' then return concat(s)
	elseif t ~= 'nil' then return tostring(s) end
	return ''
end

c.initialize = function (self, path)
	util.argcheck(path, 2, 'string')
	self:Set('file.path', path)
	self:Read()
	return self
end

-- Set properties -> file.contents.
-- This will
c.SetContents = function (self, contents)
	self:Set('file.contents', ts(contents))
	return self
end

-- Append text to properties -> file.contents
c.Append = function (self, contents)
	if type(contents) ~= 'nil' then
	local c = ts(self:Get('file.contents'))
	self:SetContents(c .. '\n' .. ts(contents))
	return self
end

-- Write properties -> file.contents to file. Writes to the specified path or properties -> file.path
c.Write = function (self, path)
	local contents = self:Get('file.contents')
	if contents then
		fs.Write(path or self:Get('file.path'), contents)
	end
	return self
end

-- Load file contents into properties -> file.contents. Reads from the specified path or properties -> file.path
-- Returns properties -> file.contents.
c.Read = function (self, path)
	self:Commit('file.contents', fs.Read(path or self:Get('file.path')))
	return self:Get('file.contents')
end

-- fs:Path proxy (build a sanitized path from args) for convenience
c.Path = function (self, ...)
	return fs:Path(...)
end

return c