-- Middleclass and Classy have their quirks. So does Lash, but Lash happens to be built to preference, so...

-- Magic trick: To require and init an instance, now we just use classes["whatever"](args). Everything is nicely indexed for us.
-- Just don't try to do anything with a class that doesn't exist. Bad mojo.
if _CLASSMGR then return _CLASSMGR end

class = class or require"lash"
local log = log or require"log"
local util = util or require 'util'
local rawset,rawget = rawset,rawget

local obj = class.Object
obj.Log = function (self, level, method, ...)
	util.argcheck(method,2,'string')
	util.argcheck(level,3,'number','nil')
	return log(self, level, method, ...)
end

local index = function (self,k)
	if not k then return end
	rawset(self, k, rawget(self,k) or require("classes." .. k))
	return rawget(self,k)
end

local newindex = function (self, k, v)
	if not class.classinfo[v] then return end
	return rawset(self,k,v)
end

classes = classes or setmetatable(
	{},
	{
		__index = index,
		__newindex = newindex,
		__call = index,
	}
)

-- Note: It's tempting to include allowance for singletons, but if we ever want one we can just assign a global. Not worth the trouble here.
return class, classes