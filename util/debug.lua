local m = {}

local type,assert,error,select = type,assert,error,select

-- Throw an error if an arg's type doesn't match an intended type.
-- Example: function foo (a, b, c) util.debug.argcheck(a, 1, 'string'); DoStuff(a) end
m.argcheck = function (value, num, ...)
   assert(type(num) == 'number', "Bad argument #2 to 'argcheck' (number expected, got "..type(num)..")")

   for i=1,select("#", ...) do
      if type(value) == select(i, ...) then return true end
   end

   local types = table.concat({...}, ", ")
   local name = string.match(debug.traceback(2,2,0), ": in function [`<](.-)['>]")
   error(("Bad argument #%d to '%s' (%s expected, got %s"):format(num, name, types, type(value)), 3)
end

argcheck = argcheck or m.argcheck

return m
