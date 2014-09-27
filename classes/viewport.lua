--[[
--	Viewport stub class
--	We attempt to automate the viewport creation process as much as possible by using MOAIEnvironment if vars aren't set.
--	This will only ever create one viewport, accessible via self:GetObject('viewport').
--]]

local c = class("viewport")
local cfg = config.Get

c.InitViewport = function (self)
	self:Log(1,'InitViewport')
	-- Use the config system to enable a singleton viewport
	local viewport = cfg('viewport','viewport',MOAIViewport.new)
	self:SafeSet("viewport",viewport)

	local initialized = cfg('viewport','initialized')
	if not initialized then
		self:Log(2,'InitViewport','First time viewport initialization in progress.')
		viewport:setSize(cfg('viewport','sizeX',MOAIEnvironment.horizontalResolution),
		                 cfg('viewport','sizeY',MOAIEnvironment.verticalResolution))
		viewport:setScale(cfg('viewport','scaleX',MOAIEnvironment.horizontalResolution),
		                  cfg('viewport','scaleY',MOAIEnvironment.verticalResolution)) 
		config.Set('viewport','initialized',true)
	end

	return viewport
end

return c
