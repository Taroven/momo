--[[ Object caching system
--	Provides a mechanism for reusing objects (default: MOAIProp2D) in order to save memory.
--	Caching may be done by coordinates or index, allowing the cache to work equally well with a grid or a list.
--	This is not a wholly efficient system! If working with a small number of objects, don't cache them.
--	USES:
--		- dimensions - Default 1, preset via Grid types. Used for cache table depth and coordinate hashing.
--		- layer - No default. Used in object:Show/Hide/Toggle for layer:insertProp.
--	IMPLEMENTS:
--		-- propcache.map - Hash-indexed mapping table for active props.
--		-- propcache.active - indexed table containing references to active props.
--		-- propcache.cached - indexed table containing references to cached props.
--		-- propcache.class - Type of object to cache. Must be compatible with MOAIProp2D.
--		-- propcache.interface - Extra methods added to created objects.
--		-- propcache.onassign - Function fired when an object is created or pulled from the cache.
--		-- propcache.onremove - Function fired when an object is removed and placed in the cache.
--		-- propcache.onacquire - Function fired when an object is pulled via :CacheGet
--		-- propcache.newprop - Function used to create new objects.
--		-- propcache.oldprop - Function used to remove objects from activity.
--
--	METHODS:
--		-- :CacheHash(coords) - Return a (hopefully) valid hash used by propcache.map
--		-- :CacheGet(coords) - Returns an object at the specified coords (may be existing, new, or from cache) and fires obj:OnAcquire()
--		-- :CacheFind(coords) - Returns an active object or nil if nothing exists at coords. Does not fire OnAcquire.
--		-- :CacheRemove(coords) - Removes and caches an active object at coords. (Use obj:Remove() if removing by reference)
--		-- :InitCache() - Sets up the cache for use. (Method is fairly self-documenting)
--]]

local c = class('propcache')

local concat = table.concat or concat
local setmetatable, getmetatable = setmetatable, getmetatable
local rawget, rawset = rawget, rawset
local type, tonumber, tostring = type, tonumber, tostring
local pairs, ipairs = pairs, ipairs

-- Automagic table creation up to a set depth, making our cache lookups way less painful.
local map
local setmap = function (object,level)
	return setmetatable({},{
		__index = map,
		object = object,
		level = level,
	})
end

map = function (self,k)
	local v = rawget(self,k)
	if v then return v end

	local mt = getmetatable(self)
	if mt.level < mt.object:Get('dimensions') - 1 then
		rawset(self, k, setmap(mt.object, mt.level + 1))
	end
	
	return rawget(self,k)
end

-- class:[Safe]Set fires any function passed to it and sets the result as the value. This gets around that.
local setf = function (f)
	if f then
		return function () return f end
	else return function (self) return self end
	end
end

-- Initialize the cache, using defaults if needed.
-- SafeSet is used in all cases to make things safer and easier. Set variables beforehand if not using a compatible class as a parent.
c.InitCache = function (self)
	self:SafeSet('dimensions',1)
	self:SafeSet('propcache.map',setmap(self,1))
	local _cached = self.SafeSet('propcache.cached',{})
	local _active = self.SafeSet('propcache.active',{})
	local _class = self.SafeSet('propcache.class',MOAIProp2D)
	local _interface = self:SafeSet('propcache.interface', {
		Remove = function (self) return self._cache:Remove(self, unpack(self.coords)) end,

		SetBatch = function (self, t)
			for k,v in pairs(t or {}) do
				if tonumber(k) then
					self[v[1]](self,unpack(v[2]))
				else
					self[k](self,unpack(v))
				end
			end
		end,

		OnAssign = function (self)
			return self._cache:Get('propcache.onassign')(self)
		end,

		OnRemove = function (self)
			return self._cache:Get('propcache.onremove')(self)
		end,

		OnAcquire = function (self)
			return self._cache:Get('propcache.onacquire')(self)
		end,

		Show = function (self)
			local layer = self._layer or self._cache:Get('layer')
			if layer then
				self._layer = layer
				return layer:insertProp(self)
			end
		end,

		Hide = function (self)
			local layer = self._layer or self._cache:Get('layer')
			if layer then
				layer:removeProp(self)
				self._layer = nil
			end
		end,

		Toggle = function (self)
			if self._layer then return self:Hide()
			else return self:Show() end
		end,
	})

	setmetatable(_interface, {__index = self:Get('propcache.class').getInterfaceTable()})

	self:SafeSet('propcache.onassign', setf)
	self:SafeSet('propcache.onremove', setf)
	self:SafeSet('propcache.onacquire', setf)

	self:SafeSet('propcache.newprop', setf( function (self, ...)
		local obj = table.remove(_cached) or _class.new()
		obj._cache = self
		obj._coords = {...}
		obj:setInterface(_interface)
		obj:OnAssign()
		table.insert(_active, obj)
		return obj
	end))

	self:SafeSet('propcache.oldprop', setf( function (self, obj)
		if _active[obj] then
			_active[obj]:OnRemove()
			return table.insert(_cached, table.remove(_active, i))
		else
			for i,v in ipairs(_active) do
				if v == obj then
					v:OnRemove()
					return table.insert(_cached, table.remove(_active, i))
				end
			end
		end
	end))
end

c.CacheHash = function (self, ...)
	local d = self:Get('dimensions')
	local n = select('#',...)
	if d == 1 then
		return (...)
	elseif d == n then
		return concat({...},self:Get('propcache.delimiter','/'))
	end
end

c.CacheFind = function (self, ...)
	local hash = self:CacheHash(...)
	if hash then
		return self:Get('propcache.map')[hash] 
	end
end

c.CacheGet = function (self, ...)
	local hash = self.CacheHash(...)
	if hash then
		local map = self:Get('propcache.map')
		local o = map[hash] or self:Get('propcache.newprop')(self, ...)
		map[hash] = o
		if o and o.OnAcquire then return o:OnAcquire()
		else return o end
	end
end

c.CacheRemove = function (self, ...)
	local hash = self.CacheHash(...)
	if hash then
		self:Get('propcache.oldprop')(self:Get('propcache.map')[hash])
		self:Get('propcache.map')[hash] = nil
	end
end

return c
