local d = log("web")

local web = {paths = {}}

local download = function (self, path, async)
	d("download (internal)",1,path,async)
	local url = path

	local task = MOAIHttpTask.new()

	task:setVerb(MOAIHttpTask.HTTP_GET)
	task:setFollowRedirects(true)
	task:setUrl(url)
	task:setUserAgent("Moai")
	task:setVerbose(true)
	--task:setTimeout(3000)

	local response, result
	task:setCallback( async or (function (task, responseCode)
	                 response = responseCode
	                 result = task:getString()
	                 d("download (internal)", 1, responseCode, url)
                 end) )
	if async then
		d("download (internal)", 1, "task is being performed async", url)
		return task:performAsync()
	else
		d("download (internal)", 1, "task is being performed (blocking)", url)
		task:performSync()
	end
	

	d("download (internal)", 1, "task complete", response, url)
	return result, response
end

web.Download = function (self, path, async)
	d("Download", 1, path, async)
	util.argcheck(path,2,"string")
	util.argcheck(async,3,"function","nil")
	return download(self, path, async)
end

-- Build path from args with replacements from self.paths
web.Path = function (self, ...)
	local t = {...}
	for i,v in ipairs(t) do t[i] = string.gsub(v,"%b[]",self.paths) end
	local path = string.gsub(table.concat(t, "/"), "[/]+", "/")
	d("Path", 1, path, ...)
	return path
end

web.AddPath = function (self, tag, path)
	util.argcheck(path,3,"string")
	util.argcheck(tag,2,"string")
	local tag = string.match(tag,"(%b[])") or ("[" .. tag .. "]")
	self.paths[tag] = path
	d("AddPath", 1, tag, path)
	return tag, path
end

return web