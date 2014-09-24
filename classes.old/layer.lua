local c = class("layer","viewmanager")
class.require("propcache")

c.InitLayer = function (self, dimensions)
	self._layer = MOAILayer2D.new()
	self._layer._class = self
	self._layer._cache = class.classes.propcache(dimensions or self._dimensions)
	self._layer._cache._layer = self._layer
	
	self.InitLayer = function (self) return self._layer end -- Just in case this gets called more than once.
	return self._layer
end

c.GetLayer = function (self)
	return self._layer or self:InitLayer()
end

c.GetProp = function (self, ...)
	return self._layer._cache:Get(...)
end

c.RemoveProp = function (self, ...)
	return self._layer._cache:Remove(...)
end

c.GetCache = function (self)
	return self._layer._cache
end

return c