-- Server, during play (the Your Rooms plan, Task 9: placing your things, server side), through the Studio hooks. The rooms
-- hook's Edit(action) and State are the remotes' own handlers (Room_Edit and Room_Get run the same functions, so the
-- token bucket, the checks and the saves are exactly the live path; t109b presses the remotes for real). The body runs held
-- (WalkInsPaused true) from the file's fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life reset,
-- no hint seen, the rooms hook's Reset (a slot claimed, the plot rebuilt); then the profile is marked (ProfileMark) and the
-- gear dropped, so nothing the player owns changes what is locked. Edits are paced one every Config.Rooms.Edit.every + 0.03 s
-- (a token comes back each `every`), except where a step tests the bucket. A cell is found from the live grid and keep
-- areas with RoomRules.Fits itself (State's grid, keep, items and unlocked), never hard-coded, and r is quarter turns 0..3.
-- (0) the catalog builds: RoomItems.Build(id, Data/RoomCatalog) for every id gives a Model (attribute ItemId, a pivot at the
--     origin) of exactly the recipe's parts (<= Config.Rooms.ItemParts), every part anchored, no collide, no touch, CanQuery,
--     no shadow under RoomItems.SMALL, no light, mesh or script; an unknown id gives nil.
-- (1) WakeUp: State answers { rooms = { bedroom = { limit, used 0, items {}, grid, keep, slots 0 } } (no home or real),
--     unlocked (the rug and plant, not tape_machine or floor_lamp), door, inside = "bedroom" }; each room holds an empty
--     Items folder.
-- (2) place a rug at a free cell: ok, index 1; one Item_1 model in Room_bedroom.Items (ItemId rug, Index 1, its pivot at
--     RoomRules.Centre of its footprint, parts inside the footprint, non-colliding); Home and the profile's career.home hold
--     { id rug, x, z, r 0 }; State shows used 1.
-- (3) move it to another cell: still one model, the old one destroyed, the new one at the new cell; a plant then placed stays
--     the very same model through a later move of the rug (only what changed is rebuilt); a rotation in place of the 2x2 rug
--     (same cell, r 1: it overlaps only itself) is allowed.
-- (4) a rotation with an odd footprint: kit_tape (GrantGear) opens the tape machine (2 x 1). At r 0 a plant on its second
--     cell is refused "overlap" and one beside it is free; moved to the same cell at r 1 the footprint is 1 x 2: the plant that
--     was free is now "overlap" and the cell it covered is open, the model's parts lie inside the new 1 x 2 footprint and its
--     front faces -X.
-- (5) refusals, each leaving Home and the models as they were: overlap, bounds (far off the grid), unknown id, locked
--     (floor_lamp), a closet and a poster in the bedroom ("room"), a bad turn (5, 1.5, -1: "rot"), a room you don't own
--     (home, attic: "room"), a stale move or remove index ("unknown"), and junk ("invalid": not a table, an unknown op, a
--     string or missing coordinate, a number id or kind, a fractional or missing index). The 7th item is "limit" (6 in the
--     bedroom) and the room's Items hold no more than limit x ItemParts parts.
-- (6) remove: the item is gone and saved; the other models are the same instances, renumbered; removing the last drops the
--     list from the saved home (Home items has no bedroom key) and the Items folder is empty.
-- (7) the token bucket: Config.Rooms.Edit.burst refusals (remove index 99 -> "unknown": a refusal costs a token) are answered
--     "unknown" and the rest of 8 back-to-back calls (well under one `every`: nothing in Edit yields on a loaded profile) answer "busy", changing nothing; one `every` later a call goes through.
-- (8) SetHome with junk (an unknown id, a string coordinate, an overlap, a far-off cell, a closet in the bedroom, a bad turn,
--     non-tables, an unknown kind) returns what it kept; the plot's Items are rebuilt from it (only the kept two, the earlier
--     models gone) and Home answers the same.
-- (9) your plot only: Edit from the hub -> "away" (State.inside nil); from another player's landing (Fill(1), Enter(2) as a
--     friend) -> "owner"; from your own landing -> goes through (and a room you own is edited from anywhere in your plot).
-- (10) a gear item saved while its gear is not owned (SetHome with a tape machine, after ResetGear) is kept and unbuilt (State
--     items 1, used 0, no model); GrantGear stands it within 3 s, ResetGear takes it down again.
-- (11) the home studio: bought for real (Career Set at the gate's needs and its price, Unlock home_studio); a closet placed
--     in home from the bedroom (a room you own is edited from anywhere in your plot) is ok and a second is "max"; a keyboard
--     stand (open once you own home) goes in; State's home row reads limit 16 and slots 4; every room's Items hold at most
--     limit x ItemParts parts.
-- (12) a Release and Claim (a rejoin) rebuilds the same items in the same cells in both rooms (Home, every model's id and
--     pivot).
-- On any error, and after success: unseated in the lounge, Unfill, the career Reset (the plot back to the bedroom), everything
-- else reset (hold on, Quiet off; this resets the career again, which wipes the home), then the rooms Reset and the noted home
-- put back, then the profile as ProfileMark noted it (the gate's money, the gear) and the career hook's Publish; the error is
-- rethrown.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local rooms = SOK:WaitForChild("_StudioRoomsHook", 5); assert(rooms, "no _StudioRoomsHook (is Systems/Rooms synced and started?)")
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.RoomRules)
local Catalog = require(RS.OK.Data.RoomCatalog)
local Items = require(RS.OK.Modules.RoomItems)
local Cfg = Config.Rooms
local LOUNGE = Vector3.new(24, 3, 0)
local STATS = { "aura", "followers", "placements", "hits", "sponsors" }
local RED = " (before the R-T9 sync of Modules/RoomItems, Modules/RoomEdit and Systems/Rooms: the expected red)"
local EVERY = Cfg.Edit.every
local out = {}
local T0 = os.clock()
local homeBefore -- the saved home as the file found it, put back at the end
local lastEdit = 0

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function str(v) return typeof(v) == "Vector3" and string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) or tostring(v) end
local function teleport(pos) -- the test's own move; checked, and tried once more if the client's position won
	for _ = 1, 2 do
		local c = p.Character or p.CharacterAdded:Wait()
		c:WaitForChild("HumanoidRootPart", 5)
		c:PivotTo(CFrame.new(pos))
		task.wait(0.3)
		local r = root()
		if r and flat(r.Position - pos) < 2 then return r end
	end
	error("teleport to " .. tostring(pos) .. " did not take")
