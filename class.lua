-- Middleclass and Classy have their quirks. So does Lash, but Lash happens to be built to preference, so...

-- Magic trick: To require and init an instance, now we just use classes["whatever"](args). Everything is nicely indexed for us.
-- Just don't try to do anything with a class that doesn't exist. Bad mojo.

local class = require"lash"
local log = require"log"

class.classpath = "momo.classes"

function class.Object:Log (self, level, method, ...)
	argcheck(method,2,'string')
	argcheck(level,3,'number','nil')
	return log(self, level, method, ...)
end

return class
