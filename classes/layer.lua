class.require('viewport')
local c = class('layer','viewport')

c.InitLayer = function (self)
	self:InitViewport()
	local layer = self:Get('layer',MOAILayer2D.new)
	return layer
end

c.ShowLayer = function (self)
	self:Log(1,'ShowLayer')
	local layer = self:Get('layer')
	if layer then
		local viewport = self:Get('viewport')
		layer:setViewport(viewport)
		self:Set('layer.visible',true)
	end
end

c.HideLayer = function (self)
	self:Log(1,'HideLayer')
	local layer = self:Get('layer')
	if layer then
		layer:setViewport(nil)
		self:Set('layer.visible',false)
	end
end

c.initialize = c.InitLayer
return c
