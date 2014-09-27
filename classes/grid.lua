--[[ Grid class
--	Used as an inheritance, provides basic methods for interacting with a MOAIGridSpace compatible object.
--
--]]

class.require('layer','cache')
local c = class('grid','layer','cache')

c.InitGrid = function (self)
	self:SafeSet('dimensions',2)
	self:SafeSet('grid.repeat',false)
	
	local layer = self:InitLayer()
	local deck = self:InitDeck()
	self:InitCache()

	local grid = self:SafeSet('grid',MOAIGrid.new)
	grid._class = self
	
	local prop = self:SafeSet('grid.prop',MOAIProp2D.new)
	prop._class = self
	prop:setDeck(deck)
	prop:setGrid(grid)
	layer:insertProp(prop)
	prop:forceUpdate()

	self:SafeSet('grid.transpose',{})
	self:SafeSet('grid.dimensions.x',10)
	self:SafeSet('grid.dimensions.y',10)
	
	self:ResizeGrid()
	return grid
end

c.ResizeGrid = function (self, x, y, tx, ty, gx, gy)
	local args = {...}
	local x = self:OptSet('grid.dimensions.x',x,10)
	local y = self:OptSet('grid.dimensions.y',y,10)
	local tx = self:OptSet('grid.tile.x',tx,1)
	local ty = self:OptSet('grid.tile.y',ty,1)
	local gx = self:OptSet('grid.gutter.x',gx,0)
	local gy = self:OptSet('grid.gutter.y',gy,0)
	local grid = self:Get('grid')
	local init = grid[self:Get('grid.init')]
	return init(grid, x, y, tx, ty, gx, gy)
end

c.ShowGrid = function (self,layer)
	return (layer or self:Get('layer')):removeProp(self:Get('grid.prop'))
end

c.HideGrid = function (self,layer)
	return (layer or self:Get('layer')):insertProp(self:Get('grid.prop'))
end

c.Transpose = function (self, method, ...)
	local f = self:Get('grid.transpose')[method]
	if f then return f(self,...) end
end

local cfrom = {}
cfrom.world = function (self,x,y)
	local grid = self:Get('grid')
	return grid:wrapCoord(grid:locToCoord(self:Get('grid.prop'):worldToModel(x,y)))
end
crom.window = function (self,x,y)
	return self:GridCellFromWorld(self:Get('layer'):wndToWorld(x,y))
end

local cto = {}
cto.world = function (self,x,y)
	return self:Get('grid.prop'):modelToWorld(self:Get('grid'):getTileLoc(x,y))
end

c.GridCoordTo = function (self, k, ...)
	local f = cto[k]
	if f then return f(self,...) end
end

c.GridCoordFrom = function (self, k, ...)
	local f = cfrom[k]
	if f then return f(self,...) end
end

return c
