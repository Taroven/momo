local config = {}

local type, rawset, rawget = type, rawset, rawget

local cfg = setmetatable({},{
	__index = function (self,k)
		local v = rawget(self,k)
		if v then return v
		else
			v = {}
			rawset(self,k,v)
			return v
		end	
	end,
})

--[[ Partitioned configuration
--	While the idea of a big static configuration table or a per-class config is appealing, we want the happy medium.
--	Config partitions are really just categorized tables with mediator methods. That's it, nothing complicated.
--]]

-- Retrieve a config value and/or set it to a provided default.
-- If k == nil, return the entire partition (no trickery here, it's a direct reference to the internal table)
-- TODO: Might be a good idea to provide a mechanism of storing and retrieving defaults, but no reason to write it in yet.
-- NOTE: If a function is passed as a default, it will be fired with no arguments and its return set as default.
-- See classes.viewport for a good use case.
config.Get = function (p, k, default, raw)
	local t = cfg[p]
	if type(k) == 'nil' then return t
	elseif t then
		if (not raw) and type(default) ~= 'nil' and type(t[k]) == 'nil' then
			if type(default) == 'function' then default = default() end
			t[k] = default
		end
		return t[k]
	end
end

-- Straight set of a config value.
config.Set = function (p, k, v)
	local t = cfg[p]
	if t then
		t[k] = v
		return t[k]
	end
end

-- Only set a value if it doesn't already exist (macro for SetConfig)
config.SafeSet = function (p, k, v)
	local t = cfg[p]
	if t and type(t[k]) == 'nil' then
		return config.Set(p,k,v)
	end
end

config.OptSet = function (p, k, v)
	if type(v) == 'nil' then
		return config:Get(p,k)
	else
		return config:Set(p,k,v)
	end
end

return config
