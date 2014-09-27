--[[ Rect Grid class
--	Used as a final class, provides initialization and transposition methods for a standard rectangular grid.
--	As with other grids, requires setting textures and such before much can be done.
--]]

class.require('grid')
local c = class('rectgrid','grid')
local abs = math.abs
local transpose = {}

c.initialize = function (self)
	self:SafeSet('dimensions',2)
	self:SafeSet('grid.repeat',false)
	self:SafeSet('grid.init','initRectGrid')
	self:Set('grid.transpose',transpose)

	self:InitGrid()
	return self
end

return c
