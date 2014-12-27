local t = {}

-- Note: Timid flags imply that existing keys won't be clobbered.
-- Shallow copy. Keeps subtables as pointers, so changes will propagate. More memory efficient than clone, but prone to error.
function t.copy (src, dest, timid)
   dest = type(dest) == "table" and dest or {}
   for k,v in pairs(src) do
      dest[k] = (timid and dest[k] ~= nil and dest[k]) or v
   end
   return dest
end

-- Deep copy. Functions and userdata are kept as pointers, but that's about it. Eats memory if abused.
-- Infinite recursion is avoided by an encounter table - if recursion is detected it just adds a reference.
-- Note: Shallow implies that tables are skipped completely (mostly for the sake of metatable sanity)
function t.clone (src, dest, timid, shallow, enc)
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

-- Combine multiple tables into a single metaindex. Returns a setmetatable()-ready table with index.
-- Usage: setmetatable(target,t.shadow(t1,t2,...)) == setmetatable(target,{__index = {t1 .. t2 .. ...}})
-- Precedence is by arg order, so place your preferred values earlier in the arg stack.
function t.shadow (...)
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
function t.spairs (t,f)
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
function t.print (t,tab,enc)
	if util then
		util.argcheck(t,1,"table")
		util.argcheck(tab,2,"number","nil")
		util.argcheck(enc,3,"table","nil")
	end
	tab = tab or 0
	enc = enc or {}
	for k,v in t.spairs(t) do
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

return t