-- Middleclass and Classy have their quirks. So does Lash, but Lash happens to be built to preference, so...

-- Magic trick: To require and init an instance, now we just use classes["whatever"](args). Everything is nicely indexed for us.
-- Just don't try to do anything with a class that doesn't exist. Bad mojo.
local rawset,rawget = rawset,rawget

local index = function (self,k)
	if not k then return end
	rawset(self, k, rawget(self,k) or require("classes." .. k)
	return rawget(self,k)
end

local newindex = function (self, k, v)
	if not class.classinfo[v] then return end
	return rawset(self,k,v)
end

classes = classes or setmetatable(
	{},
	{
		__index = index,
		__newindex = newindex,
		__call = index,
	}
)

class = class or require("middleclass")
class.Object.__metamethods = {"__tostring"}

-- Note: It's tempting to include allowance for singletons, but if we ever want one we can just assign a global. Not worth the trouble here.
return class, classes