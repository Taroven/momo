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
	if util and util.debug then
		argcheck(t,1,"table")
		argcheck(tab,2,"number","nil")
		argcheck(enc,3,"table","nil")
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
table.concat = table.concat or concat

return t