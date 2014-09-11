local c = class("axialgrid",classes.grid)

-- classes.grid provides us with the building blocks of a graphic grid, only requiring hex initialization and translation
c.initialize = function (self, ...)
	self:InitGrid(3)
	
	self:GetGrid():initAxialHexGrid(...)
end

