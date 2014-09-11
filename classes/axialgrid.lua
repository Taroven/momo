local c = class("axialgrid",classes.grid)

-- classes.grid provides us with the building blocks of a graphic grid, only requiring hex initialization and translation
c.initialize = function (self, ...)
	self:InitGrid(3)
	
	self:GetGrid():initAxialHexGrid(...)
end

-- Transposition is really easy when using offset coords, since we can mostly just use a compass table.
local transpose = {}

-- point: Pick a point R spaces away (default 1) in direction D (no default, will error).
transpose.point = function (x, y, z, d, r)
	local dkey, r = neighbors[d], r or 1
	return x + (dkey[1] * r), y + (dkey[2] * r), z + (dkey[3] * r)
end

-- Get all points between range S (start) and R (finish/range/radius) in D (direction).
-- Allows passing a result table to prevent memory churn.
transpose.range = function (x, y, z, d, s, r, t)
	local results = t or {}
	for i = s, r do
		results[#results + 1] = transpose.point(x,y,z,d,i)
	end
	return results
end

-- ring: Create a hexagonal ring of radius R.
-- Allows passing a result table to prevent memory churn.
-- Radius 0 will return the origin coords.
transpose.ring = function (x, y, z, r, t)
	local x, y, z = transpose.point(x, y, z, 5, r) -- direction 5 allows for a clean loop without special handling.
	local results = t or {}
	for d = 1, 6 do
		for i = 1, r do
			x, y, z = transpose.point(x, y, z, d) -- transpose.range would be more readable, but function cost loses out here.
			results[#results + 1] = {x, y, z}
		end
	end
	if r == 0 then results[#results + 1] = {x,y,z} end
	return results
end

-- spiral: Like transpose.range, but with rings.
-- Could be accurately named "disc", but the return is an outward spiral pattern, so going with that.
-- Memory churn is optimized, but remember that the number of tiles collected is exponential by radius.
-- spiral(x,y,z, 0, r) to include the origin cell.
-- Complex patterns are best left to other transpositions.
-- See above about the result table.
transpose.spiral = function (x, y, z, s, r, t)
	local results = t or {}
	for i = s, r do
		transpose.ring(x, y, z, i, results)
	end
	return results
end

-- TODO: transpose.distance: calculate distance between two cells.
-- Unfortunately since Moai uses a funky coord system, this isn't realistic at the moment.
-- The only feasible way without a reworked coord system would be to use some crazy pathfinding (just no) or a second set of coords (which would only be useful for this).
-- This may be fixed using axial coordinates introduced around 1.5, but impossible to test at the moment.
-- For now, it may be better to use transpose.spiral and test against affected cells.

-- transpose.arc: Alright, so it's a little awkward, but here goes. A proportionate hex cell can be subdivided into 6 60-degree segments.
-- We don't care about the angles involved, but the principal makes some nifty arcs.
-- Works like transpose.range as far as args go (and even uses .range to drive the point home)
transpose.arc = function (x, y, z, d, s, r, t)
	local results = t or {}
	for i = s, r do
		local xx,yy,zz = transpose.point(x,y,z,d,i) -- move 1 cell in the desired direction
		transpose.range(xx, yy, zz, math.abs((d + 2) - 6), 0, i - 1, results) -- pick that cell and i-1 (FIXME: Directional math or relation table) perpendicular cells
	end
	return results
end

-- 2D rect coords (q,r) convert nicely to 3D offset coords (x,y,z) and vice versa when dealing with hex grids.
-- The main stumbling point is exactly what rules the conversion needs to follow.
-- Short story is that Moai converts cleanly to "Odd-R". Use that one.
-- Basically Z axis remains the same as R, X is a relation between Q and R, and Y is a derivative.
-- We get to completely ignore Y when converting back to rect coords, passing Z and solving against X. Cool, eh?
-- Moai starts grid coords at 1, so clean conversion requires +-1 to Q/R coords in all cases.
-- We only use locals for sanity...
local conversion = {
	toOffset = {
		evenq = function (q, r)
			local q, r = q - 1, r - 1
			local z = r - (q + q%2) / 2
			return q, -q-z, z
		end,

		oddq = function (q, r)
			local q, r = q - 1, r - 1
			local z = r - (q - q%2) / 2
			return q, y, -q-z
		end,

		evenr = function (q, r)
			local q, r = q - 1, r - 1
			local x = q - (r + r%2) / 2
			return x, -x-r, r
		end,

		oddr = function (q, r)
			local q, r = q - 1, r - 1
			local x = q - (r - r%2) / 2
			return x, -x-r, r
		end,
	},
	
	toRect = {
		evenq = function (x, y, z)
			local r = z + (x + x%2) / 2
			return x+1, r+1
		end,

		oddq = function (x, y, z)
			local r = z + (x - x%2) / 2
			return x+1, r+1
		end,

		evenr = function (x, y, z)
			local q = x + (z + z%2) / 2
			return q+1, z+1
		end,

		oddr = function (x, y, z)
			local q = x + (z - z%2) / 2
			return q+1, z+1
		end,
	},
}

-- Sets coordinate conversion equations to match the grid layout.
-- Moai converts cleanly to Odd-R equations, but the rest are kept around for fun.
c.SetConversion = function (self, key)
	if conversion.rect[key] then
		self._toOffset = conversion.toOffset[key]
	end
	if conversion.offset[key] then
		self._toRect = conversion.toRect[key]
	end
end

c.Transpose = function (self, method, ...)
	local f = transpose[method]
	if f then return f(...) end
end

-- Convenience methods
c.GetOffsetCoords = function (self, x, y)
	return self._toOffset(x,y)
end

c.GetRectCoords = function (self, x, y, z)
	return self._toRect(x,y,z)
end

c.ConvertCoords = function (self, ...)
	local n = select("#",...)
	if n == 2 then return self._toOffset(...)
	elseif n == 3 then return self.toRect(...)
	end
end

return c