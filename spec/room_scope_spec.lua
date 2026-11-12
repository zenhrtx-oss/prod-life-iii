-- CLI spec for Modules/RoomScope (Wave 3 Task 5c-3): what counts as "inside a room", and the hub-scoped counts the place
-- checks (t03, t04, t05, t07, 09_qa, 14_stations) take. A room is a Model carrying a non-nil OK_Room attribute; the
-- module reads instances only through Parent, IsA, GetAttribute, GetDescendants and GetFullName, so plain tables with
-- those members stand in for the tree here. The Edit check build/t88_check.lua proves the same scoping on real instances.
-- Run: sh tools/spec.sh room_scope
local RoomScope = require("../src/ReplicatedStorage/OK/Modules/RoomScope")

local fails = {}
local function ok(name, cond) if not cond then table.insert(fails, name) end end
local function eq(name, got, want)
	if got ~= want then table.insert(fails, string.format("%s: expected %s, got %s", name, tostring(want), tostring(got))) end
end
local function plain(s, sub) return type(s) == "string" and string.find(s, sub, 1, true) ~= nil end

-- a stand-in for the bit of Instance the module reads. Real Roblox: PointLight/SpotLight/SurfaceLight are Lights, and
-- Workspace is a Model (WorldRoot -> Model), so a walk that climbs through the workspace meets a Model there too.
local LIGHTS = { PointLight = true, SpotLight = true, SurfaceLight = true }
local function new(class, name, parent, attrs)
	local n = { ClassName = class, Name = name, Parent = parent, attrs = attrs or {}, kids = {} }
	function n:IsA(c)
		return c == class or c == "Instance" or (c == "Light" and LIGHTS[class] == true)
			or (c == "Model" and class == "Workspace") or (c == "BasePart" and (class == "Part" or class == "MeshPart"))
	end
	function n:GetAttribute(k) return self.attrs[k] end
	function n:GetDescendants()
		local out = {}
		local function walk(x) for _, k in ipairs(x.kids) do table.insert(out, k); walk(k) end end
		walk(self)
		return out
	end
	function n:GetFullName()
		return self.Parent and (self.Parent:GetFullName() .. "." .. name) or name
	end
	if parent then table.insert(parent.kids, n) end
	return n
end
local function room(name, parent, kind) return new("Model", name, parent, { OK_Room = kind or "test_room" }) end
local function detach(n) -- take an instance out of its parent (Destroy, for the stand-ins)
	for i, k in ipairs(n.Parent.kids) do
		if k == n then
			table.remove(n.Parent.kids, i)
			break
		end
	end
	n.Parent = nil
end
local function lightOn(partName, parent, class) -- a part under `parent` with one light; returns the light
	local p = new("Part", partName, parent)
	return new(class or "PointLight", "Light", p)
end

-- the old counting: every Light under the root (what t03, t04, t05 and 09_qa did before 5c-3)
local function oldLightCount(root)
	local n = 0
	for _, d in ipairs(root:GetDescendants()) do if d:IsA("Light") then n += 1 end end
	return n
end

-- constants the checks rely on
eq("Attribute", RoomScope.Attribute, "OK_Room")
eq("MaxLightsPerRoom", RoomScope.MaxLightsPerRoom, 1)

-- RoomOf: the nearest ancestor Model with OK_Room
do
	local ws = new("Workspace", "Workspace", nil)
	local studio = new("Model", "OKStudio", ws)
	local hubLight = lightOn("Lamp", studio)
	eq("RoomOf: a hub light is in no room", RoomScope.RoomOf(hubLight), nil)
	eq("RoomOf: a hub model is in no room", RoomScope.RoomOf(studio), nil)

	local bed = room("Env_bedroom_starter", ws, "bedroom_starter")
	local bulb = lightOn("bd_room__bd_bulb", bed)
	eq("RoomOf: a light under a part of the room", RoomScope.RoomOf(bulb), bed)
	eq("RoomOf: the part itself", RoomScope.RoomOf(bulb.Parent), bed)
	eq("RoomOf: the room is not inside itself", RoomScope.RoomOf(bed), nil)

	-- deep: room > Folder > Model (no attribute) > Part > light
	local folder = new("Folder", "Props", bed)
	local inner = new("Model", "Desk", folder)
	local deep = lightOn("Lamp", inner)
	eq("RoomOf: through a Folder and a plain Model", RoomScope.RoomOf(deep), bed)

	-- nested rooms: the nearest one
	local sub = room("Closet", inner, "closet")
	eq("RoomOf: a room inside a room reports the nearest", RoomScope.RoomOf(lightOn("Bulb", sub)), sub)
	eq("RoomOf: a room inside a room is in the outer room", RoomScope.RoomOf(sub), bed)

	-- only a Model with a non-nil OK_Room is a room
	local tagFolder = new("Folder", "NotARoom", ws, { OK_Room = "oops" })
	eq("RoomOf: a Folder with OK_Room is not a room", RoomScope.RoomOf(lightOn("Lamp", tagFolder)), nil)
	local plainModel = new("Model", "Env_other", ws)
	eq("RoomOf: a Model without OK_Room is not a room", RoomScope.RoomOf(lightOn("Lamp", plainModel)), nil)
	local named = new("Model", "Env_bedroom_starter_lookalike", ws, { Other = "x" })
	eq("RoomOf: a Model with other attributes only is not a room", RoomScope.RoomOf(lightOn("Lamp", named)), nil)
	local second = room("Room_02", ws, "bedroom_starter")
	eq("RoomOf: a clone with the attribute is a room", RoomScope.RoomOf(lightOn("bd_room__bd_bulb", second)), second)

	-- a detached item is nobody's room
	eq("RoomOf: no parent", RoomScope.RoomOf(new("Part", "Loose", nil)), nil)
