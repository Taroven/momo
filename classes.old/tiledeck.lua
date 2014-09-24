--[[ classes.tiledeck: Stub class providing deck manipulation methods
	Note: TileDeck2D inherits from GridSpace... Makes sense and could have some fun uses.
	While one could perform an init[Diamond|Hex|Oblique|Rect|Axial]Grid() on the deck, my immediate question would be "Why?". The only realistic use I could think of for doing so would be if the deck is intended to be used as a map instead of a sheet, translating cell coords directly to the coords of a Grid2D. Not an efficient way to use a deck, for sure...
--]]

local c = class("tiledeck")

c.GetDeck = function (self)
	if not self._deck then
		self._deck = MOAITileDeck2D.new()
		self._deck._class = self
	end
	
	return self._deck
end

c.GetDeckTexture = function (self)
	return self._deck:getTexture()
end

c.GetDeckSize = function (self)
	return self._deck:getSize()
end

c.SetDeckShader = function (self, ...)
	return self._deck:setShader(...)
end

c.SetDeckTexture = function (self, ...)
	return self._deck:setTexture(...)
end

c.SetDeckSize = function (self, ...)
	return self._deck:setSize(...)
end

c.GetDeckIndex = function (self, ...)
	return self._deck:locToCellAddr(...)
end

c.GetDeckCoord = function (self, address)
	return self._deck:cellAddrToCoord(address)
end

c.WrapDeckCoord = function (self, x, y)
	return self._deck:wrapCoord(x,y)
end

return c