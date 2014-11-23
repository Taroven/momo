-- Internet helper class
-- TODO: Upload, query, socket connections, validate connection before attempts

class.require('path')
local c = class('web','tag')
local util = util or require('util')
local escape = string.escape or util.string.escape
local ac = util.argcheck

c.initialize = function (self, prefix)
	local prefix = self:OptSet('web.prefix',prefix,'')
	self:Set('tags.separator', '/')

	self:AddTag('base', prefix)
	return self
end

c.Path = function (self, ...)
	local prefix = self:Get('web.prefix','')
	local sep self:Get('tags.separator','/')

	local path = self:ParseTags(...)
	if not string.match(path, '^' .. escape(prefix)) then
		path = prefix .. path
	end
	return path
end

-- Set or unset asynchronous downloads.
-- If f is nil, unsets any existing async callback and returns the object to sync mode.
-- If f is a function, async mode is enabled and f will be called once any web tasks complete as f(object, responseCode, result)
c.SetAsync = function (self, f)
	ac(f, 'function', 'nil')
	self:Set('web.callback', f, true)
end

local download = function (self, path, async)
	self:Log("download (internal)",1,path,async)
	local task = MOAIHttpTask.new()

	task:setVerb(MOAIHttpTask.HTTP_GET)
	task:setFollowRedirects(true)
	task:setUrl(path)
	task:setUserAgent("Moai")
	task:setVerbose(true)
	--task:setTimeout(3000)

	local response, result
	task:setCallback(function (task, responseCode)
			response = responseCode
			result = task:getString()
			self:Log("download (internal)", 1, responseCode, path)
			if async then
				return async(self, responseCode, result)
			end
		end)
	if async then
		self:Log("download (internal)", 1, "task is being performed async", url)
		return task:performAsync()
	else
		self:Log("download (internal)", 1, "task is being performed (blocking)", url)
		task:performSync()
	end


	return result, response
end

c.Download = function (self, path)
	ac(path, 2, 'string')
	local async = self:Get('web.callback')
	return download(self, path, async)
end

return c