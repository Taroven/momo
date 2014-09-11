--[[ classes.viewmanager: Stub class that allows for a default viewport and camera.
	Included automatically by classes.layer:InitLayer(x).
	
	TODO: Camera fitter and manipulation methods are needed.
--]]

local c = class("viewmanager")

if not _vm then
	_vm = {MOAIViewport.new(),MOAICamera2D.new()}
end

c._viewport = _vm[1]
c._camera = _vm[2]

c.GetCamera = function (self) return self._camera end
c.GetViewport = function (self) return self._viewport end

c.ShowLayer = function (self)
	if self._layer then
		return self._layer:setViewport(self._viewport)
	end
end

c.HideLayer = function (self)
	if self._layer then
		return self._layer:setViewport(nil)
	end
end

c.ApplyCamera = function (self)
	if self._layer then
		return self._layer:setCamera(self._camera)
	end
end

c.RemoveCamera = function (self)
	if self._layer then
		return self._layer:setCamera(nil)
	end
end