--[[ Prop management class with grid helpers.

	Setting defaults (prop is always passed as arg[1]):
		local cache = propcache.new()
		local prop, index = cache()
		prop:Remove()

		local defaults = function (self,prop)
			prop:setStuff(self.stuff)
		end
		cache:SetDefaults(defaults) or cache._onassign = defaults

		local prop, index = cache()
		prop:getLoc() == 150,150
		defaults.setLoc = {0,0} -- K/V pairs go after indexed pairs, so this case would be completely accurate.
		prop:OnAssign() -- Force defaults
		prop:getLoc() == 0,0
		cache:Remove(index)

	Usage (grid):
		local cache = propcache.new(3) -- Number of dimensions can be 1, 2, or 3 (default 1)
		local prop, x, y, z = cache(1,2,3) == prop, 1, 2, 3
		prop:Remove() or cache:Remove(x,y,z)

	Usage (advanced):
		local cache = propcache.new({
			set = function (self, ...) end,
			get = function (self, ...) end,
			dimensions = (number) })
		-- Continue as normal. Make sure .dimensions is either accurate to your needs or 0/1 if needs are fluid.
--]]

local pairs, ipairs, type, tonumber = pairs, ipairs, type, tonumber
local unpack = unpack or table.unpack
local newprop, oldprop

local c = class("propcache")

c.initialize = function (self, dimensions)
	self._active = {}
	self._cached = {}

	self._layer = layer
	self._interface = {
		Remove = function (self) return self._cache:Remove(self, unpack(self._coords)) end,

		SetBatch = function (self, t)
			for k,v in pairs(t or {}) do
				if tonumber(k) then self[v[1]](self,unpack(v[2]))
				else self[k](self,unpack(v)) end
			end
		end,

		OnAssign = function (self, ...)
			return self._cache._onassign(self, ...)
		end,

		OnRemove = function (self)
			return self._cache._onremove(self)
		end,

		OnAcquire = function (self)
			return self._cache._onacquire(self)
		end,

		Show = function (self)
			if self._cache._layer then
				self._layer = self._cache._layer
				return self._layer:insertProp(self)
			end
		end,

		Hide = function (self)
			if self._layer then
				self._layer:removeProp(self)
				self._layer = nil
			end
		end,

		Toggle = function (self)
			if self._layer then return self:Hide()
			else return self:Show() end
		end,
	}
	self:SetOnAssign()
	self:SetOnAcquire()
	self:SetOnRemove()
	self:SetMapping(dimensions or 1)
	setmetatable(self._interface, {__index = MOAIProp2D.getInterfaceTable()})
end

newprop = function (self, ...)
	local prop = table.remove(self._cached) or (self._propclass or MOAIProp2D).new()

	prop._cache = self
	prop._coords = {...}
	prop:setInterface(self._interface)

	prop:OnAssign()
	table.insert(self._active, prop)
	return prop
end

oldprop = function (self, prop)
	if self._active[prop] then
		self._active[prop]:OnRemove()
		return table.insert(self._cached, table.remove(self._active, prop))
	else
		for i,v in ipairs(self._active) do
			if v == prop then
				v:OnRemove()
				return table.insert(self._cached, table.remove(self._active, i))
			end
		end
	end
end


-- Use 1 for simple index, 2 for X/Y coords, 3 for axial coords.
-- If something more complex is required, see top for an example and modify accordingly.
-- NOTE: Doesn't have to be numeric coords. You can use whatever you want for organization.
local map = {
	[1] = {
		set = function (self, prop, x)
			local k = x or (#self._cachemap + 1)
			self._cachemap[k] = prop
			return prop, k
		end,

		get = function (self, x)
			return self._cachemap[x]
		end,

		dimensions = 1,
	},

	[2] = {
		set = function (self, prop, x, y)
			self._cachemap[x][y] = prop
			return prop
		end,

		get = function (self, x, y)
			return self._cachemap[x][y]
		end,

		dimensions = 2,
	},

	[3] = {
		set = function (self, prop, x, y, z)
			self._cachemap[x][y][z] = prop
			return prop
		end,

		get = function (self, x, y, z)
			return self._cachemap[x][y][z]
		end,

		dimensions = 3,
	},
}

-- Neat metamethod that allows the cachemap to dynamically size itself, making the map functions much more friendly.
local cachemap
cachemap = function (self,k)
	local v = rawget(self,k)
	if v then return v
	else
		local mt = getmetatable(self)
		if mt.level < mt.dimensions - 1 then
			rawset(self, k, setmetatable({},{
				__index = cachemap,
				level = mt.level + 1,
				dimensions = mt.dimensions,
			}))
		end
	end
	return rawget(self, k)
end

-- Sets the mapping function to one of the defaults or a custom get/set table.
c.SetMapping = function (self, t)
	--argcheck(t, 2, "table", "number", "nil")
	t = tonumber(t or 1) and map[t] or t
	self.Find = t.get or t.find or t.Get or t.Find
	self.Set = t.set or t.Set
	self._dimensions = t.dimensions

	self._cachemap = setmetatable({},{
		__index = cachemap,
		level = 1,
		dimensions = self._dimensions,
	})
end

-- prop:OnAssign() is called when a prop is created or assigned from the cache.
c.SetOnAssign = function (self, f)
	self._onassign = f or function () end
end

-- prop:OnRemove() is called when a prop is cached and removed from active status.
c.SetOnRemove = function (self, f)
	self._onremove = f or function () end
end

-- prop:OnAcquire() is called when any time a prop is retrieved via cache:Get(). prop:OnAssign() is called first if this is a newly assigned prop.
-- cache:Get() returns prop:OnAcquire(). OnAcquire should ALWAYS return self, otherwise you will end up with no reference to the prop except via cache._cachemap.
c.SetOnAcquire = function (self, f)
	self._onacquire = f or (function (self) return self end)
end

-- The prop type may be set to any derivative of MOAIProp/2D or probably MOAITransform/2D without issue.
-- Textbox2D comes to mind.
c.SetPropClass = function (self, propclass)
	if type(propclass) == "userdata" then self._propclass = propclass
	else self._propclass = MOAIProp2D end
	return self
end

c.GetPropClass = function (self, propclass)
	if propclass then return self._propclass == propclass
	else return self._propclass end
end

-- Kill a prop by its coords (or index if not on a grid) and remove it from the map (even if inactive or nonexistant)
-- If you need to remove by reference, use prop:Remove() instead.
c.Remove = function (self, ...)
	local prop = self:Find(...)
	if prop then
		oldprop(prop)
	end
	return self:Set(nil, ...)
end

-- Create or retrieve a prop handled by the cache.
-- Grid coordinates are absolutely required if working in more than one dimension.
-- Use multiple caches if you need multiple handling methods.
c.Get = function (self, ...)
	if self._dimensions > 1 and select("#",...) ~= self._dimensions then return end
	local prop = self:Find(...) or newprop(self,...)
	return prop:OnAcquire()
end

c.__call = c.Get
return c