-- Middleclass and Classy have their quirks. So does Lash, but Lash happens to be built to preference, so...

-- Magic trick: To require and init an instance, now we just use classes["whatever"](args). Everything is nicely indexed for us.
-- Just don't try to do anything with a class that doesn't exist. Bad mojo.

config = config or require"configuration"
class = class or require"lash"
classconfig = classconfig or setmetatable({},{
	__index = function (self,k)
		local v = rawget(self,k)
		if v then return v
		else
			v = {}
			rawset(self,k,v)
			return v
		end
	end,
})
local log = log or require"log"
local util = util or require 'util'
local rawset,rawget = rawset,rawget

local obj = class.Object
obj.Log = function (self, level, method, ...)
	util.argcheck(method,2,'string')
	util.argcheck(level,3,'number','nil')
	return log(self, level, method, ...)
end

obj.Set = function (self, k, v, raw)
	self._objects = self._objects or {}
	if (not raw) and type(v) == 'function' then v = v() end
	self._objects[k] = v
	return self._objects[k]
end

obj.SafeSet = function (self, k, v, raw)
	self._objects = self._objects or {}
	if type(self._objects[k]) == 'nil' then
		return self:Set(k,v)
	end
end

obj.Get = function (self, k, default, raw)
	self._objects = self._objects or {}
	if (type(self._objects[k]) == 'nil') and (type(default) ~= 'nil') then
		self:Set(k,default,raw)
	end
	return self._objects[k]
end

obj.OptSet = function (self, k, v, default, raw)
	if type(v) == 'nil' then
		return self:Get(k,default,raw)
	else
		return self:Set(k,v,raw)
	end
end

-- Macros for class-specific configuration (see configuration.lua for usage)
obj.GetConfig = function (self, k, default)
	return config.GetConfig(self.__id or self.__name,k,default)
end

obj.SetConfig = function (self, k, v)
	return config.SetConfig(self.__id or self.__name,k,v)
end

obj.SafeSetConfig = function (self, k, v)
	return config.SafeSet(self.__id or self.__name,k,v)
end

-- Note: It's tempting to include allowance for singletons, but if we ever want one we can just assign a global. Not worth the trouble here.
return class
