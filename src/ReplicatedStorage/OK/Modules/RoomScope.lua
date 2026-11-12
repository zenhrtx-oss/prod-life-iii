-- OK Studio RoomScope: the one definition of "inside a room", and the hub-scoped counts the place checks take.
-- A room is a Model with a non-nil OK_Room attribute (the bedroom's value is "bedroom_starter"; clones keep it; a future
-- room type reuses the attribute with its own value). Everything not inside one is the hub. The hub keeps its own numbers
-- (at most 61 lights, 12 tagged interactables, 2 stations); each room may hold at most MaxLightsPerRoom lights (the
-- user's call, 2026-11-11: one warm bulb per room, not an unbounded light budget). Used by t03, t04, t05, t07, 09_qa and
-- 14_stations; build/t88_check.lua proves the scoping on real instances and spec/room_scope_spec.lua on stand-ins.
-- Pure: no Roblox globals, no require and no yielding. It reads instances only through Parent, IsA, GetAttribute,
-- GetDescendants and GetFullName, so the luau CLI spec can pass plain tables.
local M = {}

M.Attribute = "OK_Room"
M.MaxLightsPerRoom = 1

-- the nearest ancestor Model carrying OK_Room, or nil when `inst` is in the hub. A room is not inside itself.
function M.RoomOf(inst)
	local a = inst.Parent
	while a do
		if a:IsA("Model") and a:GetAttribute(M.Attribute) ~= nil then return a end
		a = a.Parent
	end
	return nil
end

-- `items` split by room: the hub's items (a new array, order kept) and the rooms' items grouped, one entry
-- { room = Model, items = { ... } } per room that holds any, in the order first seen
function M.Split(items)
	local hub, rooms, byRoom = {}, {}, {}
	for _, inst in ipairs(items) do
		local room = M.RoomOf(inst)
		if room == nil then
			table.insert(hub, inst)
		else
			local entry = byRoom[room]
			if not entry then
				entry = { room = room, items = {} }
				byRoom[room] = entry
				table.insert(rooms, entry)
			end
			table.insert(entry.items, inst)
		end
	end
	return hub, rooms
end

-- nil when every room (an entry from Split) holds at most `max` of `what`; otherwise a line naming each room above it,
-- by full name and OK_Room value: "Workspace.Room_02 (bedroom_starter) holds 2 lights, over its 1"
function M.OverBudget(rooms, what, max)
	local over = {}
	for _, entry in ipairs(rooms) do
		local n = #entry.items
		if n > max then
			table.insert(over, string.format("%s (%s) holds %d %s, over its %d", entry.room:GetFullName(),
				tostring(entry.room:GetAttribute(M.Attribute)), n, what, max))
		end
	end
	if #over == 0 then return nil end
	return table.concat(over, "; ")
end

-- every Light under `root`: the hub's count (what the 61 cap is held against), the rooms that hold lights, and the
-- OverBudget line for rooms above MaxLightsPerRoom (nil when none is)
function M.Lights(root)
	local lights = {}
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("Light") then table.insert(lights, d) end
	end
	local hub, rooms = M.Split(lights)
	return #hub, rooms, M.OverBudget(rooms, "lights", M.MaxLightsPerRoom)
end

return M