end
local function unseat()
	local h = hum()
	if h and (h.Sit or h.SeatPart) then h.Sit = false; task.wait(0.4) end
end
local function call(cmd, a, b) return rooms:Invoke(cmd, uid, a, b) end
local function show(v) local okJ, js = pcall(function() return game:GetService("HttpService"):JSONEncode(v) end); return okJ and js or tostring(v) end
-- a table as text, keys sorted, so two equal tables read the same
local function canon(v)
	if type(v) ~= "table" then return tostring(v) end
	local keys = {}
	for k in pairs(v) do table.insert(keys, k) end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	local parts = {}
	for _, k in ipairs(keys) do table.insert(parts, tostring(k) .. "=" .. canon(v[k])) end
	return "{" .. table.concat(parts, ",") .. "}"
end
local function placeIs(want, label)
	local pl = call("PlaceOf")
	local got = type(pl) == "table" and (tostring(pl.slot) .. "/" .. tostring(pl.kind)) or tostring(pl)
	assert(got == want, label .. ": PlaceOf is " .. got .. ", want " .. want)
end
local function arrivePlace(want, label)
	local ok = waitFor(function()
		local pl = call("PlaceOf")
		return type(pl) == "table" and (tostring(pl.slot) .. "/" .. tostring(pl.kind)) == want
	end, 4)
	if not ok then placeIs(want, label) end
end

-- the plot, its rooms and their item models
local function plotModel()
	local info = call("Plot")
	local f = workspace:FindFirstChild("OK_Plots")
	return info and f and f:FindFirstChild(string.format("Plot_%02d", info.slot)) or nil
end
local function roomKinds() local i = call("Plot"); return type(i) == "table" and table.concat(i.rooms, ",") or tostring(i) end
local function roomOf(kind) local m = plotModel(); return m and m:FindFirstChild("Room_" .. kind) end
local function itemsOf(kind) local r = roomOf(kind); return r and r:FindFirstChild("Items") end
local function modelsOf(kind) -- the item Models in Index order
	local f = itemsOf(kind)
	assert(f and f:IsA("Folder"), "Room_" .. kind .. " has no Items Folder" .. RED)
	local list = {}
	for _, c in ipairs(f:GetChildren()) do if c:IsA("Model") then table.insert(list, c) end end
	table.sort(list, function(a, b) return (a:GetAttribute("Index") or 0) < (b:GetAttribute("Index") or 0) end)
	return list
end
local function partCount(kind)
	local n = 0
	for _, d in ipairs(itemsOf(kind):GetDescendants()) do if d:IsA("BasePart") then n += 1 end end
	return n
end
local function worldSig(kinds)
	local list = {}
	for _, kind in ipairs(kinds) do
		for _, m in ipairs(modelsOf(kind)) do
			local pv = m:GetPivot()
			table.insert(list, string.format("%s/%s@%.2f,%.2f,%.2f,%.2f,%.2f", kind, tostring(m:GetAttribute("ItemId")), pv.X, pv.Y, pv.Z, pv.LookVector.X, pv.LookVector.Z))
		end
	end
	table.sort(list)
	return table.concat(list, ";")
end
local function snap(kinds) return canon(call("Home")) .. " | " .. worldSig(kinds or { "bedroom" }) end

-- the edit bar's State, and RoomRules.Fits against it: free cells from the live grid
local function state()
	local s = call("State")
	assert(type(s) == "table" and type(s.rooms) == "table" and type(s.unlocked) == "table", "the rooms hook's State answered " .. show(s) .. ", want { rooms, unlocked, door, inside }" .. RED)
	return s
end
local function scan(kind, id, r) -- every lowest cell { cx, cz } where `id` (turned r) fits the room now
	local s = state()
	local set = {}
	for _, u in ipairs(s.unlocked) do set[u] = true end
	local rm = s.rooms[kind]
	assert(rm, "State has no room " .. kind)
	local kc = Cfg.Kinds[kind]
	local found, seen = {}, {}
	for _, a in ipairs(kc.grid) do
		for cx = math.floor(math.min(a[1], a[3])), math.ceil(math.max(a[1], a[3])) do
			for cz = math.floor(math.min(a[2], a[4])), math.ceil(math.max(a[2], a[4])) do
				local key = cx .. ":" .. cz
				if not seen[key] then
					seen[key] = true
					if Rules.Fits(rm.items, { id = id, x = cx, z = cz, r = r or 0 }, kc, Catalog, set, kind, nil, Cfg) then table.insert(found, { cx, cz }) end
				end
			end
		end
	end
	return found
end
-- an edit through the remote's own handler, paced so the bucket never runs dry
local function edit(action)
	local gap = EVERY + 0.03 - (os.clock() - lastEdit)
	if gap > 0 then task.wait(gap) end
	lastEdit = os.clock()
	return call("Edit", action)
end
local function ok(res, label)
	assert(type(res) == "table" and res.ok == true, label .. ": Edit answered " .. show(res) .. ", want ok" .. RED)
	return res
end
-- an edit that must be refused with `reason` and change nothing
local function refused(action, reason, label, kinds)
	local before = snap(kinds)
	local res = edit(action)
	assert(type(res) == "table" and res.ok == false and res.reason == reason, label .. ": Edit answered " .. show(res) .. ", want refused '" .. reason .. "'" .. RED)
	local after = snap(kinds)
	assert(after == before, label .. ": a refused edit changed things:\n  before " .. before .. "\n  after  " .. after)
end

-- one item model, as the saved entry says
local function worldBox(m)
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			local h = d.Size / 2
			for _, sx in ipairs({ -1, 1 }) do
				for _, sy in ipairs({ -1, 1 }) do
					for _, sz in ipairs({ -1, 1 }) do
						local c = d.CFrame:PointToWorldSpace(Vector3.new(h.X * sx, h.Y * sy, h.Z * sz))
						lo = Vector3.new(math.min(lo.X, c.X), math.min(lo.Y, c.Y), math.min(lo.Z, c.Z))
						hi = Vector3.new(math.max(hi.X, c.X), math.max(hi.Y, c.Y), math.max(hi.Z, c.Z))
					end
				end
			end
		end
	end
	return lo, hi
