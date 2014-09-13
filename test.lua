class = require"lash"

tp = function (t) print(t); for k,v in pairs(t) do print(k,v) end; print(" ") end

f = {"t1","t2","t3"}
test = function (t)
	for i,v in ipairs(f) do
		local x = t[v]
		if x then x(t) else print(t,v,false) end
	end
end

c1 = class("test 1")
c1.t1 = function (self) print(self,"c1.t1") end
c1.t2 = function (self) print(self,"c1.t2") end

c2 = class("test 2")
c2.t2 = function (self) print(self,"c2.t2") end
c2.t3 = function (self) print(self,"c2.t3") end

c3 = class("test 3")
c3.t1 = function (self) print(self,"c3.t1") end
c3.t3 = function (self) print(self,"c3.t3") end

c1c = c1()
c1s = class("c1s",c1)
c1sc = c1s()

print(rawget(c1,"include"))
print(rawget(c1,"subclass"))

c2s = c1s:subclass("c2s")
c2sc = c2s()

c12 = class("c12"):include(c1,c2,c3)
c12c = c12()

codd = class("oddball", c1)
codd.t2 = function (self) print(self,"oddball") end
coddc = codd()

c64 = class("c64", c12, codd)()

print("c1"); test(c1); test(c1c)
print("c1s"); test(c1s); test(c1sc)
print("c2s"); test(c2s); test(c2sc)
print("c12"); test(c12); test(c12c)
print("c64"); test(c64)