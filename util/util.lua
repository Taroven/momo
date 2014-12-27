local util = {}

local type,assert,error,select = type,assert,error,select

-- Enhanced type example: type({},"string","table") == "table", 2
-- Useful for switch statements or basic arg checking (use util.argcheck for a strict approach)
local otype = type
util.type = function (value, ...)
	local n = select("#", ...)
	if n == 0 then return otype(value) end
	for i=1,n do
		if otype(value) == select(i, ...) then
			return otype(value), i
		end
	end
end

-- Macro for quick MD5 hashing.
util.gethash = function (data)
   local writer = MOAIHashWriter.new()
   writer:openMD5()
   writer:write(data)
   writer:close()
   return writer:getHashHex()
end

-- Throw an error if an arg's type doesn't match an intended type.
-- Example: function foo (a, b, c) util.argcheck(a, 1, 'string'); DoStuff(a) end
util.argcheck = function (value, num, ...)
   assert(type(num) == 'number', "Bad argument #2 to 'argcheck' (number expected, got "..type(num)..")")

   for i=1,select("#", ...) do
      if type(value) == select(i, ...) then return true end
   end

   local types = table.concat({...}, ", ")
   local name = string.match(debug.traceback(2,2,0), ": in function [`<](.-)['>]")
   error(("Bad argument #%d to '%s' (%s expected, got %s"):format(num, name, types, type(value)), 3)
end

return util
