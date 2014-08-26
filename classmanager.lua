-- Middleclass quasiproxy that does really cool stuff.

-- Middleclass does one very bad thing: It hijacks all metamethods except __index.
-- This becomes exceptionally annoying when trying to do anything useful with an instance root table. Rather than set up replacement metamethods, we just nuke the placeholder responsible for the issue.
-- That being said, defining c.__call (etc) requires adding to the methods table like so:
-- c.__metamethods = {"__call"}; c.__call = function (self) doStuff() end

-- Magic trick: To require and init an instance, now we just use classes["whatever"](args). Everything is nicely indexed for us.
-- Just don't try to do anything with a class that doesn't exist. Bad mojo.
local rawset,rawget = rawset,rawget

local index = function (self,k)
	if not k then return end
	rawset(self, k, rawget(self,k) or require("classes." .. k)
	return rawget(self,k)
end

local newindex = function (self, k, v)
	if not k and type(v) == "table" then return end
	if not (v.name or v.class) and getmetatable(v) then return end
	return rawset{self,k,v}
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