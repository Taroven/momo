local c = class("grid", classes.layer, classes.tiledeck)

c.InitGrid = function (self, dimensions)
	self._dimensions = 3
	
	local grid = self:GetGrid()
	local prop = self:GetGridProp()
	local layer = self:GetLayer()
	local deck = self:GetDeck()
	
	prop:setDeck(deck)
	prop:setGrid(grid)
	layer:insertProp(prop)
end

c.GetGrid = function (self)
	if not self._grid then
		self._grid = MOAIGrid2D.new()
		self._grid._class = self
	end
	
	return self._grid
end

c.GetGridProp = function (self)
	if not self._grid then self:GetGrid() end
	if not self._grid._prop then
		self._grid._prop = MOAIProp2D.new()
		self._grid._prop._class = self
	end
	
	return self._grid._prop
end

-- Environment conversion methods
-- Translate world coord to cell X/Y (collision)
c.WorldToGrid = function (self,x,y)
	return self._grid:wrapCoord(self._grid:locToCoord(self._grid._prop:worldToModel(x, y)))
end

-- Translate cell X/Y to world coord (prop placement)
c.GridToWorld = function (self,x,y)
	return self._grid._prop:modelToWorld(self._grid:getTileLoc(x, y))
end

-- Translate window X/Y to cell X/Y (touch handling)
c.WindowToGrid = function (self,x,y)
	return self:WorldCoordToGridCell(self._layer:wndToWorld(x,y))
end

c.SetGridRepeat = function (self, rep)
	return self._grid:setRepeat(rep)
end

return c