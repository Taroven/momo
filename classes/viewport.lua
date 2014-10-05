--[[
--	Viewport stub class
--	We attempt to automate the viewport creation process as much as possible by using MOAIEnvironment if vars aren't set.
--	This will only ever create one viewport, accessible via self:GetObject('viewport').
--]]

local c = class("viewport")
local cfg = class.config

c.InitViewport = function (self)
	self:Log(1,'InitViewport')
	-- Use the config system to enable a singleton viewport
local viewport = cfg:Get('viewport',MOAIViewport.new)
	self:SafeSet("viewport",viewport)

	local initialized = cfg:Get('viewport.initialized')
	if not initialized then
		self:Log(2,'InitViewport','First time viewport initialization in progress.')
		viewport:setSize(cfg:Get('viewport.dimensions.x',MOAIEnvironment.horizontalResolution),
		                 cfg:Get('viewport.dimensions.y',MOAIEnvironment.verticalResolution))
		viewport:setScale(cfg:Get('viewport.scale.x',MOAIEnvironment.horizontalResolution),
		                  cfg:Get('viewport.scale.y',MOAIEnvironment.verticalResolution)) 
		cfg:Set('viewport.initialized',true)
	end

	return viewport
end

return c