end
local function checkParts(m, id, label)
	local item = Catalog.ById[id]
	local n = 0
	for _, d in ipairs(m:GetDescendants()) do
		assert(not d:IsA("Light") and not d:IsA("MeshPart") and not d:IsA("BaseScript") and not d:IsA("Sound"), label .. ": " .. d:GetFullName() .. " is a " .. d.ClassName)
		if d:IsA("BasePart") then
			n += 1
			assert(d.Anchored and not d.CanCollide and not d.CanTouch and d.CanQuery, string.format("%s: %s Anchored %s, CanCollide %s, CanTouch %s, CanQuery %s; want anchored, no collide, no touch, queryable",
				label, d:GetFullName(), tostring(d.Anchored), tostring(d.CanCollide), tostring(d.CanTouch), tostring(d.CanQuery)))
			local big = math.max(d.Size.X, d.Size.Y, d.Size.Z) >= Items.SMALL
			assert(d.CastShadow == big, label .. ": " .. d:GetFullName() .. " CastShadow " .. tostring(d.CastShadow) .. ", want " .. tostring(big) .. " (a part under " .. Items.SMALL .. " studs casts none)")
		end
	end
	assert(n == #item.parts and n <= Cfg.ItemParts, label .. ": " .. id .. " has " .. n .. " parts, want the recipe's " .. #item.parts .. " (at most " .. Cfg.ItemParts .. ")")
end
local function checkModel(m, kind, entry, index, label)
	local item = Catalog.ById[entry.id]
	assert(m and m:IsA("Model") and m.Parent == itemsOf(kind), label .. ": " .. tostring(m) .. " is not a Model in Room_" .. kind .. ".Items")
	assert(m:GetAttribute("ItemId") == entry.id and m:GetAttribute("Index") == index and m.Name == "Item_" .. index, string.format("%s: model %s ItemId %s Index %s; want %s, %d",
		label, m.Name, tostring(m:GetAttribute("ItemId")), tostring(m:GetAttribute("Index")), entry.id, index))
	local pivot = roomOf(kind):GetPivot()
	local cx, cz = Rules.Centre(item, entry)
	local want = pivot * CFrame.new(cx, 0, cz) * CFrame.Angles(0, (entry.r or 0) * math.pi / 2, 0)
	local pv = m:GetPivot()
	assert((pv.Position - want.Position).Magnitude < 0.02, label .. ": the model's pivot is at " .. str(pv.Position) .. ", want the footprint's centre " .. str(want.Position))
	assert(pv.LookVector:Dot(want.LookVector) > 0.999, label .. ": the model faces " .. str(pv.LookVector) .. ", want " .. str(want.LookVector) .. " (r " .. tostring(entry.r) .. ")")
	checkParts(m, entry.id, label)
	-- the parts lie inside the footprint's cells
	local cells = Rules.Cells(item, entry)
	local lox, loz, hix, hiz = math.huge, math.huge, -math.huge, -math.huge
	for _, c in ipairs(cells) do
		for _, corner in ipairs({ { c[1], c[2] }, { c[1] + 1, c[2] + 1 } }) do
			local w = pivot:PointToWorldSpace(Vector3.new(corner[1], 0, corner[2]))
			lox, loz, hix, hiz = math.min(lox, w.X), math.min(loz, w.Z), math.max(hix, w.X), math.max(hiz, w.Z)
		end
	end
	local lo, hi = worldBox(m)
	local tol = 0.06
	assert(lo.X >= lox - tol and hi.X <= hix + tol and lo.Z >= loz - tol and hi.Z <= hiz + tol, string.format("%s: the parts span x %.2f..%.2f, z %.2f..%.2f, want inside the footprint x %.2f..%.2f, z %.2f..%.2f",
		label, lo.X, hi.X, lo.Z, hi.Z, lox, hix, loz, hiz))
	assert(lo.Y >= pivot.Y - 0.02, label .. ": the item sinks " .. string.format("%.2f", pivot.Y - lo.Y) .. " below the floor")
end
local function savedList(kind) local h = call("Home"); return h and h.items and h.items[kind] end
-- is the cell inside the w x d block of cells whose lowest cell is (bx, bz)?
local function inBlock(c, bx, bz, w, d) return c[1] >= bx and c[1] < bx + w and c[2] >= bz and c[2] < bz + d end
-- every saved entry of the room has its model, in order
local function checkRoom(kind, label)
	local list = savedList(kind) or {}
	local ms = modelsOf(kind)
	assert(#ms == #list, label .. ": Room_" .. kind .. ".Items holds " .. #ms .. " models, the saved list has " .. #list)
	for i, e in ipairs(list) do checkModel(ms[i], kind, e, i, label .. " item " .. i) end
	assert(partCount(kind) <= Cfg.Kinds[kind].limit * Cfg.ItemParts, label .. ": Room_" .. kind .. ".Items hold " .. partCount(kind) .. " parts, want at most " .. Cfg.Kinds[kind].limit * Cfg.ItemParts)
end
local function clearHome(label)
	assert(type(call("SetHome", { v = 1, door = Cfg.DoorDefault, items = {} })) == "table", label .. ": SetHome failed")
	assert(#modelsOf("bedroom") == 0, label .. ": the bedroom's Items are not empty after an empty SetHome")
end

-- the file's own fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life reset, no hint seen,
-- the rooms hook's Reset (slot claimed, plot rebuilt)
local function fresh(label)
	unseat()
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(ph:Invoke("Reset", uid) == true, label .. ": phone Reset failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	assert(call("Reset") == true, label .. ": the rooms hook's Reset failed (no slot, or the plot did not build)")
end
local function gateOf(id) for _, g in ipairs(Config.Career.Gates) do if g.id == id then return g end end end

local function run()
	local mk = test:Invoke("ProfileMark", uid) -- first, before anything changes (the cleanup's ProfileRestore)
	assert(mk == true, "the test hook's ProfileMark answered " .. tostring(mk) .. ", want true")
	homeBefore = call("Home")
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("edit")
	assert(test:Invoke("ResetGear", uid) == true, "ResetGear failed") -- nothing the player owns changes what is locked
	assert(type(Cfg.Edit) == "table" and Cfg.Edit.burst >= 3 and EVERY > 0, "Config.Rooms.Edit should be { burst >= 3, every > 0 }, got " .. show(Cfg.Edit))

	-- 0. the catalog builds
	assert(type(Items.Build) == "function", "RoomItems has no Build" .. RED)
	for _, item in ipairs(Catalog.Items) do
		local m = Items.Build(item.id, Catalog)
		assert(typeof(m) == "Instance" and m:IsA("Model") and m:GetAttribute("ItemId") == item.id, "RoomItems.Build(" .. item.id .. ") is " .. tostring(m) .. ", want a Model with ItemId " .. item.id)
		assert(m.Parent == nil, "RoomItems.Build(" .. item.id .. ") came back parented (" .. tostring(m.Parent) .. "), want a loose Model")
		checkParts(m, item.id, "0 Build(" .. item.id .. ")")
		local pv = m:GetPivot()
		assert(pv.Position.Magnitude < 1e-6, "0: Build(" .. item.id .. ") has its pivot at " .. str(pv.Position) .. ", want the origin")
		m:Destroy()
	end
	assert(Items.Build("sofa_9000", Catalog) == nil, "0: Build of an unknown id should be nil")
	table.insert(out, string.format("0 catalog: all %d items build as loose Models with ItemId, the recipe's parts (<= %d), anchored, no collide, no touch, CanQuery, no shadow under %.1f studs, no light or mesh or script; an unknown id gives nil",
		#Catalog.Items, Cfg.ItemParts, Items.SMALL))

	-- 1. in the bedroom: State
	assert(call("WakeUp") == true, "WakeUp returned false")
	placeIs("1/bedroom", "WakeUp")
	local s1 = state()
	local bed1 = s1.rooms.bedroom
	assert(bed1 and bed1.limit == Cfg.Kinds.bedroom.limit and bed1.used == 0 and #bed1.items == 0 and bed1.slots == (Cfg.Kinds.bedroom.posters or 0)
		and canon(bed1.grid) == canon(Cfg.Kinds.bedroom.grid) and canon(bed1.keep) == canon(Cfg.Kinds.bedroom.keep),
		"1: State.rooms.bedroom reads " .. show(bed1) .. ", want limit " .. Cfg.Kinds.bedroom.limit .. ", used 0, no items, slots 0, the live grid and keep")
	assert(s1.rooms.home == nil and s1.rooms.real == nil, "1: State lists rooms you don't own: " .. show(s1.rooms))
	local open = {}
	for _, u in ipairs(s1.unlocked) do open[u] = true end
	assert(open.rug and open.plant and not open.tape_machine and not open.floor_lamp, "1: State.unlocked is " .. table.concat(s1.unlocked, ",") .. ", want the rug and plant, not the tape machine or floor lamp")
	assert(s1.door == Cfg.DoorDefault and s1.inside == "bedroom", "1: State door " .. tostring(s1.door) .. ", inside " .. tostring(s1.inside) .. "; want " .. Cfg.DoorDefault .. ", bedroom")
	assert(#modelsOf("bedroom") == 0, "1: a fresh bedroom's Items are not empty")
	table.insert(out, "1 State in the bedroom: limit " .. bed1.limit .. ", used 0, the live grid and keep, unlocked " .. #s1.unlocked .. " ids (rug, plant; not tape_machine or floor_lamp), door " .. s1.door .. ", inside bedroom; an empty Items folder")

	-- 2. place a rug
	local rugCells = scan("bedroom", "rug")
	assert(#rugCells >= 2, "premise: the bedroom's free floor has " .. #rugCells .. " cells where a rug fits, want 2 or more")
	local c1, c2 = rugCells[1], rugCells[#rugCells]
	local r2 = ok(edit({ op = "place", kind = "bedroom", id = "rug", x = c1[1], z = c1[2], r = 0 }), "2 place")
	assert(r2.op == "place" and r2.kind == "bedroom" and r2.index == 1, "2: the answer reads " .. show(r2) .. ", want op place, kind bedroom, index 1")
	local rugEntry = { id = "rug", x = c1[1], z = c1[2], r = 0 }
	checkRoom("bedroom", "2")
	assert(canon(savedList("bedroom")) == canon({ rugEntry }), "2: Home's bedroom reads " .. show(savedList("bedroom")) .. ", want [ " .. show(rugEntry) .. " ]")
	local prof = test:Invoke("GetProfile", uid)
	assert(type(prof) == "table" and type(prof.career) == "table" and type(prof.career.home) == "table" and type(prof.career.home.items) == "table"
		and canon(prof.career.home.items.bedroom) == canon({ rugEntry }), "2: the profile's career.home does not hold the rug (not saved): " .. show(prof and prof.career and prof.career.home))
	local s2 = state()
	assert(s2.rooms.bedroom.used == 1 and #s2.rooms.bedroom.items == 1 and s2.rooms.bedroom.items[1].id == "rug", "2: State after the place reads " .. show(s2.rooms.bedroom))
	table.insert(out, string.format("2 place: a rug at cell (%d, %d): ok, index 1; one Item_1 model in Room_bedroom.Items, pivot at its footprint's centre, parts inside it, non-colliding; Home and the profile hold it; State used 1", c1[1], c1[2]))

	-- 3. move it; a bystander is not rebuilt; a rotation in place
	local old = modelsOf("bedroom")[1]
	local r3 = ok(edit({ op = "move", kind = "bedroom", index = 1, x = c2[1], z = c2[2] }), "3 move")
	assert(r3.op == "move" and r3.index == 1, "3: the answer reads " .. show(r3))
	rugEntry = { id = "rug", x = c2[1], z = c2[2], r = 0 }
	checkRoom("bedroom", "3 moved")
	assert(old.Parent == nil, "3: the old model is still in the world (Parent " .. tostring(old.Parent) .. ")")
	assert(#modelsOf("bedroom") == 1, "3: the move left " .. #modelsOf("bedroom") .. " models, want one")
	local pc -- a free cell for a plant that is not under the rug's first spot (the rug comes back there)
	for _, c in ipairs(scan("bedroom", "plant")) do
		if not inBlock(c, c1[1], c1[2], 2, 2) then pc = c; break end
	end
	assert(pc, "premise: no free cell for a plant outside the rug's first spot")
	ok(edit({ op = "place", kind = "bedroom", id = "plant", x = pc[1], z = pc[2] }), "3 plant")
	local plantModel = modelsOf("bedroom")[2]
	checkRoom("bedroom", "3 with a plant")
	assert(savedList("bedroom")[2].r == 0, "3: a place with no r saved r " .. tostring(savedList("bedroom")[2].r) .. ", want 0")
	ok(edit({ op = "move", kind = "bedroom", index = 1, x = c1[1], z = c1[2] }), "3 move back")
	checkRoom("bedroom", "3 moved back")
	assert(modelsOf("bedroom")[2] == plantModel and plantModel.Parent ~= nil, "3: moving the rug rebuilt the plant's model (a new instance); only what changed should be rebuilt")
	-- the rug turned in place: its cells stay, only the turn changes; it overlaps only itself
	ok(edit({ op = "move", kind = "bedroom", index = 1, x = c1[1], z = c1[2], r = 1 }), "3 rotate in place")
	assert(savedList("bedroom")[1].r == 1, "3: the rug's saved r is " .. tostring(savedList("bedroom")[1].r) .. ", want 1")
	checkRoom("bedroom", "3 rotated")
	table.insert(out, string.format("3 move: the rug to (%d, %d) and back: one model each time, the old one destroyed, the new at the new cell; a plant's model stayed the same instance through the move; the 2x2 rug turned in place (r 1) is allowed", c2[1], c2[2]))

	-- 4. a rotation with an odd footprint (the tape machine, 2 x 1; kit_tape opens it)
	clearHome("4")
	refused({ op = "place", kind = "bedroom", id = "tape_machine", x = c1[1], z = c1[2] }, "locked", "4 tape machine before kit_tape")
	assert(test:Invoke("GrantGear", uid, "kit_tape") == true, "4: GrantGear(kit_tape) failed")
	assert(waitFor(function() for _, u in ipairs(state().unlocked) do if u == "tape_machine" then return true end end return false end, 3), "4: kit_tape did not unlock the tape machine")
	local blocks = scan("bedroom", "rug") -- a free 2 x 2 block: its lowest cell
	assert(#blocks >= 1, "premise: no free 2 x 2 block on the bedroom floor")
	local bx, bz = blocks[1][1], blocks[1][2]
	ok(edit({ op = "place", kind = "bedroom", id = "tape_machine", x = bx, z = bz, r = 0 }), "4 place the tape machine")
	checkRoom("bedroom", "4 r0") -- the footprint is (bx..bx+1, bz)
	refused({ op = "place", kind = "bedroom", id = "plant", x = bx + 1, z = bz }, "overlap", "4 plant on the tape machine's second cell")
	ok(edit({ op = "place", kind = "bedroom", id = "plant", x = bx, z = bz + 1 }), "4 plant beside it (free at r 0)")
	ok(edit({ op = "remove", kind = "bedroom", index = 2 }), "4 take the plant away")
	local before4 = modelsOf("bedroom")[1]
	ok(edit({ op = "move", kind = "bedroom", index = 1, x = bx, z = bz, r = 1 }), "4 turn the tape machine")
	assert(savedList("bedroom")[1].r == 1, "4: the tape machine's saved r is " .. tostring(savedList("bedroom")[1].r) .. ", want 1")
	checkRoom("bedroom", "4 r1") -- the footprint is now (bx, bz..bz+1), parts inside it, the front turned to -X
	local pv = modelsOf("bedroom")[1]:GetPivot()
	local pivotRoom = roomOf("bedroom"):GetPivot()
	assert(pv.LookVector:Dot(pivotRoom:VectorToWorldSpace(Vector3.new(-1, 0, 0))) > 0.999, "4: the turned tape machine faces " .. str(pv.LookVector) .. ", want the room's -X")
	assert(before4.Parent == nil, "4: the tape machine's old model stayed in the world")
	refused({ op = "place", kind = "bedroom", id = "plant", x = bx, z = bz + 1 }, "overlap", "4 plant on the turned tape machine's new cell")
	ok(edit({ op = "place", kind = "bedroom", id = "plant", x = bx + 1, z = bz }), "4 plant on the cell it left (free at r 1)")
	checkRoom("bedroom", "4 with the plant")
	table.insert(out, string.format("4 odd footprint: the tape machine at (%d, %d): r 0 covers the cell east (plant refused 'overlap'), the cell south is free; turned r 1 it covers the cell south (now 'overlap') and frees the east one; its parts lie inside the new 1 x 2 footprint and it faces -X", bx, bz))

	-- 5. the refusals
	clearHome("5")
	local cells5 = scan("bedroom", "plant")
	local lim = Cfg.Kinds.bedroom.limit
	assert(#cells5 >= lim + 1, "premise: the bedroom's free floor has " .. #cells5 .. " cells, want " .. (lim + 1) .. " or more (the limit step needs them)")
	local spare = {} -- the free cells outside the rug's first spot (the rug goes back there in 8)
	for _, c in ipairs(cells5) do if not inBlock(c, c1[1], c1[2], 2, 2) then table.insert(spare, c) end end
	assert(#spare >= 4, "premise: only " .. #spare .. " free cells outside the rug's first spot, want 4 or more")
	local q = cells5[1]
	ok(edit({ op = "place", kind = "bedroom", id = "plant", x = q[1], z = q[2] }), "5 a plant to collide with")
	refused({ op = "place", kind = "bedroom", id = "plant", x = q[1], z = q[2] }, "overlap", "5 overlap")
	refused({ op = "place", kind = "bedroom", id = "plant", x = 1000, z = 1000 }, "bounds", "5 bounds (off the grid)")
	refused({ op = "place", kind = "bedroom", id = "plant", x = 0 / 0, z = 0 }, "bounds", "5 bounds (not a number)")
	refused({ op = "place", kind = "bedroom", id = "sofa_9000", x = q[1] + 1, z = q[2] }, "unknown", "5 unknown id")
	refused({ op = "place", kind = "bedroom", id = "floor_lamp", x = cells5[2][1], z = cells5[2][2] }, "locked", "5 locked (floor_lamp needs a fame tier)")
	refused({ op = "place", kind = "bedroom", id = "closet", x = cells5[2][1], z = cells5[2][2] }, "room", "5 a closet in the bedroom")
	refused({ op = "place", kind = "bedroom", id = "poster", x = cells5[2][1], z = cells5[2][2] }, "room", "5 a poster in the bedroom")
	for _, bad in ipairs({ 5, 1.5, -1, 4 }) do
		refused({ op = "place", kind = "bedroom", id = "plant", x = cells5[2][1], z = cells5[2][2], r = bad }, "rot", "5 turn " .. tostring(bad))
	end
	refused({ op = "place", kind = "home", id = "plant", x = 0, z = 0 }, "room", "5 a room you don't own (home)")
	refused({ op = "place", kind = "attic", id = "plant", x = 0, z = 0 }, "room", "5 a room that does not exist")
	refused({ op = "move", kind = "bedroom", index = 99, x = cells5[2][1], z = cells5[2][2] }, "unknown", "5 a stale move index")
	refused({ op = "move", kind = "bedroom", index = 0, x = cells5[2][1], z = cells5[2][2] }, "unknown", "5 move index 0")
	refused({ op = "remove", kind = "bedroom", index = 99 }, "unknown", "5 a stale remove index")
	refused({ op = "remove", kind = "bedroom", index = -3 }, "unknown", "5 remove index -3")
	for i, junk in ipairs({
		{ "an action that is a string", "place" },
		{ "an unknown op", { op = "burn", kind = "bedroom" } },
		{ "no op", { kind = "bedroom", id = "plant", x = 0, z = 0 } },
		{ "a number kind", { op = "place", kind = 5, id = "plant", x = 0, z = 0 } },
		{ "a table kind", { op = "place", kind = {}, id = "plant", x = 0, z = 0 } },
		{ "a number id", { op = "place", kind = "bedroom", id = 5, x = 0, z = 0 } },
		{ "a string x", { op = "place", kind = "bedroom", id = "plant", x = "3", z = 0 } },
		{ "no z", { op = "place", kind = "bedroom", id = "plant", x = 3 } },
		{ "a string r", { op = "place", kind = "bedroom", id = "plant", x = 3, z = 0, r = "1" } },
		{ "a fractional index", { op = "move", kind = "bedroom", index = 1.5, x = 3, z = 0 } },
		{ "no index", { op = "remove", kind = "bedroom" } },
	}) do
		refused(junk[2], "invalid", "5 junk " .. i .. " (" .. junk[1] .. ")")
	end
	refused(nil, "invalid", "5 no action at all")
	-- fill the room to its limit, then one more
	clearHome("5 limit")
	for i = 1, lim do
		local c = cells5[i]
		ok(edit({ op = "place", kind = "bedroom", id = "plant", x = c[1], z = c[2] }), "5 plant " .. i)
	end
	assert(state().rooms.bedroom.used == lim, "5: State used reads " .. state().rooms.bedroom.used .. " after " .. lim .. " places")
	refused({ op = "place", kind = "bedroom", id = "plant", x = cells5[lim + 1][1], z = cells5[lim + 1][2] }, "limit", "5 the " .. (lim + 1) .. "th item")
	refused({ op = "place", kind = "bedroom", id = "rug", x = cells5[lim + 1][1], z = cells5[lim + 1][2] }, "limit", "5 the " .. (lim + 1) .. "th item (a rug)")
	checkRoom("bedroom", "5 full")
	table.insert(out, string.format("5 refusals: overlap, bounds (off the grid, NaN), unknown id, locked, closet and poster in the bedroom 'room', bad turns 'rot', home and attic 'room', stale indexes 'unknown', 11 kinds of junk and no action 'invalid'; the %dth item 'limit'; each left Home and the models unchanged; %d parts <= %d", lim + 1, partCount("bedroom"), lim * Cfg.ItemParts))

	-- 6. remove
	local keep = modelsOf("bedroom")
	local gone = keep[1]
	local res6 = ok(edit({ op = "remove", kind = "bedroom", index = 1 }), "6 remove")
	assert(res6.op == "remove" and res6.index == 1, "6: the answer reads " .. show(res6))
	assert(gone.Parent == nil, "6: the removed item's model is still in the world")
	checkRoom("bedroom", "6 after one remove")
	local left = modelsOf("bedroom")
	assert(#left == lim - 1, "6: " .. #left .. " models left, want " .. (lim - 1))
	for i = 1, #left do assert(left[i] == keep[i + 1], "6: model " .. i .. " is not the same instance as before the remove (only the removed one should go)") end
	for _ = 1, lim - 1 do ok(edit({ op = "remove", kind = "bedroom", index = 1 }), "6 remove all") end
	assert(#modelsOf("bedroom") == 0, "6: the Items folder still holds " .. #modelsOf("bedroom") .. " models")
	local h6 = call("Home")
	assert(type(h6) == "table" and type(h6.items) == "table" and h6.items.bedroom == nil, "6: an emptied room's list should drop from the save, Home reads " .. show(h6))
	table.insert(out, "6 remove: gone and saved; the other models stayed the same instances (renumbered); removing the last dropped the bedroom's list from the saved home and the Items folder is empty")

	-- 7. the token bucket
	task.wait(Cfg.Edit.burst * EVERY + 0.3) -- full again
	local before7 = snap()
	local replies = {}
	local t7 = os.clock()
	for i = 1, 8 do replies[i] = call("Edit", { op = "remove", kind = "bedroom", index = 99 }) end
	local took = os.clock() - t7
	lastEdit = os.clock()
	local unknown, busy, other = 0, 0, {}
	for _, r in ipairs(replies) do
		if type(r) == "table" and r.ok == false and r.reason == "unknown" then unknown += 1
		elseif type(r) == "table" and r.ok == false and r.reason == "busy" then busy += 1
		else table.insert(other, show(r)) end
	end
	assert(took < EVERY, string.format("7: the 8 calls took %.3f s, want under one token's refill (%.1f s): an Edit that yields would make the count unreliable", took, EVERY))
	assert(#other == 0, "7: unexpected answers " .. table.concat(other, "; ") .. RED)
	assert(unknown >= Cfg.Edit.burst and unknown <= Cfg.Edit.burst + 1 and busy == 8 - unknown and busy >= 2,
		string.format("7: 8 calls in %.3f s: %d answered 'unknown' (a refusal costs a token) and %d 'busy'; want %d..%d 'unknown' and the rest 'busy'", took, unknown, busy, Cfg.Edit.burst, Cfg.Edit.burst + 1))
	assert(snap() == before7, "7: busy refusals changed things")
	local later = edit({ op = "remove", kind = "bedroom", index = 99 })
	assert(type(later) == "table" and later.reason == "unknown", "7: a call one 'every' later answered " .. show(later) .. ", want 'unknown' (not busy: a token came back)")
	table.insert(out, string.format("7 bucket: 8 calls in %.3f s: %d answered 'unknown' (burst %d), %d 'busy', nothing changed; one every (%.1f s) later a call goes through", took, unknown, Cfg.Edit.burst, busy, EVERY))

	-- 8. SetHome with junk: the plot's items follow the repaired home
	ok(edit({ op = "place", kind = "bedroom", id = "rug", x = c1[1], z = c1[2] }), "8 a rug before the junk")
	ok(edit({ op = "place", kind = "bedroom", id = "plant", x = spare[#spare][1], z = spare[#spare][2] }), "8 a plant before the junk")
	local stale8 = modelsOf("bedroom")
	local p1, p2 = spare[1], spare[2]
	local kept8 = call("SetHome", { v = 1, door = "open", items = {
		bedroom = {
			{ id = "plant", x = p1[1], z = p1[2], r = 0 },       -- kept
			{ id = "sofa_9000", x = 0, z = 0, r = 0 },           -- unknown id
			{ id = "plant", x = "3", z = 0, r = 0 },             -- a string coordinate
			{ id = "rug", x = p1[1], z = p1[2], r = 0 },         -- overlaps the plant
			{ id = "plant", x = 999, z = 999, r = 0 },           -- off the grid
			{ id = "closet", x = p2[1], z = p2[2], r = 0 },      -- not allowed in a bedroom
			"junk", 42,                                          -- not tables
			{ id = "plant", x = p2[1], z = p2[2], r = 7 },       -- a bad turn
			{ id = "plant", x = p2[1], z = p2[2], r = 0 },       -- kept
		},
		attic = { { id = "plant", x = 0, z = 0, r = 0 } },       -- a kind that does not exist
	} })
	assert(type(kept8) == "table" and kept8.door == "open" and canon(kept8.items) == canon({ bedroom = { { id = "plant", x = p1[1], z = p1[2], r = 0 }, { id = "plant", x = p2[1], z = p2[2], r = 0 } } }),
		"8: SetHome kept " .. show(kept8) .. ", want the door open and the two good plants only")
	assert(canon(call("Home")) == canon(kept8), "8: Home does not answer what SetHome kept")
	checkRoom("bedroom", "8")
	assert(#modelsOf("bedroom") == 2, "8: the plot's Items hold " .. #modelsOf("bedroom") .. " models after the junk SetHome, want the 2 kept")
	for _, m in ipairs(stale8) do assert(m.Parent == nil, "8: a model from before the SetHome is still in the world (" .. m.Name .. ")") end
	assert(state().door == "open", "8: State.door did not follow SetHome")
	table.insert(out, "8 SetHome with junk (unknown id, string coordinate, overlap, far-off cell, closet in the bedroom, bad turn, non-tables, unknown kind): kept the door and two plants; the plot's Items rebuilt from it, the earlier models gone")

	-- 9. your plot only
	teleport(LOUNGE)
	placeIs("hub", "9 lounge")
	local away = edit({ op = "remove", kind = "bedroom", index = 99 })
	assert(type(away) == "table" and away.ok == false and away.reason == "away", "9: Edit from the hub answered " .. show(away) .. ", want 'away'")
	assert(state().inside == nil, "9: State.inside in the hub reads " .. tostring(state().inside) .. ", want nil")
	local before9 = snap()
	local away2 = edit({ op = "place", kind = "bedroom", id = "plant", x = spare[#spare - 1][1], z = spare[#spare - 1][2] })
	assert(type(away2) == "table" and away2.ok == false and away2.reason == "away" and snap() == before9, "9: a real place from the hub answered " .. show(away2) .. " (or changed things), want 'away' and no change")
	assert(call("Fill", 1) == 1, "9: Fill(1) did not make a stand-in plot")
	assert(call("Enter", 2, true) == true, "9: Enter(2, as a friend) returned false")
	arrivePlace("2/landing", "9 another player's landing")
	local own9 = edit({ op = "place", kind = "bedroom", id = "plant", x = spare[#spare - 1][1], z = spare[#spare - 1][2] })
	assert(type(own9) == "table" and own9.ok == false and own9.reason == "owner", "9: Edit from another player's landing answered " .. show(own9) .. ", want 'owner'")
	local own9b = edit({ op = "remove", kind = "bedroom", index = 1 })
	assert(type(own9b) == "table" and own9b.reason == "owner", "9: a remove from another player's landing answered " .. show(own9b) .. ", want 'owner'")
	assert(state().inside == nil, "9: State.inside in another player's plot reads " .. tostring(state().inside) .. ", want nil")
	teleport(LOUNGE)
	assert(call("Unfill") == 1, "9: Unfill did not free the stand-in plot")
	assert(snap() == before9, "9: an edit from another player's plot changed your things")
	-- your own landing: inside your plot, so a room you own can be edited from there
	assert(call("WakeUp") == true, "9: WakeUp returned false")
	assert(call("Exit", "bedroom") == true, "9: Exit(bedroom) returned false")
	arrivePlace("1/landing", "9 your own landing")
	assert(state().inside == nil, "9: State.inside on your landing reads " .. tostring(state().inside) .. ", want nil")
	ok(edit({ op = "place", kind = "bedroom", id = "plant", x = spare[#spare - 1][1], z = spare[#spare - 1][2] }), "9 a place from your own landing")
	assert(#modelsOf("bedroom") == 3, "9: the landing place left " .. #modelsOf("bedroom") .. " models, want 3")
	ok(edit({ op = "remove", kind = "bedroom", index = 3 }), "9 take it away again")
	assert(call("GoIn", "bedroom") == true, "9: GoIn(bedroom) returned false")
	arrivePlace("1/bedroom", "9 back in the bedroom")
	table.insert(out, "9 where you stand: from the hub 'away' (State.inside nil), from another player's landing (Fill(1), Enter(2)) 'owner' for a place and a remove, nothing changed; from your own landing a room you own is edited (it goes through)")

	-- 10. a gear item saved while its gear is not owned
	assert(test:Invoke("ResetGear", uid) == true, "10: ResetGear failed")
	local kept10 = call("SetHome", { v = 1, door = Cfg.DoorDefault, items = { bedroom = { { id = "tape_machine", x = bx, z = bz, r = 0 } } } })
	assert(type(kept10) == "table" and type(kept10.items.bedroom) == "table" and #kept10.items.bedroom == 1 and kept10.items.bedroom[1].id == "tape_machine",
		"10: SetHome should keep a gear item saved while locked (unbuilt), got " .. show(kept10))
	local s10 = state()
	assert(#s10.rooms.bedroom.items == 1 and s10.rooms.bedroom.used == 0 and #modelsOf("bedroom") == 0, "10: while locked State reads items " .. #s10.rooms.bedroom.items
		.. ", used " .. s10.rooms.bedroom.used .. ", " .. #modelsOf("bedroom") .. " models; want 1, 0, 0 (kept in the save, not built, not counted)")
	assert(test:Invoke("GrantGear", uid, "kit_tape") == true, "10: GrantGear(kit_tape) failed")
	assert(waitFor(function() return #modelsOf("bedroom") == 1 end, 3), "10: the saved tape machine did not stand within 3 s of GrantGear(kit_tape) (the Gear listener)")
	checkRoom("bedroom", "10 gear arrived")
	assert(state().rooms.bedroom.used == 1, "10: State used reads " .. state().rooms.bedroom.used .. " once the gear is owned, want 1")
	assert(test:Invoke("ResetGear", uid) == true, "10: ResetGear failed")
	assert(waitFor(function() return #modelsOf("bedroom") == 0 end, 3), "10: the tape machine still stands 3 s after ResetGear")
	assert(#(savedList("bedroom") or {}) == 1, "10: losing the gear deleted the saved item")
	table.insert(out, "10 gear later: a tape machine saved while kit_tape is not owned is kept and unbuilt (State items 1, used 0); GrantGear stands it within 3 s, ResetGear takes it down, the save keeps it")

	-- 11. the home studio
	clearHome("11")
	teleport(LOUNGE)
	local g = gateOf("home_studio")
	assert(g and type(g.cost) == "number", "premise: no home_studio gate with a price in Config.Career.Gates")
	local stage = { money = g.cost }
	for _, stat in ipairs(STATS) do stage[stat] = (g.needs or {})[stat] or 0 end
	assert(career:Invoke("Set", uid, stage) == true, "11: Career Set " .. show(stage) .. " failed")
	local u = career:Invoke("Unlock", uid, "home_studio")
	assert(type(u) == "table" and u.ok == true, "11: Unlock(home_studio) answered " .. show(u))
	assert(waitFor(function() return roomKinds() == "bedroom,home" end, 5), "11: the plot's rooms read '" .. roomKinds() .. "', want bedroom,home")
	assert(call("WakeUp") == true, "11: WakeUp returned false")
	placeIs("1/bedroom", "11 woken in the bedroom")
	assert(#modelsOf("home") == 0, "11: a new home room's Items are not empty")
	local s11 = state()
	assert(s11.rooms.home and s11.rooms.home.limit == Cfg.Kinds.home.limit and s11.rooms.home.slots == Cfg.Kinds.home.posters and s11.inside == "bedroom",
		"11: State.rooms.home reads " .. show(s11.rooms.home) .. ", inside " .. tostring(s11.inside) .. "; want limit " .. Cfg.Kinds.home.limit .. ", slots " .. Cfg.Kinds.home.posters .. ", inside bedroom")
	local closets = scan("home", "closet")
	assert(#closets >= 1, "premise: the home room has no free floor for the closet (3 x 2)")
	local cl = closets[1]
	ok(edit({ op = "place", kind = "home", id = "closet", x = cl[1], z = cl[2], r = 0 }), "11 closet in home (edited from the bedroom)")
	refused({ op = "place", kind = "home", id = "closet", x = cl[1], z = cl[2], r = 0 }, "max", "11 a second closet", { "bedroom", "home" })
	local boards = scan("home", "keyboard_stand")
	assert(#boards >= 1, "premise: the home room has no free floor for a keyboard stand (3 x 1)")
	ok(edit({ op = "place", kind = "home", id = "keyboard_stand", x = boards[1][1], z = boards[1][2], r = 0 }), "11 keyboard stand in home (open once you own home)")
	local plantsHome = scan("home", "plant")
	ok(edit({ op = "place", kind = "home", id = "plant", x = plantsHome[1][1], z = plantsHome[1][2] }), "11 a plant in home")
	ok(edit({ op = "place", kind = "bedroom", id = "rug", x = c1[1], z = c1[2] }), "11 a rug in the bedroom")
	checkRoom("home", "11 home")
	checkRoom("bedroom", "11 bedroom")
	assert(#modelsOf("home") == 3 and #modelsOf("bedroom") == 1, "11: Items hold " .. #modelsOf("home") .. " in home and " .. #modelsOf("bedroom") .. " in the bedroom, want 3 and 1")
	for _, kind in ipairs({ "bedroom", "home" }) do
		assert(partCount(kind) <= Cfg.Kinds[kind].limit * Cfg.ItemParts, "11: Room_" .. kind .. ".Items hold " .. partCount(kind) .. " parts, want at most " .. Cfg.Kinds[kind].limit * Cfg.ItemParts)
	end
	table.insert(out, string.format("11 home studio: bought for $%d; from the bedroom a closet went into home (a second 'max'), a keyboard stand and a plant too; State's home row reads limit %d, slots %d; the parts of both rooms' Items stay within limit x %d",
		g.cost, Cfg.Kinds.home.limit, Cfg.Kinds.home.posters, Cfg.ItemParts))

	-- 12. a rejoin rebuilds the same items in the same cells
	local both = { "bedroom", "home" }
	local before12 = snap(both)
	local slot12 = call("Plot").slot
	teleport(LOUNGE)
	assert(call("Release") == true, "12: Release returned false")
	assert(call("Plot") == nil, "12: the plot is still there after Release")
	local claimed = call("Claim")
	assert(claimed == slot12, "12: Claim answered " .. tostring(claimed) .. ", want slot " .. slot12 .. " again")
	assert(roomKinds() == "bedroom,home", "12: the rebuilt plot's rooms read '" .. roomKinds() .. "', want bedroom,home")
	checkRoom("home", "12 home")
	checkRoom("bedroom", "12 bedroom")
	assert(snap(both) == before12, "12: the rejoined plot's items differ:\n  before " .. before12 .. "\n  after  " .. snap(both))
	table.insert(out, "12 rejoin: Release and Claim gave slot " .. slot12 .. " again and rebuilt the same items in the same cells in both rooms (Home, every model's id and pivot)")

	return "T108A PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", os.clock() - T0)
end

local okRun, msg = pcall(run)
pcall(unseat)
pcall(teleport, LOUNGE) -- first, so the rebuild below never happens under the player
pcall(function() rooms:Invoke("Unfill", uid) end)
pcall(function()
	career:Invoke("Reset", uid) -- the gate goes; the CareerGates listener rebuilds the plot to the bedroom
	waitFor(function() return roomKinds() == "bedroom" end, 5)
end)
pcall(function()
	wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid); ph:Invoke("Quiet", uid, false)
end)
-- the home last: a career Reset replaces prof.career (the home with it), so the Reset and the noted home go after the one above
pcall(function() rooms:Invoke("Reset", uid) end)
pcall(function() if homeBefore then rooms:Invoke("SetHome", uid, homeBefore) end end)
-- the profile as ProfileMark noted it (the gate's money, the gear)
local restored
pcall(function() restored = test:Invoke("ProfileRestore", uid) end)
pcall(function() career:Invoke("Publish", uid) end) -- Career_Get's cached Money dropped, the career attributes sent again
if not okRun then error(msg, 0) end
assert(restored == true, "cleanup: the test hook's ProfileRestore answered " .. tostring(restored) .. ", want true")
return msg
