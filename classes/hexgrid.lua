--[[ Hex Grid class
--	Used as a final class, provides initialization and transposition methods for an axial hex grid.
--	As with other grids, requires setting textures and such before much can be done.
--]]

class.require('grid')
local c = class('hexgrid','grid')
local abs = math.abs
local transpose = {}

c.initialize = function (self)
	self:SafeSet('dimensions',2)
	self:SafeSet('grid.repeat',false)
	self:SafeSet('grid.init','initAxialHexGrid')
	self:Set('grid.transpose',transpose)
	
	self:InitGrid()
	return self
end

-- Direction map used in transposition methods
local neighbors = {
	{1,  1},	-- Up (right)
	{1,  0},	-- Right
	{0, -1},	-- Down (right)
	{-1,-1},	-- Down (left)
	{-1, 0},	-- Left
	{-1, 1},	-- Up (left)
}

-- All transposition methods except for .point allow for a table as the final arg. If used, results are appended to the table instead of returned directly.

-- Starting from point(x,y), travel (r) tiles in direction (d)
transpose.point = function (self, x, y, d, r, t)
	local key, r = neighbors[d], r or 1
	return x + (dkey[1] * r), y + (dkey[2] * r)
end

-- As point, but return all cells from (s) to (r) distance.
transpose.range = function (self, x, y, d, s, r, t)
	t = t or {}
	local dkey = neighbors[d]
	for i = s, r do
		-- emulate transpose.point here to save on function cost
		t[#t + 1] = { x + (dkey[1] * i), y + (dkey[2] * i) }
	end
	return t
end

-- Using point(x,y) as center, return a ring of (r) radius.
transpose.ring = function (self, x, y, r, t)
	t = t or {}
	x, y = transpose.point(x,y,5,r)
	for d = 1,6 do
		for i = 1, r do
			x, y = x + (neighbors[d][1] * i), y + (neighbors[d][2] * i)
			t[#t + 1] = {x,y}
		end
	end
	if r == 0 then t[#t + 1] = {x,y} end
	return t
end

-- transpose.ring with thickness (see transpose.line)
transpose.spiral = function (self, x, y, s, r, t)
	t = t or {}
	for i = s,r do
		transpose.ring(x,y,i,t)
	end
	return t
end

-- As transpose.line, but filling all cells "within" the target direction (~60 degree arc)
transpose.arc = function (self, x, y, d, s, r, t)
	t = t or {}
	for i = s,r do
		local xx,yy = transpose.point(x,y,d,i)
		transpose.range(xx, yy, abs((d+2) - 6), 0, i - 1, t)
	end
end

transpose.distance = function (self, x, y, x2, y2)
	return (abs(x - x2) + abs(y - y2) + abs(x + y - x2 - y2)) / 2
end

return c