end

-- Split: the hub's items in order, and the rooms' items grouped in first-seen order
do
	local ws = new("Workspace", "Workspace", nil)
	local studio = new("Model", "OKStudio", ws)
	local a = room("Room_A", ws, "bedroom_starter")
	local b = room("Room_B", ws, "bedroom_starter")
	local h1, h2 = lightOn("Hub1", studio), lightOn("Hub2", ws)
	local a1, b1, a2 = lightOn("A1", a), lightOn("B1", b), lightOn("A2", a)
	local hub, rooms = RoomScope.Split({ a1, h1, b1, h2, a2 })
	eq("Split: hub size", #hub, 2)
	eq("Split: hub keeps the order (1)", hub[1], h1)
	eq("Split: hub keeps the order (2)", hub[2], h2)
	eq("Split: two rooms", #rooms, 2)
	eq("Split: first-seen room first", rooms[1] and rooms[1].room, a)
	eq("Split: second room", rooms[2] and rooms[2].room, b)
	eq("Split: room A's items", rooms[1] and #rooms[1].items, 2)
	ok("Split: room A's items in order", rooms[1] and rooms[1].items[1] == a1 and rooms[1].items[2] == a2)
	eq("Split: room B's items", rooms[2] and #rooms[2].items, 1)
	ok("Split: room B's item", rooms[2] and rooms[2].items[1] == b1)
	local h0, r0 = RoomScope.Split({})
	eq("Split: nothing in, empty hub", #h0, 0)
	eq("Split: nothing in, no rooms", #r0, 0)
	local hOnly, rOnly = RoomScope.Split({ h1, h2 })
	eq("Split: hub only", #hOnly, 2)
	eq("Split: hub only, no rooms", #rOnly, 0)
end

-- OverBudget: names every room above its budget (full name and OK_Room value), nil when none is
do
	local ws = new("Workspace", "Workspace", nil)
	local a = room("Room_01", ws, "bedroom_starter")
	local b = room("Room_02", ws, "bedroom_starter")
	local c = room("Env_other", ws, "other_type")
	local function entries(counts) -- { { room, n }, ... } -> the shape Split gives
		local rooms = {}
		for _, rn in ipairs(counts) do
			local items = {}
			for i = 1, rn[2] do items[i] = { n = i } end
			table.insert(rooms, { room = rn[1], items = items })
		end
		return rooms
	end
	eq("OverBudget: at the limit is fine", RoomScope.OverBudget(entries({ { a, 1 }, { b, 1 } }), "lights", 1), nil)
	eq("OverBudget: no rooms", RoomScope.OverBudget({}, "lights", 1), nil)
	local msg = RoomScope.OverBudget(entries({ { a, 1 }, { b, 2 } }), "lights", 1)
	ok("OverBudget: names the room that is over", plain(msg, "Workspace.Room_02"))
	ok("OverBudget: not the one that isn't", not plain(msg, "Workspace.Room_01"))
	ok("OverBudget: its OK_Room value", plain(msg, "bedroom_starter"))
	ok("OverBudget: what it holds", plain(msg, "2 lights"))
	ok("OverBudget: its budget", plain(msg, "1"))
	local both = RoomScope.OverBudget(entries({ { a, 2 }, { c, 3 } }), "lights", 1)
	ok("OverBudget: both rooms named (1)", plain(both, "Workspace.Room_01"))
	ok("OverBudget: both rooms named (2)", plain(both, "Workspace.Env_other") and plain(both, "other_type"))
	ok("OverBudget: a bigger budget lets 3 through", RoomScope.OverBudget(entries({ { c, 3 } }), "lights", 3) == nil)
end

-- Lights: every Light under a root, the hub's count, the rooms, and the rooms over their budget
do
	local ws = new("Workspace", "Workspace", nil)
	local studio = new("Model", "OKStudio", ws)
	for i = 1, 61 do lightOn("Lamp" .. i, studio) end
	local n0, rooms0, over0 = RoomScope.Lights(ws)
	eq("Lights: the hub's 61", n0, 61)
	eq("Lights: no rooms yet", #rooms0, 0)
	eq("Lights: nothing over", over0, nil)
	eq("Lights control: old counting, no rooms", oldLightCount(ws), 61)

	-- the bedroom arrives: one bulb, one room
	local bed = room("Env_bedroom_starter", ws, "bedroom_starter")
	lightOn("bd_room__bd_bulb", bed)
	local n1, rooms1, over1 = RoomScope.Lights(ws)
	eq("Lights: the hub's count does not move", n1, 61)
	eq("Lights: the room is counted as a room", #rooms1, 1)
	eq("Lights: its room", rooms1[1] and rooms1[1].room, bed)
	eq("Lights: its one light", rooms1[1] and #rooms1[1].items, 1)
	eq("Lights: one bulb is within the room's budget", over1, nil)
	eq("Lights control: the old count now reads 62 and trips the cap of 61", oldLightCount(ws), 62)

	-- a second light in the room is over its budget, named; the hub still does not move
	local lamp = lightOn("Lamp", new("Folder", "Props", bed), "SpotLight")
	local n2, rooms2, over2 = RoomScope.Lights(ws)
	eq("Lights: the hub's count still does not move", n2, 61)
	eq("Lights: the room holds two", rooms2[1] and #rooms2[1].items, 2)
	ok("Lights: the 2nd light is over budget", over2 ~= nil)
	ok("Lights: over budget names the room", plain(over2, "Workspace.Env_bedroom_starter"))
	ok("Lights: and its OK_Room value", plain(over2, "bedroom_starter"))
	detach(lamp.Parent) -- take the 2nd light away again
	eq("Lights: back to one, back within budget", select(3, RoomScope.Lights(ws)), nil)

	-- a light outside any room still counts against the hub's 61
	local stray = lightOn("Stray", ws)
	local n3, _, over3 = RoomScope.Lights(ws)
	eq("Lights: a hub light counts (62, over the cap)", n3, 62)
	ok("Lights: a hub light is no room's business", over3 == nil)
	ok("Lights: the check's own comparison would now fail", not (n3 <= 61))
	detach(stray.Parent)

	-- a light inside a non-Model with OK_Room still counts for the hub
	local tagFolder = new("Folder", "OK_Room_looking", ws, { OK_Room = "x" })
	lightOn("Lamp", tagFolder)
	eq("Lights: a Folder is not a room", (RoomScope.Lights(ws)), 62)

	-- SurfaceLight and SpotLight are Lights too; a room with only those still holds one each
	local sub = room("Room_03", ws, "bedroom_starter")
	lightOn("S", sub, "SurfaceLight")
	local _, rooms4, over4 = RoomScope.Lights(ws)
	eq("Lights: a SurfaceLight in a room is that room's light", rooms4[#rooms4] and rooms4[#rooms4].room, sub)
	eq("Lights: and within budget", over4, nil)

	-- twelve rooms, the phone test: each holds its one bulb
	local test = new("Model", "RoomTest", ws)
	local rms = new("Folder", "Rooms", test)
	for i = 1, 12 do lightOn("bd_room__bd_bulb", room(string.format("Room_%02d", i), rms, "bedroom_starter")) end
	local n5, rooms5, over5 = RoomScope.Lights(ws)
	eq("Lights: the 12 test rooms leave the hub's count alone", n5, 62)
	eq("Lights: the bedroom, Room_03 and the 12 test rooms are rooms", #rooms5, 14)
	eq("Lights: all within budget", over5, nil)
	eq("Lights control: the old count would have added 14", oldLightCount(ws), 62 + 14)
	-- one test room gets a second light: it is named
	lightOn("Extra", rms.kids[5])
	local _, _, over6 = RoomScope.Lights(ws)
	ok("Lights: Room_05's second light is named", plain(over6, "Workspace.RoomTest.Rooms.Room_05"))
end

if #fails > 0 then error(#fails .. " room_scope case(s) failed: " .. table.concat(fails, "; ")) end
print("SPEC OK: room_scope")
