local util = {} 

-- global lookups 
local type,assert = type,assert 
local setmetatable, getmetatable  = setmetatable, getmetatable 

local types = {"table","function","number","boolean","nil","userdata"}
while #types > 0 do types[types[1]] = table.remove(types,1); end

-- Enhanced type example: type({},"string","table") == "table", 2
-- Useful for switch statements or basic arg checking (use util.argcheck for a strict approach)
local otype = type
util.type = function (value, ...)
   local n = select("#", ...)
   if n == 0 then return otype(value); end
	 for i=1,n do
      if otype(value) == select(i, ...) then return (otype(value),i); end 
   end
end

util.typematch = function (value, ...)
	local n = select("#",...)
	if n > 0 then for i=1,n do
    if otype(value) == type(select(i, ...)) then return otype(value),i; end 
  end end
  return (otype(value) == "nil")
end

util.concat = function (...) 
   return table.concat({...},'') 
end

util.gethash = function (data) 
   local writer = MOAIHashWriter.new() 
   writer:openMD5() 
   writer:write( data ) 
   writer:close() 
   return writer:getHashHex() 
end 

util.typecheck = function (var, varType, default) 
   if type(var) == varType then 
      return var 
   end 
   return default 
end 

-- Much better. 
util.argcheck = function (value, num, ...) 
   assert(type(num) == 'number', "Bad argument #2 to 'argcheck' (number expected, got "..type(num)..")") 

   for i=1,select("#", ...) do 
      if type(value) == select(i, ...) then return end 
   end 

   local types = table.concat({...}, ", ") 
   local name = string.match(debug.traceback(2,2,0), ": in function [`<](.-)['>]") 
   error(("Bad argument #%d to '%s' (%s expected, got %s"):format(num, name, types, type(value)), 3) 
end

local t = {}

-- Note: Timid flags imply that existing keys won't be clobbered. 
-- Shallow copy. Keeps subtables as pointers, so changes will propagate. More memory efficient than clone, but prone to error. 
t.copy = function (src,dest,timid) 
   dest = type(dest) == "table" and dest or {} 
   for k,v in pairs(src) do 
      dest[k] = (timid and dest[k] ~= nil and dest[k]) or v 
   end 
   return dest 
end 

-- Deep copy. Functions and userdata are kept as pointers, but that's about it. Eats memory if abused.
-- Infinite recursion is avoided by an encounter table - if recursion is detected it just adds a reference.
-- Note: Shallow implies that tables are skipped completely (mostly for the sake of metatable sanity) 
t.clone = function (src,dest,timid,shallow,enc) 
	enc = enc or {[tostring(_ENV or _G)] = (_ENV or _G)} -- recurse check
	dest = type(dest) == "table" and dest or {} 
	for k,v in pairs(src) do 
		if type(v) == "table" and not shallow then
			local e = tostring(v)
			enc[e] = enc[e] or t.clone(v, dest[k], timid, nil, enc)
			dest[k] = (timid and type(dest[k]) ~= "nil" and dest[k]) or enc[e]
		else
			dest[k] = (timid and type(dest[k]) ~= "nil" and dest[k]) or v 
		end 
	end 
	return dest 
end

t.combine = function (src,dest) 
	local dest = type(dest) == "table" and dest or {}
	t.clone(src,dest)
	local mt = (getmetatable(src) or {}).__index or {}
	t.clone(mt,dest,true)
	return dest
end 

-- Combine multiple tables into a single metaindex. Returns a setmetatable()-ready table with index.
-- Usage: setmetatable(target,t.shadow(t1,t2,...)) == setmetatable(target,{__index = {t1 .. t2 .. ...}})
-- Precedence is by arg order, so place your preferred values earlier in the arg stack.
t.shadow = function (...)
	local src = {...}
	local dmt = {}
	local dest = {}
	local enc = {[tostring(_ENV or _G)] = (_ENV or _G)} -- keep memory usage down a bit by preserving the encounter table for clone()
	
	while src[1] do
		local t = table.remove(src)
		local mt = getmetatable(t)
		if mt and mt.__index then
			table.clone(mt.__index,dmt)
		end
		table.clone(t,dest,nil,nil,enc)
	end
	local final = table.clone(dest,dmt)
	return {__index = final}
end

-- Sorted pairs - less efficient than pairs, but consistent results. Usage is identical to pairs (though iteration is numeric)
-- Allows passing a custom sorting function (arg 2) for use as a priority iterator, reverse alpha, etc.
t.spairs = function (t,f)
	local r = {}
	for key in pairs(t) do r[#r + 1] = key; end
	r = table.sort(r,f)
	
	local i = 0
	return function ()
		i = i + 1
		return r[i], t[r[i]]
	end
end

local tprint = function (k,v,tab)
	return print(string.rep("  ",tab) .. tostring(k) .. " = " .. tostring(v))
end

-- sorted and indented print macro
t.print = function (t,tab,enc)
	util.argcheck(t,1,"table")
	util.argcheck(tab,2,"number","nil")
	util.argcheck(enc,3,"table","nil")
	tab = tab or 0
	enc = enc or {}
	for k,v in t.spairs(t)
		if type(v) == "table" then
			local e = tostring(v)
			if enc[e] then
				tprint(k, e .. " (previously printed)", tab)
			else
				tprint(k .. " (" .. e .. ")", "{", tab)
				t.print(v,tab + 1)
				print(string.rep("  ",tab) .. "} --" .. e)
			end
			enc[e] = enc[e] or v
		else
			tprint(k,v,tab)
		end
	end
	local mt = getmetatable(t)
	if mt then
		tprint("metatable " .. tostring(mt), "{", tab)
		t.print(mt,tab + 1)
		print(string.rep("  ",tab) .. "} --metatable " .. tostring(mt))
	end
end

-- Compatibility issue.
t.concat = table.concat or concat

local s = {}
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
s.escape = function(s)
	return (string.gsub(s, ".", escapes))
end

-- split string by delimiter
s.explode = function (s,sep)
	local t = {}
	for w in string.gmatch(s,sep) do
		t[#t + 1] = w
	end
	return table.unpack(t)
end

s.totype = function (s)
	if tonumber(s) then return tonumber(s)
	if s == "true" then return true
	if s == "false" then return false
	else return s
	end
end

util.table = t
util.string = s

util.Init = function (self)
	self.Init = function (self) return self end
	local mt = getmetatable(_ENV or _G)
	if mt and (mt.__index and mt.__index.table) then return self end
	for k,v in pairs(self) do
		if type(v) == "table" and (_ENV or _G)[k] then
			setmetatable((_ENV or _G)[k], self.table.shadow(v))
		end
	end
	setmetatable(_ENV or _G, self.table.shadow(self))
	return self
end 

return util 
