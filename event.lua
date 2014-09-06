if EventManager then return EventManager end

--[[ The event manager is a fairly simple beast designed for use within an OO system.

	Example:
	obj = class('foo'); obj.TEST_EVENT = function (...) print(...) end
	EventManager:Register(obj,'TEST_EVENT'); EventManager:Fire(nil,'TEST_EVENT') --> table:0x1337	TEST_EVENT
	EventManager:Disable(obj); EventManager:Fire(nil,'TEST_EVENT') --> nothing (obj is disabled from receiving all events)
	EventManager:Enable(obj); EventManager:Fire(nil,'TEST_EVENT',true) --> table:0x1337 TEST_EVENT	true
	EventManager:Unregister(obj,'TEST_EVENT'); EventManager:Fire(nil,'TEST_EVENT') --> nothing
	EventManager:Enable(obj); EventManager:Fire(nil,'TEST_EVENT') --> nothing (obj is completely removed from the TEST_EVENT table)

	EventManager:Register/:Unregister will take pretty much anything you pass to them. An event 'name' may be of any type that Lua can hit with tostring, though the conventional use would be to just use strings. Arguments passed to :Fire can be anything you like and aren't touched at all.
	Event propagation is in whatever order pairs picks. DO NOT count on a specific propagation order.
--]]

local mt = {
	events = {},
	disabled = {},
	restricted = {},
	__metatable = true, -- hide the metatable from prying code
}
local em = {}
setmetatable(em,mt)

local pairs,ipairs,select,type,tostring = pairs,ipairs,select,type,tostring
local unpack = unpack or table.unpack -- 5.1/5.2 compatibility issue

-- Not really a huge memory hit if we don't use weak tables here (we only store references to existing objects), but no real reason not to.
local weakmt = {__mode = 'k'}
local weak = function () return setmetatable({},weakmt) end

-- :Fire ignores events without registration tables. Removing empty tables saves us a few cycles when unpopular events are fired.
local empty = function (self,event)
	if type(mt.events[event]) == 'table' then
		for k,v in pairs(mt.events[event]) do
			if v then return end
		end
		mt.events[event] = nil
	end
end

-- Propagate event with arg list to all registered entities
em.Fire = function (self, caller, event, ...)
	local e = tostring(event)
	if mt.restricted[event] and mt.restricted[event] ~= caller then return end
	if mt.events[e] then
		for _,entity in pairs(mt.events[e]) do
			if not(mt.disabled[entity]) then
				local f = entity[event]
				if f then f(entity, event, ...) end
			end
		end
	end
end

-- Add an object to an event's propagation list (ref[event](ref,event,...) will be fired when an event occurs)
em.Register = function (self, ref, ...)
	for i = 1, select('#',...) do
		local event = select(i,...)
		if type(event) == 'table' then
			self:Register(ref, unpack(event))
		else
			mt.events[event] = mt.events[event] or weak()
			mt.events[event][ref] = ref
		end
	end
end

-- Remove an object from an event's propagation list
em.Unregister = function (self, ref, ...)
	for i = 1, select('#',...) do
		local event = select(i,...)
		if type(event) == 'table' then
			self:Unregister(ref, unpack(event))
		elseif mt.events[event] then
			mt.events[event][ref] = nil
			empty(self,event)
		end
	end
end

-- Restricting an event sets a reference that must be passed to :Fire in order for the event to propagate.
-- The best use for this is by creating an empty local table and using that as a key, as such:
-- local eventKey = {}; EventManager:Restrict('RESTRICTED_EVENT', eventKey)
-- EventManager:Fire(nil, 'RESTRICTED_EVENT') --> does nothing
-- EventManager:Fire(eventKey, 'RESTRICTED_EVENT') --> fires RESTRICTED_EVENT
em.Restrict = function (self, event, ref)
	if restricted[event] then return end
	restricted[event] = ref
	return true
end

em.Unrestrict = function (self, event, ref)
	if restricted[event] ~= ref then return end
	restricted[event] = nil
	return true
end

-- Disabling an object removes it from event propagation, effectively unregistering it from all events.
-- One excellent way to use this would be within a prop cache, disabling props from receiving events while they are inactive.
em.Disable = function (self, ref)
	mt.disabled[ref] = true
end

em.Enable = function (self, ref)
	mt.disabled[ref] = nil
end

EventManager = em
return em
