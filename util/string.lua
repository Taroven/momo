local m = {}

local unpack = unpack or table.unpack

local escapes = {
	["^"] = "%^",
	["$"] = "%$",
	["("] = "%(",
	[")"] = "%)",
	["%"] = "%%",
	["."] = "%.",
	["["] = "%[",
	["]"] = "%]",
	["*"] = "%*",
	["+"] = "%+",
	["-"] = "%-",
	["?"] = "%?",
	["\0"] = "%z",
}

function m.escape (s)
	return (string.gsub(s, ".", escapes))
end

-- util.string.pack: Split string by pattern and return a table of segments.
-- Default pattern is %s+, which should pack a string into words.
function m.pack (s, pattern)
	local t = {}
	pattern = pattern or "%s+"
	for w in string.gmatch(s, pattern) do
		t[#t + 1] = w
	end
	return t
end

-- util.string.explode: Macro for util.string.pack + unpack.
function m.explode (s, pattern)
	local t = m.pack(s, pattern)
	return unpack(t)
end

-- Macro for quick MD5 hashing (Probably the only Moai-specific method in the utils...)
function m.hash (data)
   local writer = MOAIHashWriter.new()
   writer:openMD5()
   writer:write(data)
   writer:close()
   return writer:getHashHex()
end

return m